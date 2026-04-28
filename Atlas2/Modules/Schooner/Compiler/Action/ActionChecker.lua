local utils = require('Schooner.Compiler.Utils')
local compilerHelpers = require('Schooner.Compiler.CompilerHelpers')
local helper = require('Schooner.SchoonerHelpers')
local C = require('Schooner.Compiler.CompilerHelpers')
local E = require('Schooner.Compiler.Errors')
local pl = require('pl.import_into')()

local M = {}

local UNDERSCORE_CHARACTER = "_"

local function isNamedInput(args)
    if type(args) ~= "table" then
        return false
    end
    for index, _ in pairs(args) do
        if type(index) == "string" then
            return true
        end
    end
    return false
end

local function removeComments(content)
    -- Remove multi-line comments
    local cleanedContent = string.gsub(content, "%-%-%[%[(.-)%]%]", "")

    -- Remove single-line comments
    cleanedContent = string.gsub(cleanedContent, "%-%-([^\n]*\n?)", "")

    return cleanedContent
end

local function findMainFunction(actionPath, actionText)
    local matchCounts = 0
    local mainStr
    for x in string.gmatch(actionText, "function%s*main%s*%((.-)%)") do
        matchCounts = matchCounts + 1
        mainStr = x
    end

    for before, x in string.gmatch(actionText,
                                   "([^\n]-)main%s*=%s*function%s*%((.-)%)") do
        if not utils.isNonEmptyString(helper.trim(before)) then
            matchCounts = matchCounts + 1
            mainStr = x
        end
    end

    if matchCounts > 1 then
        E:actionParameterParseFailed(actionPath,
                                     "Multiple 'main = function()' or 'function main(...)' " ..
                                     "string found in this action which is not supported " ..
                                     "when named arguments are used.")
    end

    if mainStr == nil then
        E:actionParameterParseFailed(actionPath,
                                     "Could not find 'function main(...)' in this action")
    end

    return mainStr
end

local function getFunctionParamsFromLua(actionPath)
    local actionText = helper.readFile(actionPath)

    actionText = removeComments(actionText)

    local mainStr = findMainFunction(actionPath, actionText)
    if mainStr == "" then
        return {}
    end
    mainStr = string.gsub(mainStr, " ", "")
    mainStr = string.gsub(mainStr, "\n", "")

    return utils.tokenize(mainStr, ",")
end

local function getFunctionParamsFromCSV(actionPath)
    local parameters = {}
    local _, mainSequence = compilerHelpers.loadCSV(actionPath, 'Action CSV')
    local startParameterRead = false
    local index = 1
    for _, value in ipairs(mainSequence) do
        -- when receive new function during startParameterRead status, we should stop collecting parameters
        if startParameterRead then
            if utils.isNonEmptyString(value["Function"]) then
                break
            end
        end

        -- where we start collecting parameters
        if value["Function"] == "Parameters" then
            startParameterRead = true
        end

        -- start collecting parameters when enter startParameterRead status
        if startParameterRead then
            if utils.isNonEmptyString(value["Outputs"]) then
                if value["Outputs"] ~= UNDERSCORE_CHARACTER then
                    parameters[index] = (value["Outputs"])
                else
                    -- skip this parameter
                    parameters[index] = false
                end
                index = index + 1
            end
        end
    end
    return parameters
end

local function getFunctionParams(actionPath)
    if pl.stringx.endswith(actionPath, ".lua") then
        return getFunctionParamsFromLua(actionPath)
    elseif pl.stringx.endswith(actionPath, ".csv") then
        return getFunctionParamsFromCSV(actionPath)
    end
    return {}
end

local function checkNamedInput(action, parameters)
    local newArgs = {}
    for key, value in pairs(action.args) do
        local findParameter = false;
        for index, v in ipairs(parameters) do
            if v == key then
                findParameter = true;
                newArgs[index] = value;
                break
            end
        end
        if not findParameter then
            E:actionParameterNotFound(key, action.filename)
        end
    end
    return newArgs
end

local function checkNamedInputAndReset(action, seenActionParamTable)
    if utils.isNonEmptyTable(seenActionParamTable) then
        local parameters = getFunctionParams(
                           seenActionParamTable[action.filename])
        action.args = checkNamedInput(action, parameters)
    else
        E:actionFileParametersNoFound(action.filename)
    end
end

local function checkActionExist(stationActionDirectories,
                                action,
                                seenActionTable)
    if action.dataQuery == true or stationActionDirectories == nil or
    seenActionTable[action.filename] then
        return
    end
    for _, stationActionDirectory in ipairs(stationActionDirectories or {}) do
        local actionFile = io.open(stationActionDirectory .. '/' ..
                                   action.filename, "r")
        -- could find action name but still need check case sensitive
        if actionFile then
            local fileName = string.match(action.filename, '[^%/]+%w$')
            local cmd =
            'cd "' .. stationActionDirectory .. '" &&find . -name ' .. fileName
            local file = io.popen(cmd)
            if file ~= nil then
                -- there could be multiple find results, like
                -- `a/a.lua` and `b/a.lua`, when filename contains `a.lua` as the last section.
                -- iterate everyone to look for target file.
                local findResult = file:lines()
                for result in findResult do
                    -- result is the relative path of stationActionDirectory.
                    -- remove the begining of './' and enter in the end.
                    if result ~= '' then
                        result = string.gsub(result, "^%.%/", "")
                        result = string.gsub(result, "%s+$", "")
                    end
                    if result == action.filename then
                        seenActionTable[action.filename] =
                        stationActionDirectory .. '/' .. action.filename
                        file:close()
                        actionFile:close()
                        return
                    end
                end
                file:close()
            end
            actionFile:close()
        end
    end
    E:actionFileDoNotExists(action.filename, stationActionDirectories)
end

function M.checkActions(testDef,
                        actionNames,
                        stationActionDirectories,
                        isPipeline)
    local actions = C.actionsToArray(testDef.sequence)
    testDef.actions = actions
    testDef.sequence = nil
    local seenActionTable = {}
    for _, action in ipairs(actions) do
        -- Pipeline stations currently cannot support policies
        -- Long term plan is to support per-slot policy in
        -- the Schooner layer: rdar://135365250 ([Schooner Pipeline] Policy Rendezvous For a Subset of Slots)
        if (action.policy) and (isPipeline == true) then
            E:pipelineDoesntSupportPolicy()
        end

        -- index could be nil, for graph type actions in a dictionary
        local actionLocation = 'Action name' .. ': ' .. action.name
        E:pushLocation(actionLocation)

        checkActionExist(stationActionDirectories, action, seenActionTable)

        if isNamedInput(action.args) then
            checkNamedInputAndReset(action, seenActionTable)
        end

        -- Check for duplicates and build names table
        C.checkDuplicateName(actionNames, action.name)

        -- Ensure lookups in action args are valid
        -- Will check that actions referenced by args exist in a later step
        for _, argRow in ipairs(action.args or {}) do
            if utils.isNonEmptyTable(argRow) and
            utils.isNonEmptyTable(argRow.lookup) then
                argRow.lookup[1] = pl.stringx.strip(argRow.lookup[1])
                if argRow.lookup[1] == 'inputs' then
                    if not utils.isNonEmptyString(argRow.lookup[2]) then
                        E:badDataType('Second element to action arg lookup ' ..
                                      'table must be a nonempty string.')
                    end

                    argRow.lookup[2] = pl.stringx.strip(argRow.lookup[2])
                    local varName = argRow.lookup[2]
                    if testDef.inputs == nil then
                        local msg = '. Missing inputs key found in ' ..
                                    testDef.coveragePath .. ': technology=' ..
                                    testDef.technology .. ', coverage=' ..
                                    testDef.coverage .. ', testParameters=' ..
                                    testDef.testParameters
                        E:missingInputs(msg)
                    end
                    if testDef.inputs[varName] == nil then
                        E:missingVarName(varName)
                    end
                elseif not utils.isNonEmptyString(argRow.lookup[1]) then
                    E:badDataType('First element to action arg lookup table ' ..
                                  'must be a nonempty string')
                end
            end
        end
        E:popLocation()
    end
end

return M
