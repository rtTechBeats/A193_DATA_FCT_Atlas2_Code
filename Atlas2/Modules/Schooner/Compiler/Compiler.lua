-- Lua builtin that is banned in test definition Lua exapression
local bannedBuiltins = {
    'require',
    'collectgarbage',
    'coroutine',
    'loadfile',
    'dofile',
    'load',
    'os',
    'io'
}

local function loadMooncake()
    -- for mink test
    local cffixedHome = os.getenv('CFFIXED_USER_HOME')
    if cffixedHome then
        package.cpath = package.cpath .. ';' .. cffixedHome ..
                        '/Library/Atlas2/Modules/Mooncake/?.so;'
    end

    -- for normal run
    local home = os.getenv('HOME')
    local oldCPath = package.cpath
    if home then
        package.cpath = package.cpath .. ';' .. home ..
                        '/Library/Atlas2/Modules/Mooncake/?.so;'
    end

    local mooncake_0 = require('mooncake_0')
    package.cpath = oldCPath
    return mooncake_0
end

local C = require('Schooner.Compiler.CompilerHelpers')
local E = require('Schooner.Compiler.Errors')
local limits = require('Schooner.Compiler.Limits')
local condition = require('Schooner.Compiler.Condition.Condition')
local sampling = require('Schooner.Compiler.Sampling')
local ce = Atlas.loadPlugin('ConditionEvaluator')
local pl = require('pl.import_into')()
local utils = require('Schooner.Compiler.Utils')
local actionCheck = require('Schooner.Compiler.Action.ActionChecker')
local compilerHelpers = require('Schooner.Compiler.CompilerHelpers')
local helper = require('Schooner.SchoonerHelpers')
local tree = require('Schooner.Tree')
local common = require('Schooner.SchoonerCommon')
local markdownGenerator = require('Schooner.Compiler.MarkdownGenerator')
local dump = helper.dump
local mooncake = loadMooncake()

-- constants
local LIMITS = common.LIMITS
local CONDITIONS = common.CONDITIONS
local MAIN = common.MAIN
local TEARDOWN = common.TEARDOWN
local SAMPLING = common.SAMPLING

-- compiler output keys
local MAIN_TESTS = common.MAIN_TESTS
local MAIN_ACTIONS = common.MAIN_ACTIONS
local TEARDOWN_TESTS = common.TEARDOWN_TESTS
local TEARDOWN_ACTIONS = common.TEARDOWN_ACTIONS

local debugFlag = os.getenv('SCHOONER_COMPILER_DEBUG') == 'YES'

-- print when env var SCHOONER_COMPILER_DEBUG is YES
local function debugPrint(msg)
    if debugFlag then
        print('Debug: ' .. tostring(msg))
    end
end

local columns = common.SHARED_COLUMNS
local separators = common.separators

-- save an clean _ENV to used by load below
-- this enables using lua default functions like tonumber() and print()
-- in input Lua expressions.
local M = {}

-- store yaml file content cache.
-- key: file name/path in Main table
-- value: table from the file
local yamlCache = {}

function M.readYAML(file)
    if yamlCache[file] == nil then
        yamlCache[file] = mooncake.load_with_dup_anchor_disabled(
                          helper.readFile(file))
    end
    return yamlCache[file]
end

-- error out if main and teardown has the same test
function M.checkDuplicateTest(mainTests, teardownTests)
    for _, teardownTest in ipairs(teardownTests) do
        for _, mainTest in ipairs(mainTests) do
            if teardownTest.Technology == mainTest.Technology and
            teardownTest.Coverage == mainTest.Coverage and
            teardownTest.TestParameters == mainTest.TestParameters then
                msg = 'Duplicated test in Main and Teardown section, ' ..
                      'which is not allowed: '
                msg = msg .. 'Technology=' .. mainTest.Technology ..
                      ', Coverage='
                msg = msg .. mainTest.Coverage .. ', TestParameters=' ..
                      mainTest.TestParameters
                error(msg)
            end
        end
    end
end

-- currently only works for find.output
-- when merging find.mainOutput with find.output in rdar://106119157,
-- TODO: try to use the same code to handle find.outputs and find.output
-- when process teardown use main data.
-- basically merge updateActionArgToIndexCrossDAG with updateActionArgToIndexCrossDAGFindOutputs
function M.updateActionArgToIndexCrossDAG(actionArg,
                                          dagTestMappingIdxCurrentMode)
    if not utils.isNonEmptyTable(actionArg) then
        return
    end
    if actionArg.dag == MAIN then
        local mainTest = dagTestMappingIdxCurrentMode[actionArg.dag]
                         .testSpecToDefinition[actionArg.actionSpec]
        if mainTest.outputs == nil then
            E:findOutputUseNonExistingOutputInMain(actionArg.actionSpec,
                                                   actionArg.returnIdx)
        end
        -- existence of main test referred to is checked in ensureInputsOutputsInCoverage
        local mainIdx = mainTest.outputs[actionArg.returnIdx]
        if mainIdx == nil then
            E:findOutputUseNonExistingOutputInMain(actionArg.actionSpec,
                                                   actionArg.returnIdx)
        end
        actionArg.actionIdx = mainIdx.actionIdx
        actionArg.returnIdx = mainIdx.returnIdx
        actionArg.actionSpec = nil
    end
end

function M.updateActionArgToIndexCrossDAGFindOutputs(action, mainActions)
    for i, mainAction in ipairs(mainActions) do
        if mainAction.actionSpec == action.actionSpec then
            action.actionIdx = i
            action.actionSpec = nil
            return
        end
    end

    E:internalError('Test is using data from other DAG but the action ' ..
                    'spec ' .. tostring(action.actionSpec) .. ' is not found')
end

function M.linkMainAndTeardownCoverage(dagTestMappingIdxCurrentMode,
                                       sortedTeardownActions,
                                       sortedTeardownTests,
                                       mainActions)
    -- find.mainOutput special handling: teardown use data from main
    for _, action in ipairs(sortedTeardownActions) do
        if utils.isNonEmptyArray(action.args) then
            for _, arg in ipairs(action.args) do
                M.updateActionArgToIndexCrossDAG(arg.action,
                                                 dagTestMappingIdxCurrentMode)
            end
        end
    end

    -- find.outputs special handling when teardown use data from main
    for _, test in ipairs(sortedTeardownTests) do
        for _, actions in pairs(test.findOutputsActions or {}) do
            for _, action in pairs(actions) do
                if action.dag ~= nil then
                    M.updateActionArgToIndexCrossDAGFindOutputs(action,
                                                                mainActions)
                end
            end
        end
    end
end

local function removeExtraActionKey(actions)
    for _, action in ipairs(actions) do
        action.actionSpec = nil
        -- remove deps if it is empty
        if next(action.deps) == nil then
            action.deps = nil
        end
    end
end

local function removeExtraLimitKey(limitDefs)
    for _, limit in ipairs(limitDefs) do
        limit.Technology = nil
        limit.Coverage = nil
        limit.TestParameters = nil
        limit.SubSubTest = nil
        limit.originalRowIdx = nil
    end
end

local function removeExtraTestKey(tests)
    for _, test in ipairs(tests) do
        test.separator = nil
        test.originalRowIdx = nil
        test.wildcardTestSpec = nil
        test.testSpec = nil
        test.inputs = nil
        test.mode = nil
        test.isEmpty = nil
        test.testConditions = nil
        test.testConditionInputs = nil
        local stringToBoolean = { Y = true, N = false }
        test.StopOnFail = stringToBoolean[test.StopOnFail]

        -- remove deps if it is empty
        if next(test.deps) == nil then
            test.deps = nil
        end
    end
end

function M.removeExtraKeys(mainTests,
                           teardownTests,
                           mainActions,
                           teardownActions,
                           limitDefs)
    removeExtraActionKey(mainActions)
    removeExtraActionKey(teardownActions)
    removeExtraTestKey(mainTests)
    removeExtraTestKey(teardownTests)
    removeExtraLimitKey(limitDefs)
end

function M.verifySamplingGroupDefinition(tests, samplingGroups)
    -- make sure
    -- 1. all sample group appeared in main table are defined in sampling table
    -- 2. all sample group defined in sampling table are used in main table
    local consumedSampleGroups = {}
    for _, row in ipairs(tests) do
        if (helper.isNonEmptyString(row.SamplingGroup)) then
            C.checkFieldFormat(row.SamplingGroup,
                               common.SAMPLE_GROUP_MAIN_TABLE,
                               'badSpecFieldFormat')
            if samplingGroups[row.SamplingGroup] == nil then
                local fullname = row.Technology .. ' ' .. row.Coverage .. ' ' ..
                                 row.TestParameters
                E:mainTestUseUndefinedSampleGroup(fullname, row.SamplingGroup)
            else
                consumedSampleGroups[row.SamplingGroup] = true
            end
        end
    end

    for group in pairs(samplingGroups) do
        if consumedSampleGroups[group] == nil then
            E:sampleGroupNotConsumed(group)
        end
    end
end

function M.checkIfTeardownTestHasSampleGroup(teardownTests)
    for _, test in ipairs(teardownTests) do
        if helper.isNonEmptyString(test.SamplingGroup) then
            local fullname = test.Technology .. ' ' .. test.Coverage .. ' ' ..
                             test.TestParameters
            E:teardownTestHasSampleGroup(fullname)
        end
    end
end

-- Sort an entry's deps field to be in increasing order.
-- If the original entry's deps field was {3,1,2}, then the sorted version
-- becomes {1,2,3}
local function sortDeps(entries)
    if helper.isNilOrEmptyTable(entries) then
        return
    end

    for _, entry in ipairs(entries) do
        if not helper.isNilOrEmptyTable(entry.deps) then
            table.sort(entry.deps)
        end
    end
end

local function sortDepsField(mainTests,
                             teardownTests,
                             mainActions,
                             teardownActions)
    sortDeps(mainTests)
    sortDeps(teardownTests)
    sortDeps(mainActions)
    sortDeps(teardownActions)
end

-- only for main or teardown, not both
local function sortSequenceByMode(sequence, allTestModes)
    local sequenceSortedByMode = {}

    for _, mode in ipairs(allTestModes) do
        sequenceSortedByMode[mode] = {}
        local sequenceForMode = sequenceSortedByMode[mode]

        for _, row in ipairs(sequence) do
            local modeFoundInRow = pl.tablex.find(row.mode or {}, mode)
            if row.separator or modeFoundInRow then
                local rowCopy = helper.clone(row)
                table.insert(sequenceForMode, rowCopy)
            end
        end
    end

    return sequenceSortedByMode
end

-- Process main and teardown sequence test filters:
-- 1. Replace empty Mode cell with values from IN validator (for convenience later)
-- 2. Product/StationType left as empty:
--      a. Used -> must be defined
--      b. Defined -> validated
--      c. Unexpected value cannot filter test -> OK to leave empty
--
-- @arg expectedFilterValues      dictionary of filters
-- @arg mainSeq                   main sequence
-- @arg teardownSeq               teardown sequence
local function processTestFilters(expectedFilterValues,
                                  mainSeq,
                                  teardownSeq)
    local expectedModes = {
        [common.MODE] = helper.tableKeys(expectedFilterValues[common.MODE])
    }
    C.populateEmptyFilters(mainSeq, expectedModes)
    C.populateEmptyFilters(teardownSeq, expectedModes)
end

local function filterLimitForMode(limitDefs, mode)
    local filteredLimits = {}

    for _, limit in ipairs(limitDefs) do
        if pl.tablex.find(limit.mode or {}, mode) then
            local limitCopy = helper.clone(limit)
            table.insert(filteredLimits, limitCopy)
        end
    end
    return filteredLimits
end

local function setCompilerOutputForMode(compilerOutput,
                                        mode,
                                        sortedMainTests,
                                        sortedTeardownTests,
                                        sortedMainActions,
                                        sortedTeardownActions,
                                        limit,
                                        limitInfo,
                                        conditions,
                                        samplings,
                                        testPlanAttribute)

    local outputForMode = {}
    outputForMode[MAIN_TESTS] = sortedMainTests
    outputForMode[TEARDOWN_TESTS] = sortedTeardownTests
    outputForMode[MAIN_ACTIONS] = sortedMainActions
    outputForMode[TEARDOWN_ACTIONS] = sortedTeardownActions
    outputForMode[LIMITS] = limit
    outputForMode[CONDITIONS] = conditions
    outputForMode[SAMPLING] = samplings
    outputForMode[common.LIMIT_INFO] = limitInfo
    if testPlanAttribute then
        outputForMode[common.TEST_PLAN_ATTRIBUTE] = helper.clone(
                                                    testPlanAttribute)
    end

    compilerOutput[common.TEST_PLAN_FOR_MODES][mode] = outputForMode
end

-- Test conditions should only be initialized once, by a single test.
-- This function verifies that each test condition is only initialized a single time.
function M.verifyNoDuplicateTestDefinitionInitialization(sortedMainTests,
                                                         sortedTeardownTests,
                                                         conditions)
    if conditions == nil or conditions.test == nil then
        return
    end

    -- Merge main & teardown tests together to enable for loop check
    local mergedTests = helper.clone(sortedMainTests)
    for _, teardownTest in ipairs(sortedTeardownTests) do
        table.insert(mergedTests, teardownTest)
    end

    local testConditionTable = {}
    for _, testDef in ipairs(mergedTests) do
        if testDef.testConditions ~= nil then
            for testConditionName, _ in pairs(testDef.testConditions) do
                if testConditionTable[testConditionName] ~= nil then
                    E:duplicatedTestConditionInitialization(testConditionName)
                end
                testConditionTable[testConditionName] = true
            end
        end
    end
end

-- @arg key - key being checked; ex: 'sequence', nil represents entire test block
-- @arg expectedTable - sub-table of common.TEST_DEF_KEYS containing info about expected keys
-- @arg testDefInput - sub-block of test definition block for comparison
-- Check:
-- 1) testDefInput is of corect type,
-- 2) all required keys are present,
-- 3) no unexpected keys are present
local function recursivelyCheckKeys(key, expectedTable, testDefInput)

    -- Check testDefInput is of correct type
    -- Value for 'plugins' key can be table or string
    local allowedTypes = pl.Set({ type(testDefInput) })
    if not pl.Set.issubset(allowedTypes, pl.Set(expectedTable.dataType)) then
        E:testDefValueWrongType(key, testDefInput, expectedTable.dataType)
    end

    -- 'actions' gives a list, and 'filename' is a required key for
    -- the value of every element of this list.
    if key == 'actions' then
        for k, value in ipairs(testDefInput) do
            if (type(k) ~= 'string' and type(k) ~= 'number') then
                E:internalInvalidActionsKeyType(k)
            end

            local actionName, actionSettings
            if type(k) == 'number' then
                actionName, actionSettings = C.nameAction(value)
            else
                -- key must be number; or will fail the check above
                actionName, actionSettings = k, value
            end
            recursivelyCheckKeys(actionName, expectedTable, actionSettings)
        end
        -- Once all 'actions' are checked, skip rest of recursive call
        return
    end

    -- 'outputs' and 'conditions' have similar structure in yaml
    if key == 'conditions' or key == 'outputs' then
        for name, settings in pairs(testDefInput) do
            recursivelyCheckKeys(name, expectedTable, settings)
            if not utils.isNonEmptyString(settings.lookup[1]) then
                E:badLookupKeyFormat()
            end
        end
        return
    end

    -- No more subkeys to check.
    if type(testDefInput) ~= 'table' or
    (expectedTable.requiredKeys == nil and expectedTable.optionalKeys == nil) then
        return
    end

    -- In case a layer contains no required/optional keys
    local requiredKeys = pl.Set({})
    local optionalKeys = pl.Set({})
    local actualKeys = pl.Set(pl.tablex.keys(testDefInput))

    -- No required keys for DQAction
    if expectedTable.requiredKeys ~= nil and testDefInput.dataQuery ~= true then
        requiredKeys = pl.Set(pl.tablex.keys(expectedTable.requiredKeys))
    end
    if expectedTable.optionalKeys ~= nil and testDefInput.dataQuery ~= true then
        optionalKeys = pl.Set(pl.tablex.keys(expectedTable.optionalKeys))
    elseif testDefInput.dataQuery == true then
        -- Special optional keys for DQAction
        optionalKeys = pl.Set({ 'background', 'deps', 'dataQuery' })
    end

    -- Process required keys
    -- A * B is penlight syntax for intersection(A, B)
    local missingKeys = requiredKeys - requiredKeys * actualKeys
    if #missingKeys > 0 then
        E:testDefMissingRequiredKey(key, pl.Set.values(missingKeys))
    end

    -- Process optional keys
    local extraKeys = actualKeys - ((requiredKeys + optionalKeys) * actualKeys)
    if #extraKeys > 0 then
        local allKeys = pl.Set.values(requiredKeys + optionalKeys)
        E:testDefKeyNotFound(pl.Set.values(extraKeys), allKeys)
    end

    -- Recurse for next level in test block
    for _, reqKey in ipairs(pl.Set.values(requiredKeys)) do
        recursivelyCheckKeys(reqKey, expectedTable.requiredKeys[reqKey],
                             testDefInput[reqKey])
    end
    for _, optKey in ipairs(pl.Set.values(optionalKeys)) do
        if testDefInput[optKey] ~= nil then
            recursivelyCheckKeys(optKey, expectedTable.optionalKeys[optKey],
                                 testDefInput[optKey])
        end
    end
end

-- Verify keys in test defition file match allowed list of keys.
local function checkTestDefinitionKeys(testDefinitions)

    for _, test in ipairs(testDefinitions) do
        local technology = test.technology or 'EMPTY TECHNOLOGY'
        local coverage = test.coverage or 'EMPTY COVERAGE'
        local testParameters = test.testParameters or 'EMPTY TESTPARAMETERS'
        local testID = 'Test block with technology: ' .. technology
        testID = testID .. ', coverage: ' .. coverage
        testID = testID .. ', testParameters: ' .. testParameters
        E:pushLocation(testID)
        recursivelyCheckKeys(nil, common.TEST_DEF_KEYS, test)
        E:popLocation()
    end
end

-- Take stationVersion value from plist string.
-- 1. If there are no conditional_limit, prefix, mode/product/stationType exists, length(stationVersion) <= 48
-- 2. Among conditional_limit, prefix, mode/product/stationType, length(stationVersion) + prefix <= 47
function M.checkStationVersionLength(plistContent,
                                     plistPath,
                                     limitInfo,
                                     limitVersionPrefix)
    if not string.find(plistContent, '<key>StationVersion</key>') then
        E:missStationVersionKey(plistPath)
    end
    local _, stationVersionTagEndIndex =
    string.find(plistContent, '<key>StationVersion</key>')
    local stationVersionValueString = string.sub(plistContent,
                                                 stationVersionTagEndIndex + 1)
    local stationVersion = stationVersionValueString:match(
                           "<string>([%g ]-)</string>")
    if stationVersion == "" then
        E:emptyStationVersion(plistPath)
    end

    -- If there are only prefix for limit version
    -- then stationVersion + prefix < 47
    if limitVersionPrefix ~= nil and
    (utils.isEmptyTable(limitInfo.conditions) and limitInfo.withMode == false and
    limitInfo.withProduct == false and limitInfo.withStationType == false) and
    (string.len(stationVersion) + string.len(limitVersionPrefix)) >
    common.MAX_LENGTH_OF_STATION_VERSION_WITH_DIVIDER then
        E:stationVersionLengthErrorWithoutConditionalLimit()
    elseif limitVersionPrefix == nil and
    (utils.isEmptyTable(limitInfo.conditions) and limitInfo.withMode == false and
    limitInfo.withProduct == false and limitInfo.withStationType == false) and
    string.len(stationVersion) > common.MAX_LENGTH_OF_STATION_VERSION then
        -- If there isn't any limit version, StationVersion should less than 48
        E:stationVersionLengthErrorWithoutConditionalLimitAndLimitVersionPrefix()
    elseif (utils.isEmptyTable(limitInfo.conditions) == false or
    limitInfo.withMode == true or limitInfo.withProduct == true or
    limitInfo.withStationType == true) then
        -- possibleLV: possible Limits Version strings
        local possibleLVs = limitInfo.numberPossibleLimitVersions

        -- array to store possible sw version pieces
        local infoPool = {}
        table.insert(infoPool, stationVersion)
        if limitVersionPrefix ~= nil then
            table.insert(infoPool, limitVersionPrefix)
        end
        -- For instance, we have 4 possibilities, which should begin from 0.
        -- Therefore, the limit index list should be [0, 1, 2, 3].
        table.insert(infoPool, tostring(possibleLVs - 1))
        -- svString: software version string
        local svString = pl.stringx.join('_', infoPool)
        if string.len(svString) > common.MAX_LENGTH_OF_STATION_VERSION then
            E:limitVersionExceedLength(svString, string.len(svString))
        end
    end
end

function M.checkStationMode(plistContent, plistPath, modes)
    if not string.find(plistContent, '<key>GroupArgs</key>') then
        E:missGroupArgsKeyKey(plistPath)
        return
    end

    local _, groupArgsEndIndex = string.find(plistContent,
                                             '<key>GroupArgs</key>')
    local afterGroupArgs = string.sub(plistContent, groupArgsEndIndex + 1)
    local _, arrayEndTagIndex = afterGroupArgs:find('</array>')
    local groupArgsArrayAsString = string.sub(afterGroupArgs, 1,
                                              arrayEndTagIndex)

    local modesInPlistTable = {}
    local modesInPlist = groupArgsArrayAsString:gmatch(
                         "<string>([%g ]-)</string>")
    for mode in modesInPlist do
        table.insert(modesInPlistTable, mode)
    end
    if #modesInPlistTable == 0 then
        E:emptyStationMode(plistPath)
    else
        local lastMode = modesInPlistTable[#modesInPlistTable]
        if not helper.hasVal(modes, lastMode) then
            -- Loop through if there is case insensitive match
            for _, mode in ipairs(modes) do
                if string.lower(lastMode) == string.lower(mode) then
                    -- there is a match but different case
                    E:caseMismatchStationMode(plistPath, mode, lastMode)
                    return
                end
            end
            E:invalidStationMode(plistPath, modes, lastMode)
        end
    end
end

function M.processPlistsCheckInDirectories(plistDirectoryPaths,
                                           callback, ...)
    if plistDirectoryPaths == nil then
        return
    end
    for _, plistPath in ipairs(plistDirectoryPaths) do
        plistPath = '"' .. plistPath .. '"'
        local plistPaths = helper.ls(plistPath .. '/*.plist')
        M.processPlistsCheckByPaths(plistPaths, callback, ...)
    end
end

function M.processPlistsCheckByPaths(plistPaths, callback, ...)
    if plistPaths == nil then
        return
    end
    for _, plistPath in ipairs(plistPaths) do
        local plistContent = helper.readPlist(plistPath)
        callback(plistContent, plistPath, ...)
    end
end

function M.processSinglePlistCheck(plistDirectoryPaths,
                                   plistPaths,
                                   callback, ...)
    M.processPlistsCheckByPaths(plistPaths, callback, ...)
    M.processPlistsCheckInDirectories(plistDirectoryPaths, callback, ...)
end

function M.checkStationPlist(plistDirectoryPaths,
                             plistPaths,
                             limitInfo,
                             limitVersionPrefix,
                             modes)
    M.processSinglePlistCheck(plistDirectoryPaths, plistPaths,
                              M.checkStationVersionLength, limitInfo,
                              limitVersionPrefix)
    M.processSinglePlistCheck(plistDirectoryPaths, plistPaths,
                              M.checkStationMode, modes)

    -- not used by runner
    limitInfo.numberPossibleLimitVersions = nil
end

function M.insertLimitVersionPrefix(limitVersionPrefix,
                                    limitInfo,
                                    stationPlist,
                                    stationPlistDirectory)
    if (utils.isNonEmptyTable(limitInfo.conditions) or limitInfo.withMode ==
    true or limitInfo.withProduct == true or limitInfo.withStationType == true or
    limitVersionPrefix ~= nil) and
    (stationPlist == nil and stationPlistDirectory == nil) then
        E:missStationPlistOrDirectory()
    end
    if limitVersionPrefix then
        limitInfo.limitVersionPrefix = limitVersionPrefix
    end
end

function M.markConditionAsUsed(conditions, name, where, location)
    local wheres = common.conditionUsage
    assert(wheres[where] ~= nil,
           '[Internal] invalid where in markConditionAsUsed: ' ..
           tostring(where) .. '; expecting one in ' .. dump(wheres))

    if conditions[name] == nil then
        conditions[name] = {}
        -- defensive: ensure caller get the right key to prevent
        -- getting setting.tsetCondition instead of setting.testConditions
        setmetatable(conditions[name], {
            __index = function(_, k)
                if wheres[k] == nil then
                    E:internalUnsupportedKey(k)
                end
            end
        })
    end
    conditions[name][where] = location
end

local function findFilterUsage(setting, conditionIdentifier, where, location)
    for upperCaseFilter, lowerCaseFilter in pairs(common.ALL_FILTERS) do
        local msg = '[Internal]: unexpected filter in findFilterUsage'
        assert(columns[upperCaseFilter] ~= nil, msg)
        if setting[lowerCaseFilter] ~= nil then
            M.markConditionAsUsed(conditionIdentifier, columns[upperCaseFilter],
                                  where, location)
        end
    end
end

function M.findConditionsFromLimits(limitForMode,
                                    conditionIdentifier,
                                    mode,
                                    testConditionInfo,
                                    testConditionNames)
    local limitsHasConditions = false
    if limitForMode then
        for _, setting in ipairs(limitForMode) do
            local location = "Technology: " .. setting.Technology ..
                             ", Coverage: " .. setting.Coverage ..
                             ', TestParameters: ' .. setting.TestParameters ..
                             ", Subsubtestname: " .. setting.subsubtestname ..
                             ", Mode: " .. mode .. " in limit table line " ..
                             setting.originalRowIdx
            -- setting.required can be a string / boolean value / nil
            -- if it is a string, then it is a condition expression
            if type(setting.required) == 'string' then
                limitsHasConditions = true
                setting.conditionInRequired = {}
                local tokens = ce.tokenize(setting.required)
                for _, token in ipairs(tokens) do
                    if token.type == 'identifier' then
                        M.markConditionAsUsed(conditionIdentifier, token.value,
                                              'limitRequired', location)
                        -- store the information: orphaned require limit check will use this
                        table.insert(setting.conditionInRequired, token.value)
                    end
                    if testConditionNames[token.value] then
                        M.saveTestConditionInfo(token.value, testConditionInfo,
                                                setting, location,
                                                'usingTestCondition')
                    end
                end
            end
            if setting.conditions ~= nil then
                limitsHasConditions = true
                local tokens = ce.tokenize(setting.conditions)
                for _, token in ipairs(tokens) do
                    if token.type == 'identifier' then
                        M.markConditionAsUsed(conditionIdentifier, token.value,
                                              'limitConditions', location)
                    end
                end
            end
            findFilterUsage(setting, conditionIdentifier, 'limitFilters',
                            location)
        end
    end
    return limitsHasConditions
end

function M.findConditionsFromActions(sortedActions,
                                     conditionIdentifier)
    if sortedActions == nil then
        return
    end
    -- code below assumes sortedActions is not nil.
    for _, setting in ipairs(sortedActions) do
        local location = "Test Definition: " .. setting.actionSpec
        if setting.args ~= nil then
            for _, input in ipairs(setting.args) do
                if input.condition ~= nil then

                    M.markConditionAsUsed(conditionIdentifier, input.condition,
                                          'yamlInputs', location)
                end
            end
        end
        if setting.testConditions ~= nil then
            for name, _ in pairs(setting.testConditions) do
                M.markConditionAsUsed(conditionIdentifier, name,
                                      'yamlConditions', location)
            end
        end
    end
end

function M.findConditionsFromMainTable(sortedTests,
                                       conditionIdentifier,
                                       mode,
                                       testConditionInfo,
                                       testConditionNames)
    if sortedTests then
        for _, setting in ipairs(sortedTests) do
            local location = "Technology: " .. setting.Technology ..
                             ", Coverage: " .. setting.Coverage ..
                             ', TestParameters: ' .. setting.TestParameters ..
                             ", Mode: " .. mode .. " in main " .. "table line " ..
                             setting.originalRowIdx ..
                             "'s condition expression "
            if setting.Conditions ~= nil then
                local tokens = ce.tokenize(setting.Conditions)
                compilerHelpers.checkForRestrictedConditionNames(tokens)
                for _, token in ipairs(tokens) do
                    if token.type == 'identifier' then
                        M.markConditionAsUsed(conditionIdentifier, token.value,
                                              'testConditions', location)
                    end
                    if testConditionNames[token.value] then
                        M.saveTestConditionInfo(token.value, testConditionInfo,
                                                setting, location,
                                                'usingTestCondition')
                    end
                end
            end
            findFilterUsage(setting, conditionIdentifier, 'testFilters',
                            location)
        end
    end
end

-- If condition in condition table is not used in main table, limit table, or test definition yaml
-- then it will be removed from condition table.
-- If the condition is a reserved filter name, it will be retained in the condition table even if it's not used.
-- @arg conditionVar            group or init conditions from Condition.csv
-- @arg conditionIdentifier     table of condition usage
function M.returnUsedCondition(conditionVar, conditionIdentifier)
    local newCondition = {}
    for _, setting in ipairs(conditionVar) do
        local name = setting.name
        local used = conditionIdentifier[name] ~= nil
        if used or common.ALL_FILTERS[name] then
            table.insert(newCondition, setting)
        end
    end
    -- If no conditions are used, then return nil
    return next(newCondition) ~= nil and newCondition or nil
end

function M.removeUnusedCondition(conditionTable,
                                 conditionIdentifier)
    for _, conditionType in ipairs(common.CONDITION_REMOVE_TYPE) do
        if conditionTable[conditionType] then
            conditionTable[conditionType] =
            M.returnUsedCondition(conditionTable[conditionType],
                                  conditionIdentifier)
        end
    end
end

function M.checkTestConditionGenerate(testConditions,
                                      conditionIdentifier)
    if testConditions == nil then
        return
    end
    for _, setting in ipairs(testConditions) do
        local name = setting.name
        if conditionIdentifier[name] ~= nil and
        conditionIdentifier[name].yamlConditions == nil then
            E:testConditionNotGenerate(name)
        end

    end
end

function M.checkConditionUse(sortedMainTests,
                             sortedTeardownTests,
                             sortedMainActions,
                             sortedTeardownActions,
                             limitForMode,
                             conditionTable,
                             mode,
                             testConditionInfo,
                             testConditionNames)
    local conditionIdentifier = {}
    local testPlanAttribute = {}
    -- find the indentifiers in limit require and limit conditions column
    local limitsHasConditions = M.findConditionsFromLimits(limitForMode,
                                                           conditionIdentifier,
                                                           mode,
                                                           testConditionInfo,
                                                           testConditionNames)
    testPlanAttribute['limitsHasConditions'] = limitsHasConditions
    -- find the indentifiers in yaml inputs and lookup
    M.findConditionsFromActions(sortedMainActions, conditionIdentifier)
    M.findConditionsFromActions(sortedTeardownActions, conditionIdentifier)
    -- find the indentifiers in main table conditions column
    M.findConditionsFromMainTable(sortedMainTests, conditionIdentifier, mode,
                                  testConditionInfo, testConditionNames)
    M.findConditionsFromMainTable(sortedTeardownTests, conditionIdentifier,
                                  mode, testConditionInfo, testConditionNames)

    -- check all indentifiers if they are in condition table
    M.checkAllIdentifierInCondition(conditionIdentifier, conditionTable)

    -- if a group or init condition is not used in main table or limit table or yaml,
    -- then this condition will be removed from condition table.
    M.removeUnusedCondition(conditionTable, conditionIdentifier)
    M.checkTestConditionGenerate(conditionTable.test, conditionIdentifier)

    testPlanAttribute['requireConditionValidator'] = false
    for _, value in pairs(conditionIdentifier) do
        if value.limitRequired or value.limitConditions or value.testConditions then
            testPlanAttribute['requireConditionValidator'] = true
        end
    end
    return testPlanAttribute
end

local function pipelineDoesNotSupportInitCondition(isPipeline,
                                                   initConditions)
    if isPipeline and initConditions ~= nil and next(initConditions) ~= nil then
        E:pipelineDoesNotSupportInitCondition()
    end
end
local function pipelineDoesNotSupportTeardownTests(isPipeline,
                                                   teardownTests)
    if isPipeline and teardownTests ~= nil and next(teardownTests) ~= nil then
        E:pipelineDoesNotSupportTeardownTest()
    end
end

function M.compile(mainCSVPath,
                   limitsCSVPath,
                   conditionsCSVPath,
                   sampleCSVPath,
                   limitVersionPrefix,
                   stationPlist,
                   stationPlistDirectory,
                   stationActionDirectories,
                   baseDirs,
                   markdownOutputPath)
    -- TODO: align with rdar://123487888 (Track minimum Atlas version for each feature with table)
    helper.checkAtlasVersion('Atlas.loadRestricted', '2.36.1.2')

    local conditions, expectedFilterValues =
    condition.processConditions(conditionsCSVPath)
    local testConditionNames = condition.getTestConditionNames(conditions)

    local mainSequenceScrubbed, teardownSequenceScrubbed, allTests =
    M.preprocessMainSequence(mainCSVPath, expectedFilterValues)
    local modes = helper.tableKeys(expectedFilterValues[common.MODE])
    local expandedLimits, DORC, limitInfo =
    limits.processLimits(limitsCSVPath, allTests, conditions,
                         expectedFilterValues)

    processTestFilters(expectedFilterValues, mainSequenceScrubbed,
                       teardownSequenceScrubbed)

    M.insertLimitVersionPrefix(limitVersionPrefix, limitInfo, stationPlist,
                               stationPlistDirectory)
    M.checkStationPlist(stationPlistDirectory, stationPlist, limitInfo,
                        limitVersionPrefix, modes)
    -- main csv rows for mode
    local mainSequenceSortedByMode = sortSequenceByMode(mainSequenceScrubbed,
                                                        modes)
    local teardownSequenceSortedByMode = sortSequenceByMode(
                                         teardownSequenceScrubbed, modes)
    local samplings = sampling.processSampling(sampleCSVPath)
    local compilerOutput = {}
    compilerOutput[common.TEST_PLAN_ATTRIBUTE] = {
        [common.DisableOrphanedRecordChecking] = DORC
    }
    compilerOutput[common.TEST_PLAN_FOR_MODES] = {}

    for _, mode in ipairs(modes) do
        E:pushLocation('Mode: ' .. mode)
        -- for searching actions across dags
        -- {
        --    main = {array of main tests},
        --    teardown = {array of teardown tests},
        -- }
        local testsAllDAGs = {}
        local testConditionInfo = {}

        local limitForMode = filterLimitForMode(expandedLimits, mode)
        local sortedMainTests, sortedMainActions, isPipeline =
        M.processSequenceAndCoverage(mainCSVPath, baseDirs,
                                     mainSequenceSortedByMode[mode],
                                     testsAllDAGs, MAIN,
                                     stationActionDirectories,
                                     testConditionInfo, testConditionNames)

        pipelineDoesNotSupportInitCondition(isPipeline, conditions.init)
        pipelineDoesNotSupportTeardownTests(isPipeline,
                                            teardownSequenceSortedByMode[mode])

        local sortedTeardownTests, sortedTeardownActions =
        M.processSequenceAndCoverage(mainCSVPath, baseDirs,
                                     teardownSequenceSortedByMode[mode],
                                     testsAllDAGs, TEARDOWN,
                                     stationActionDirectories,
                                     testConditionInfo, testConditionNames)
        M.checkDuplicateTest(sortedMainTests, sortedTeardownTests)
        -- convert action spec into action index
        M.linkMainAndTeardownCoverage(testsAllDAGs, sortedTeardownActions,
                                      sortedTeardownTests, sortedMainActions)
        M.verifyNoDuplicateTestDefinitionInitialization(sortedMainTests,
                                                        sortedTeardownTests,
                                                        conditions)
        M.updateTestsConditionalFlag(sortedMainTests, sortedMainActions)
        M.updateTestsConditionalFlag(sortedTeardownTests, sortedTeardownActions)
        local conditionsForEachMode = helper.clone(conditions)
        -- check condition in condition table is used in main table, limit table and yaml.
        -- if condition is not used then it will be removed.
        local testPlanAttribute = M.checkConditionUse(sortedMainTests,
                                                      sortedTeardownTests,
                                                      sortedMainActions,
                                                      sortedTeardownActions,
                                                      limitForMode,
                                                      conditionsForEachMode,
                                                      mode, testConditionInfo,
                                                      testConditionNames)
        M.checkUsingTestConditionNotInitIalized(testConditionInfo)
        M.removeExtraKeys(sortedMainTests, sortedTeardownTests,
                          sortedMainActions, sortedTeardownActions, limitForMode)
        C.removeFiltersWhenAll(sortedMainTests, expectedFilterValues)
        C.removeFiltersWhenAll(sortedTeardownTests, expectedFilterValues)
        C.removeFiltersWhenAll(limitForMode, expectedFilterValues)
        sortDepsField(sortedMainTests, sortedTeardownTests, sortedMainActions,
                      sortedTeardownActions)

        M.verifySamplingGroupDefinition(mainSequenceScrubbed, samplings);
        M.checkIfTeardownTestHasSampleGroup(teardownSequenceScrubbed)

        setCompilerOutputForMode(compilerOutput, mode, sortedMainTests,
                                 sortedTeardownTests, sortedMainActions,
                                 sortedTeardownActions, limitForMode, limitInfo,
                                 conditionsForEachMode, samplings,
                                 testPlanAttribute)
        E:popLocation()
    end

    -- Generate markdown if requested
    if markdownOutputPath ~= nil then
        markdownGenerator.generateCoverageMarkdown(compilerOutput,
                                                   markdownOutputPath)
    end

    return compilerOutput
end

function M.updateTestsConditionalFlag(tests, actions)
    for _, test in ipairs(tests or {}) do
        M.updateTestConditionalFlag(tests, test, actions)
    end

    for _, test in ipairs(tests or {}) do
        if test.conditional == false then
            test.conditional = nil
        end
    end
end

-- update test conditional flag.
-- if test's conditional flag is unknow, calculate it and store it in test.
-- A test is conditional if
--    1. it has `Conditions`   -- already processed?
--    2. any of its action use find.output(s) and (one of) the source test(s) is conditional
--       arg using test condtion is already converted into action before this.
--       in M.linkTestConditionInputs()
function M.updateTestConditionalFlag(tests, test, actions)
    if test.conditional ~= nil then
        return
    end

    -- if test has conditions, mark it as a conditional test
    -- no need to look into actions
    if helper.isNonEmptyString(test.Conditions) then
        test.conditional = true
        return
    end

    -- set to false; will loop through all actions to see if
    -- any action get data from a conditional test
    test.conditional = false
    for _, actionIndex in ipairs(test.actions or {}) do
        local action = actions[actionIndex]
        for _, arg in ipairs(action.args or {}) do
            -- only check action within dag
            if arg.action and not arg.action.dag then
                local argActionIndex = arg.action.actionIdx
                if not helper.hasVal(test.actions, argActionIndex) then
                    -- refer to action in another test
                    local argAction = actions[argActionIndex]
                    local argTest = tests[argAction.testIdx]
                    M.updateTestConditionalFlag(tests, argTest, actions)
                    test.conditional = test.conditional or argTest.conditional
                    if test.conditional == true then
                        -- one of the arg is from a conditional test
                        -- do not need to check the remaining args.
                        return
                    end
                end
            end
        end
    end
end

function M.processSequenceAndCoverage(mainCSVPath,
                                      baseDirs,
                                      sequenceScrubbed,
                                      dagTestMappingIdxCurrentMode,
                                      dagName,
                                      stationActionDirectories,
                                      testConditionInfo,
                                      testConditionNames)

    -- main csv --> main tests
    local sortedMainGraph, coveragePathsToTestSpecs, testSpecToRow,
          testSpecToRowIdx, phaseTestDefs =
    M.processSequence(mainCSVPath, sequenceScrubbed, dagName)

    -- Set pipeline flag. true if pipeline stations false otherwise
    local isPipeline = false
    if next(phaseTestDefs) ~= nil then
        isPipeline = true
    end

    local dependentTests, testSpecToDefinition = M.processTestDefs(
                                                 coveragePathsToTestSpecs,
                                                 baseDirs,
                                                 stationActionDirectories,
                                                 testSpecToRow,
                                                 testConditionInfo,
                                                 testConditionNames, isPipeline)
    -- add phase test definitions to normal test defs
    for k, v in pairs(phaseTestDefs) do
        assert(testSpecToDefinition[k] == nil)
        testSpecToDefinition[k] = v
    end

    M.scanForAmbiguousWildcards(coveragePathsToTestSpecs)
    M.convertActionDeps(testSpecToDefinition)
    M.ensureInputsOutputsInCoverage(dependentTests, testSpecToDefinition,
                                    testSpecToRow, dagTestMappingIdxCurrentMode)
    -- Double check no new ambiguous wildcard matches were introduced
    M.scanForAmbiguousWildcards(coveragePathsToTestSpecs)
    M.createActionForFindOutputs(testSpecToDefinition, sortedMainGraph,
                                 dagTestMappingIdxCurrentMode)
    -- when condition is Test condition, convert testDef.inputs['x'] = {conditions='A'}
    -- into the action that generates the test condition, since it is the same:
    -- passing data from 1 action to another.
    -- Ignore the cross-dag scenario since runner is handling the case when
    -- test generating test condition is cancelled while test condition is used
    -- in teardown.
    M.linkTestConditionInputs(testSpecToDefinition)
    M.linkActions(testSpecToDefinition)
    M.linkMainGraph(sortedMainGraph, testSpecToDefinition, testSpecToRowIdx)

    local sortedActionGraph = M.sortActionsAcrossAllCoverage(
                              testSpecToDefinition)

    M.convertToIndices(sortedMainGraph, sortedActionGraph, testSpecToDefinition)
    M.populateActionGraphWithTestConditions(sortedMainGraph, sortedActionGraph)

    dagTestMappingIdxCurrentMode[dagName] = {
        testSpecToDefinition = testSpecToDefinition
    }

    return sortedMainGraph, sortedActionGraph, isPipeline
end

function M.linkTestConditionInputs(testDefs)
    -- 1. collect mapping about test conditions
    -- {conditionName = testname}
    local testConditions = {}

    for _, testDef in pairs(testDefs) do
        if testDef.testConditions then
            for name, setting in pairs(testDef.testConditions) do
                testConditions[name] = {
                    actionName = setting.actionName,
                    returnIdx = setting.returnIdx,
                    technology = testDef.technology,
                    coverage = testDef.coverage,
                    testParameters = testDef.testParameters
                }
            end
        end
    end

    -- 2. check all consumer in test.inputs
    for _, testDef in pairs(testDefs) do
        local inputs = testDef.inputs
        for var, setting in pairs(inputs or {}) do
            if setting.condition then
                local conditionName = setting.condition
                local conditionSetting = testConditions[conditionName]
                if conditionSetting then
                    -- is a test condition.
                    -- move "conditions[TestCondition]" like inputs into
                    -- a separate table
                    if testDef.testConditionInputs == nil then
                        testDef.testConditionInputs = {}
                    end
                    -- will be handled in linkActions()
                    local newTCInput = testDef.testConditionInputs
                    newTCInput[conditionName] = {
                        actionSpec = C.encodeActionSpec2(conditionSetting),
                        returnIdx = conditionSetting.returnIdx
                    }

                    inputs[var] = nil
                end
            end
        end
    end
end

function M.createActionForFindOutputs(testSpecToDefinition,
                                      tests,
                                      dagTestMappingIdxCurrentMode)
    for _, test in ipairs(tests) do
        local testDef = testSpecToDefinition[C.encodeTest(test)]
        E:pushLocation(testDef.coveragePath)
        for inputName, input in pairs(testDef.inputs or {}) do
            if utils.isNonEmptyTable(input['find.outputs']) then
                local testNames = input['find.outputs']
                local outVarName = input['find.outputs'].varName

                -- for current dag
                local testDefs = testSpecToDefinition
                if testNames.dag == MAIN then
                    testDefs = dagTestMappingIdxCurrentMode[MAIN]
                               .testSpecToDefinition
                end
                local matchingTests = M.findMatchingTests(testDefs, testNames)
                if next(matchingTests) == nil then
                    E:noMatchingTestFound(testNames)
                end

                local argActions = {}
                for _, matchingTest in ipairs(matchingTests) do
                    local testNamesString = C.encodeTest(matchingTest.testDef)

                    local depTestDef = testDefs[testNamesString]
                    if not utils.isNonEmptyTable(depTestDef) then
                        -- user shouldn't see this
                        local msg = 'depTestDef must be nonempty table, ' ..
                                    'perhaps not found in testDefs= ' ..
                                    pl.pretty.write(testDefs)
                        E:internalError(msg)
                    end

                    local output = depTestDef.outputs[outVarName]

                    local returnIdx = output.returnIdx
                    encodedActionSpec = C.encodeActionSpec({
                        depTestDef.technology,
                        depTestDef.coverage,
                        depTestDef.testParameters,
                        output.actionName
                    })
                    if not utils.isNonEmptyString(encodedActionSpec) then
                        local msg = 'encodedActionSpec '
                        msg = msg .. 'must be nonempty string, '
                        msg = msg .. 'perhaps not found in output = '
                        msg = msg .. pl.pretty.write(output)
                        E:intBadDataType(msg)
                    end
                    if not utils.isValidNumber(returnIdx) then
                        E:intBadDataType(
                        'returnIdx must be nil or number, not ' ..
                        tostring(returnIdx))
                    end
                    argActions[matchingTest.testDef.testParameters] = {
                        actionSpec = encodedActionSpec,
                        returnIdx = returnIdx,
                        meta = matchingTest.meta,
                        dag = testNames.dag
                    }
                end

                -- create a special action for find.outputs
                if testDef.findOutputsActions == nil then
                    testDef.findOutputsActions = {}
                end
                test.findOutputsActions = testDef.findOutputsActions
                testDef.findOutputsActions[inputName] = argActions
                input['find.outputs'] = { findOutputsActionName = inputName }
            end
        end
        E:popLocation()
    end
end

function M.preprocessMainSequence(mainCSVPath, expectedFilterValues)
    E:pushLocation(mainCSVPath)

    local header, mainSequence = C.loadCSV(mainCSVPath, MAIN)
    C.validateHeader(mainCSVPath, header, MAIN)

    -- Skip disabled items & blank lines, strip whitespace
    local mainTests = {}
    local teardownTests = {}
    local allTests = {}
    local allFilters = {}
    local isInTeardownSequence, firstTeardownIdx = false, 0
    for rowIdx, row in ipairs(mainSequence) do
        -- rowIdx here map to the row in main table is rowIdx + 1, since header is the first row
        -- Currently only found one case that an error msg gives out row number.
        E:pushLocation('Row ' .. rowIdx + common.NUM_HEADER_LINES)

        -- TODO: Use OOP for parsing CSV to avoid duplicate code across limits + main CSVs
        -- E.g. CSVFile base class -> subclasses for Limits and Main,
        -- each implement their own parse/process/findDuplicate functions
        C.parseFilter(row, columns.Mode)
        C.parseFilter(row, columns.Product)
        C.parseFilter(row, columns.StationType)
        C.addSeenFilters(allFilters, {
            [common.MODE] = row[common.MODE],
            [common.PRODUCT] = row[common.PRODUCT],
            [common.STATION_TYPE] = row[common.STATION_TYPE]
        })

        C.checkMainTableRow(row)

        -- Preserve original rowIdx
        row.originalRowIdx = rowIdx

        if row.separator == separators.TEARDOWN then
            if isInTeardownSequence then
                E:teardownSepAlreadySeen(firstTeardownIdx)
            else
                isInTeardownSequence, firstTeardownIdx = true, rowIdx +
                                                         common.NUM_HEADER_LINES
            end
        end

        if not row.isEmpty and row.separator ~= separators.TEARDOWN and
        row.Disable:upper() ~= 'Y' then
            local rows = C.expandLoopInTestParameters(row)
            if isInTeardownSequence then
                if row.StopOnFail ~= '' then
                    E:teardownTestSetStopOnFail(row)
                end
                C.addRows(teardownTests, rows)
            else
                C.addRows(mainTests, rows)
            end
            C.addRows(allTests, rows)
        end

        -- Pop rowIdx
        E:popLocation()
    end

    C.findDuplicateEntries(allTests, MAIN)
    C.validateFilters(expectedFilterValues, allFilters)
    -- Pop mainCSVPath
    E:popLocation()

    return mainTests, teardownTests, allTests
end

function M.createPhaseTestDef(phaseIndex)
    assert(type(phaseIndex) == 'number')
    assert(phaseIndex > 0)
    local testParameters = tostring(phaseIndex)
    return {
        technology = '-PHASE-',
        coverage = 'TEST',
        testParameters = testParameters,
        actions = {
            {
                -- StartTest.lua is actual an empty action
                -- TODO: rename it to Empty.lua or Noop.lua
                name = 'EmptyPhaseAction',
                filename = 'Schooner/StartTest.lua',
                -- store the phase number so runner
                -- 1. use addPhase to add this action
                -- 2. use the phase number as phase name
                phase = testParameters
            }
        },
        specializedSpec = { '-PHASE-', 'TEST', testParameters },
        coveragePath = 'SchoonerBuiltin',
        valid = true
    }
end

-- process Main tests or Teardown tests, not both
function M.processSequence(mainCSVPath, sequenceScrubbed, dagName)
    E:pushLocation(mainCSVPath)

    -- Prepare table for main sequence dependencies
    local coveragePathsToTestSpecs = {}
    -- only used when there is phase;
    -- phase separator is translated into a Phase Test
    -- all parallel group above should be in its dependency
    -- all parallel group below should depend on it
    local lastTestInParallelGroupCurrentPhase = {}
    local numberParallelGroupsCurrentPhase = 1
    local numberOfPhases = 0
    local testSpecToRow, isNewGroup, previousTestSpec = {}, true, nil
    -- same format as testSpecToDefinition:
    --  key: testSpec
    --  value: test definition table
    local phaseTests = {}
    local currentPhaseTestSpec
    for _, row in ipairs(sequenceScrubbed) do
        -- Last column is original rowIdx
        E:pushLocation('Row ' .. row.originalRowIdx)

        if row.separator then
            assert(row.separator == separators.PARALLEL or row.separator ==
                   separators.PHASE, row.separator)
            if row.separator == separators.PARALLEL then
                isNewGroup = true
                numberParallelGroupsCurrentPhase =
                #lastTestInParallelGroupCurrentPhase + 1
            elseif row.separator == separators.PHASE then
                -- convert -PHASE-, -, - into a test -PHASE-, TEST, N
                -- 1. no need to check name
                numberOfPhases = numberOfPhases + 1
                row.Coverage = 'TEST'
                row.TestParameters = tostring(numberOfPhases)

                local testSpec = C.specNamesToIndices(row)
                local encodedTestSpec = C.encodeTestSpec(testSpec)
                row.testSpec = encodedTestSpec

                -- 2. empty Dependency column, but has implicit dependencies:
                -- pointing last test of every parallel group of the previous phase
                -- to this test
                -- so dag could stop before this test in runUntil/wait
                row.additionalDependencies = pl.List()
                for _, previousRow in
                ipairs(lastTestInParallelGroupCurrentPhase) do
                    row.additionalDependencies:append(previousRow.testSpec)
                end

                -- 3. start of an new parallel group
                isNewGroup = true
                previousTestSpec = nil
                -- 4. no yaml file to process
                -- 5. treat the row as a real test
                testSpecToRow[encodedTestSpec] = row
                -- 6. clean up tests of last phase, be ready to track current phase
                numberParallelGroupsCurrentPhase = 1
                lastTestInParallelGroupCurrentPhase = {}

                -- 7. return test def for the phase test
                phaseTests[encodedTestSpec] =
                M.createPhaseTestDef(numberOfPhases)
                -- 8. store current phase test so test below can depend on it
                currentPhaseTestSpec = row.testSpec
            end
        else
            C.checkFieldFormat(row.Technology, common.TECHNOLOGY,
                               'badSpecFieldFormat')
            C.checkFieldFormat(row.Coverage, common.COVERAGE,
                               'badSpecFieldFormat')
            C.checkFieldFormat(row.TestParameters, common.TEST_PARAMETERS,
                               'badSpecFieldFormat')

            local testSpec = C.specNamesToIndices(row)

            local encodedTestSpec = C.encodeTestSpec(testSpec)
            if testSpecToRow[encodedTestSpec] ~= nil then
                E:duplicateTestSpec(encodedTestSpec)
            end

            row.testSpec = encodedTestSpec

            -- encodedDeps: deps from csv; may be used in inputs.
            -- additionalDeps: deps added by schooner, like
            -- 1. test depend on its previous test above.
            -- 2. test use another test's output as input
            -- 3. (in future) test use test condition that is intialized
            --    by other test
            row.encodedDeps = C.parseTestDependency(row.Dependency)
            row.additionalDependencies = pl.List()
            for _, encodedDep in ipairs(row.encodedDeps) do
                if encodedDep == encodedTestSpec then
                    E:circularDependency(encodedTestSpec)
                end
            end
            if isNewGroup then
                isNewGroup = false
            else
                if previousTestSpec ~= nil then
                    row.additionalDependencies:append(previousTestSpec)
                end
            end
            if currentPhaseTestSpec ~= nil then
                row.additionalDependencies:append(currentPhaseTestSpec)
            end

            if utils.isValidTable(coveragePathsToTestSpecs[row.CoverageFile]) then
                table.insert(coveragePathsToTestSpecs[row.CoverageFile],
                             { testSpec = testSpec })
            else
                coveragePathsToTestSpecs[row.CoverageFile] = {
                    { testSpec = testSpec }
                }
            end

            testSpecToRow[encodedTestSpec] = row
            previousTestSpec = encodedTestSpec

            -- store the test so it is last test in the parallel group being processed
            lastTestInParallelGroupCurrentPhase[numberParallelGroupsCurrentPhase] =
            row
        end

        -- Pop rowIdx
        E:popLocation()
    end

    -- Create graph for main sequence dependencies
    local sortedMainGraph = C.sortMainGraph(testSpecToRow, dagName)

    -- Map spec to index after sorting
    local testSpecToRowIdx = {}
    for rowIdx, row in ipairs(sortedMainGraph) do
        testSpecToRowIdx[row.testSpec] = rowIdx
    end

    -- Pop mainCSVPath
    E:popLocation()

    return sortedMainGraph, coveragePathsToTestSpecs, testSpecToRow,
           testSpecToRowIdx, phaseTests
end

-- AB could match test def with A* in testParameters
-- testParameters of test def has * but is not single *
function M.isPartialPattern(test)
    local str = test.testParameters
    stripped = pl.stringx.strip(str)

    if stripped ~= str then
        E:haveExtraSpace(dump(test))
    end

    local hasPattern = C.hasPattern(str)
    local isNotStar = str ~= '*'

    return hasPattern and isNotStar
end

-- find matching test definition block from given array of test defs from the same file.
-- strict matching first, then partial mapping (like A*), then wildcard (*).
-- assuming coverage doesn't have duplicate items.
-- error out if not found.
function M.findMatchingTestDef(mainTestNames, coverage)
    local strictMatchTestDef
    local partialMatchTestDef
    local wildcardMatchTestDef

    local tech = mainTestNames[1]
    local cov = mainTestNames[2]
    local testParam = mainTestNames[3]

    for _, testDef in ipairs(coverage) do
        if tech == testDef.technology and cov == testDef.coverage then
            -- technology, coverage and testParameter strictly match
            if testParam == testDef.testParameters then
                -- strict match found
                strictMatchTestDef = testDef
                break
            elseif M.isPartialPattern(testDef) then
                -- found multiple partial match. Error out.
                if C.stringWildcardMatch(testDef.testParameters, testParam) then
                    if partialMatchTestDef ~= nil then
                        E:ambiguousTestDefMatch(C.encodeTest(testDef), {
                            partialMatchTestDef,
                            testDef
                        })
                    end
                    partialMatchTestDef = testDef
                end
            elseif testDef.testParameters == '*' then
                -- A strict match might be found later
                wildcardMatchTestDef = testDef
            elseif helper.trim(testDef.testParameters) == '*' then
                E:haveExtraSpace(C.encodeTest(testDef))
            end
        end
    end

    local matchingTestDef = strictMatchTestDef or partialMatchTestDef or
                            wildcardMatchTestDef

    if matchingTestDef == nil then
        E:noTestDefMatch(dump(mainTestNames))
    end

    -- return a copy of the test definition
    -- and replace '*' with actual testParameters
    local ret = helper.clone(matchingTestDef)
    ret.testParameters = mainTestNames[3]
    return ret
end

function M.checkFindOutputArguments(testDef, sourceTestDef)
    if testDef.technology == "" or testDef.coverage == "" then
        local msg = 'found in ' .. sourceTestDef.coveragePath ..
                    ': technology="' .. sourceTestDef.technology ..
                    '", coverage="' .. sourceTestDef.coverage .. '", ' ..
                    'testParameters="' .. sourceTestDef.testParameters .. '"'
        E:testDefNilFindout(msg)
    end
end

function M.checkTestNames(testDef)
    C.checkFieldFormat(testDef.technology, common.TECHNOLOGY,
                       'badSpecFieldFormat')
    C.checkFieldFormat(testDef.coverage, common.COVERAGE, 'badSpecFieldFormat')
    C.checkFieldFormat(testDef.testParameters, common.TEST_PARAMETERS,
                       'badSpecFieldFormat')
end

-- param argsString: content inside () of find.output()
-- return: table parsed from the find.output string, like
--          {
--              technology = '',
--              coverage = '',
--              testParameters = '',
--              varName = '',
--          }
function M.parseFindOutput(argsString, sourceTestDef)
    E:pushLocation(argsString)

    local args = pl.stringx.split(argsString, ',')
    if #args < 4 then
        E:wrongParamsFindOutput(#args)
    end

    -- tech: the 1st section
    -- cov: the 2nd section
    -- varName: the last section
    -- ensure field 1, 2 and 4 are quoted
    local ret = {
        technology = C.stripAndUnquote(args[1]),
        coverage = C.stripAndUnquote(args[2]),
        varName = C.stripAndUnquote(args[#args])
    }

    -- arg3 is the string remove arg1/2/4: content between the 2nd comma and the last comma
    local commaLocations = {}
    local commaLocation = 0
    -- find the location of 2nd comma
    while commaLocation do
        commaLocation = argsString:find(',', commaLocation + 1)
        table.insert(commaLocations, commaLocation)
    end

    -- "a, b, c, d, e"
    --   2  5  8  11
    --      |<--->|
    --      | c, d|
    --    start: 5 + 1 = 6
    --    end  : 11 - 1
    local arg3Start = commaLocations[2] + 1
    local arg3End = commaLocations[#commaLocations] - 1
    assert(arg3Start < arg3End)

    local arg3 = argsString:sub(arg3Start, arg3End)

    -- ensure comma in the 3rd arg is within ()
    -- to catch find.output('a', 'b', 'c', 'd', 'e')
    -- find.output('a', 'b', testParameters:gsub('a', 'b'), 'e') is ok
    if #commaLocations > 3 then
        -- more than 3 commas; the 3rd arg must contains at least 1 comma
        local pNonComma = '[^,]*'
        local pAnything = '.*'
        local pattern = '^' .. pNonComma .. '%(' .. pAnything .. ',' ..
                        pAnything .. '%)' .. pNonComma .. '$'
        if not arg3:match(pattern) then
            E:wrongParamsFindOutput('> 4')
        end
    end

    -- the 3rd arg could have Lua code.
    local env = {}
    env.testParameters = sourceTestDef.testParameters

    ret.testParameters = M.runLuaExpression(arg3, env, bannedBuiltins,
                                            function(...)
        E:invalidLuaCodeFindOutput3rdArg(...)
    end)

    M.checkFindOutputArguments(ret, sourceTestDef)
    M.checkTestNames(ret)
    C.checkFieldFormat(ret.varName, common.VARIABLE_NAME, 'badVarNameFormat')

    E:popLocation()
    return ret
end

function M.checkInputs(testDef,
                       dependentTests,
                       testConditionInfo,
                       testInfo,
                       testConditionNames,
                       location)
    local sourceTestDef = {
        technology = testDef.technology,
        coverage = testDef.coverage,
        testParameters = testDef.testParameters,
        coveragePath = testDef.coveragePath
    }

    -- Dependent actions & conditions
    if utils.isNonEmptyTable(testDef.inputs) then
        for varName, inputExpr in pairs(testDef.inputs) do
            -- shark: workaround: only load for conditions
            if inputExpr:match('^conditions%[.+%]$') ~= nil then
                local conditionName = inputExpr:match('^conditions%[(.+)%]$')
                local unquoted
                unquoted, conditionName =
                pcall(C.stripAndUnquote, conditionName)
                if not unquoted or conditionName == nil or conditionName == '' then
                    E:conditionsKeyNil(varName)
                end

                if testConditionNames[conditionName] then
                    M.saveTestConditionInfo(conditionName, testConditionInfo,
                                            testInfo, location,
                                            'usingTestCondition')
                end
                testDef.inputs[varName] = { condition = conditionName }
            elseif inputExpr:match('^find%.output%(.+%)$') ~= nil then
                local argsString = inputExpr:match('^find%.output%((.+)%)$')
                local dependency = M.parseFindOutput(argsString, sourceTestDef)

                if C.hasPattern(dependency.testParameters) then
                    E:findOutput3rdArgHasPattern(dependency)
                end

                -- Transform input
                testDef.inputs[varName] = { ['find.output'] = dependency }
                -- Save for later
                table.insert(dependentTests,
                             { dependency = dependency, requiredBy = testDef })
            elseif inputExpr:match('^find%.mainOutput%(.+%)$') ~= nil then
                E:usingFindMainOutput()
            elseif inputExpr:match('^find%.outputs%(.+%)$') ~= nil then
                local argsString = inputExpr:match('^find%.outputs%((.+)%)$')
                local dependency = pl.tablex.copy(
                                   M.parseFindOutput(argsString, sourceTestDef))

                if not C.hasPattern(dependency.testParameters) then
                    E:findOutputs3rdArgNotPattern(dependency)
                end

                -- Transform input
                testDef.inputs[varName] = { ['find.outputs'] = dependency }
                -- Save for later
                table.insert(dependentTests,
                             { dependency = dependency, requiredBy = testDef })
                -- TODO: adding an "else" here so later compiler knows
                -- it is some Lua code to run.
            end
        end
    end
end

function M.checkOutputs(testDef, actionNames)
    if utils.isNonEmptyTable(testDef.outputs) then
        -- Get exposed actions
        for varName, outputTbl in pairs(testDef.outputs) do
            C.checkFieldFormat(varName, common.VARIABLE_NAME, 'badVarNameFormat')

            local actionName, returnIdx = outputTbl.lookup[1],
                                          outputTbl.lookup[2] or 1

            if returnIdx == 'overallResult' then
                returnIdx = common.DEVICE_RESULT_RETURN_IDX
            end
            compilerHelpers.checkLookupReturnIdx(returnIdx)

            -- Ensure exposed action is in test definition
            if actionNames[actionName] == nil then
                E:actionNotFound(actionName)
            end

            testDef.outputs[varName] = {
                actionName = actionName,
                returnIdx = returnIdx
            }
        end
    end
end

-- return: boolean
function M.isBuiltinInput(input)
    local inputBuiltinKeys = { 'condition', 'find.output', 'find.outputs' }

    for _, key in ipairs(inputBuiltinKeys) do
        if input[key] ~= nil then
            return true
        end
    end

    return false
end

function M.isLuaExpressionInput(input) return not M.isBuiltinInput(input) end

-- run the input expression and return the evaluated value, using given env.
-- error out if expression is not an valid one or erorr out when running.
-- errorFunction: a function that will be called with arg (input, errorMsg)
--                when error happens
-- returnNil: boolean; true to allow the expression to resolve to nil.
--            by default false, so function will error out if resolve to nil
function M.runLuaExpression(input, env, bannedENVs, errorFunction, returnNil)
    local cmdString = 'return ' .. input
    errorFunction = errorFunction or function(...) E:badLuaExpression(...) end

    local loadPass, value = pcall(Atlas.loadRestricted, cmdString, env,
                                  bannedENVs)

    if not loadPass then
        errorFunction(input, value)
    end

    if not returnNil and value == nil then
        errorFunction(input, 'Lua expression resolves to nil')
    end
    return value
end

-- update inputs with real value from Main by
-- run lua code in inputs using testParameters as local var.
function M.runLuaExpressionInputs(testDef)
    -- Substitute test spec references in inputs
    -- shark: do we support technology and coverage in input expression? I guess not
    if testDef.inputs == nil or next(testDef.inputs) == nil then
        return
    end

    local env = {}
    env.testParameters = testDef.testParameters

    -- resolve input that is Lua expression
    for name, input in pairs(testDef.inputs) do
        if M.isLuaExpressionInput(input) then
            E:pushLocation(name .. ' ' .. input)
            local reporter = function(expression, msg)
                E:badInputExpr(name, 'fails to resolve Lua expression ' ..
                               expression .. ', msg: ' .. msg)
            end
            local value = M.runLuaExpression(input, env, bannedBuiltins,
                                             reporter)
            testDef.inputs[name] = { value = value }
            E:popLocation()
        end
    end
end

function M.updateActionArgsFromInputs(testDef)
    -- Specialize action args
    for _, action in ipairs(testDef.actions) do
        -- Use proper length of action.args to traverse table. Needed to include nil values.
        local numArgs = utils.findProperLength(action.args or {})
        for argIdx = 1, numArgs do
            local argRow = action.args[argIdx]
            if utils.isNonEmptyTable(argRow) then
                if utils.isNonEmptyTable(argRow.lookup) then
                    if argRow.lookup[1] == 'inputs' then
                        local varName = argRow.lookup[2]

                        if testDef.inputs[varName].value ~= nil then
                            action.args[argIdx] = {
                                value = testDef.inputs[varName].value
                            }
                        end
                        local inputCondition = testDef.inputs[varName].condition
                        if utils.isNonEmptyString(inputCondition) then
                            action.args[argIdx] = { condition = inputCondition }
                        end
                    end
                else
                    -- table as args
                    action.args[argIdx] = { value = argRow }
                end
            else
                -- magic value in yaml
                action.args[argIdx] = { value = argRow }
            end
        end
    end
end

function M.checkTestConditions(testDef,
                               actionNames,
                               testConditionInfo,
                               testInfo,
                               testConditionNames,
                               location)
    local testConditions = testDef.conditions
    testDef.conditions = nil
    testDef.testConditions = {}

    for conditionName, outputTbl in pairs(testConditions or {}) do
        C.checkFieldFormat(conditionName, common.CONDITION_NAME,
                           'badVarNameFormat')

        -- Group/Init condition could not initialize in Yaml
        if testConditionNames[conditionName] == nil then
            E:wrongTypeConditionInitialize(conditionName)
        else
            M.saveTestConditionInfo(conditionName, testConditionInfo, testInfo,
                                    location, 'initializeTestCondition')
        end

        local actionName, returnIdx = outputTbl.lookup[1],
                                      outputTbl.lookup[2] or 1

        if returnIdx == 'overallResult' then
            returnIdx = common.DEVICE_RESULT_RETURN_IDX
        end
        compilerHelpers.checkLookupReturnIdx(returnIdx)

        if actionNames[actionName] == nil then
            E:actionNotFound(actionName)
        end

        testDef.testConditions[conditionName] = {
            actionName = actionName,
            returnIdx = returnIdx
        }
    end
end

-- save product, stationType, location of test which initialize or use test condition.
-- for example testConditionInfo = {A = 'usingTestCondition' = { product = {P1}, location = ''}}
function M.saveTestConditionInfo(name,
                                 testConditionInfo,
                                 testInfo,
                                 location,
                                 type)
    testConditionInfo[name] = testConditionInfo[name] or {}
    local eachTestCondition = testConditionInfo[name]
    local productAndStationTypeInfo = {
        product = testInfo.product,
        stationType = testInfo.stationType,
        location = location
    }
    eachTestCondition[type] = eachTestCondition[type] or {}
    if type == 'usingTestCondition' then
        table.insert(eachTestCondition[type], productAndStationTypeInfo)
    elseif type == 'initializeTestCondition' then
        eachTestCondition[type] = productAndStationTypeInfo
    end
end

-- check if given test definition has any syntax error.
-- convert to intermediate data structure if necessary.
-- error out if any error is found.
-- do not return anything if syntax is valid.
-- testDef is specialized: testParameter is value in Main table.
function M.checkTestDefinition(testDef,
                               dependentTests,
                               stationActionDirectories,
                               testInfo,
                               testConditionInfo,
                               testConditionNames,
                               location,
                               isPipeline)
    local testName = "Test name: " .. C.encodeTest(testDef)
    E:pushLocation(testName)
    local actionNames = {}

    -- check input syntax; calculate value
    -- check if conditions[k] k is nil;
    -- convert inputs expression into function/table.
    -- find.output should have 4 args
    -- checkVarName
    -- checkTestNames(ret)
    -- check test data dependency for cycle detection.
    -- check condition names are found in the condition table
    M.checkInputs(testDef, dependentTests, testConditionInfo, testInfo,
                  testConditionNames, location)
    -- action
    -- no duplicated action names
    -- args can be (inputs, name) or (action, [n])
    --    - inputs name should exist
    --    - action should exist
    --    - n should be >0 number
    --    - if action, no circle dependency: action A use actionB's return while B use A's return
    -- validating actions.

    actionCheck.checkActions(testDef, actionNames, stationActionDirectories,
                             isPipeline)

    -- check outputs syntax
    -- checkVarName
    -- output should be table with lookup key
    -- output should from an action and optional return index.
    -- return index should be >0 number.
    -- store in exposedVars
    -- testDef.exposedVars = M.checkOutputs(testDef, actionNames)
    M.checkOutputs(testDef, actionNames)

    -- check test conditions
    -- check test conditions syntax
    -- check test condition var name
    -- test conditions should be table with lookup key
    -- test conditions should from an action and optional return index.
    -- return index should be >0 number.
    M.checkTestConditions(testDef, actionNames, testConditionInfo, testInfo,
                          testConditionNames, location)

    C.sortActions(testDef, actionNames)
    testDef.valid = true
    E:popLocation()
end

function M.loadCoverage(baseDirs, coveragePath)
    local path
    for _, folder in ipairs(baseDirs) do
        if helper.fileExist(folder .. '/' .. coveragePath) then
            if path ~= nil then
                E:coverageInMultipleFolder(coveragePath)
            else
                path = folder .. '/' .. coveragePath
            end
        end
    end

    local didPass, coverageOrErr = pcall(M.readYAML, path)
    if not didPass then
        E:cantReadCoverage(coverageOrErr)
    end

    if not utils.isValidTable(coverageOrErr) then
        E:coverageNotTable()
    end
    local coverage = helper.clone(coverageOrErr)
    return coverage
end

function M.haveIdentifierInConditionCSV(value, conditionsForType)
    for _, conditionRow in pairs(conditionsForType) do
        if conditionRow['name'] == value then
            return true
        end
    end
    return false
end

function M.findConditionWithName(value, conditions)
    -- conditionForType is a list of all conditions for a given condition type (ex. Group, Init, or Test)
    for _, conditionsForType in pairs(conditions) do
        local result = M.haveIdentifierInConditionCSV(value, conditionsForType)
        if result == true then
            return true
        end
    end
    return false
end

function M.checkIdentifierInCondition(identifier,
                                      identifierData,
                                      conditionsForCopy)
    for _, conditionType in ipairs(common.CONDITION_TYPE) do
        for _, setting in ipairs(conditionsForCopy[conditionType] or {}) do
            local name = setting.name
            if identifier == name then
                -- Currently, test conditions are not supported in Conditions column of limit table.
                -- TODO: Remove below if-block once support for test conditions is defined.
                if identifierData.limitConditions and conditionType == 'test' then
                    E:unsupportedConditionTypeInLimitTable(name,
                                                           identifierData.limitConditions)
                end
                return true
            end
        end
    end
end

-- Check that the condition evaluation's identifier can be found inside the
-- conditions table.  A condition evaluation is in the form of <X comparison Y>,
-- where X is the identifier, the comparison is a boolean operator (==, <, >) and Y is the
-- value being compared against.
function M.checkAllIdentifierInCondition(conditionIdentifier,
                                         conditionTable)
    for identifier, identifierData in pairs(conditionIdentifier) do
        local haveIdentifier = M.checkIdentifierInCondition(identifier,
                                                            identifierData,
                                                            conditionTable)
        if not haveIdentifier then
            local locations = {}
            for key in pairs(common.conditionUsage) do
                if identifierData[key] then
                    table.insert(locations, identifierData[key])
                end
            end
            if next(locations) then
                E:undefinedConditionVariable(identifier, locations)
            end
        end
    end
end

-- Check for duplicate test definition blocks.  A duplicate block is defined as
-- >=2 blocks that share the same Technology, Coverage, and TestParameteres values.
function M.checkDuplicateTestDefinition(testDefs, coveragePath)
    local keys = { common.TECHNOLOGY, common.COVERAGE, common.TEST_PARAMETERS }
    local dupHandler = function(def, node)
        if node.seen then
            error('Test definition: ' .. dump(def) .. ' already exists.')
        end
        node.seen = true
    end
    local t = tree.new(nil, keys, dupHandler)
    for _, testDef in ipairs(testDefs) do
        -- make sure testDef is a valid table
        if not utils.isValidTable(testDef) then
            E:testDefNotTable()
        end
        -- check if all test name keys are present
        M.checkTestNames(testDef)

        local def = {
            [common.TECHNOLOGY] = testDef.technology,
            [common.COVERAGE] = testDef.coverage,
            [common.TEST_PARAMETERS] = testDef.testParameters
        }
        -- capture the error msg to report an more explicit error.
        local result, err = pcall(t.add, t, def, t.tree, 1)
        if result == false and err:match('.* already exists.') then
            local msg = 'found in ' .. coveragePath .. ': technology=' ..
                        testDef.technology .. ', coverage=' .. testDef.coverage ..
                        ', testParameters=' .. testDef.testParameters
            E:duplicateTestSpec(msg)
        end
    end
end

function M.checkUsingTestConditionNotInitIalized(testConditionInfo)
    for testConditionName, testConditionData in pairs(testConditionInfo) do
        local testConditionInitialize =
        testConditionData.initializeTestCondition
        local testConditionUsing = testConditionData.usingTestCondition
        -- not use test condition
        if testConditionUsing == nil then
            goto continue
        end
        -- not even initialize
        if testConditionInitialize == nil then
            E:usingTestConditionNotInitialized(testConditionName,
                                               'not initialized',
                                               testConditionData.usingTestCondition
                                               .location)
        end
        -- using and initialize test condition with empty product and stationType
        if testConditionUsing.product == nil and testConditionUsing.stationType ==
        nil and testConditionInitialize.product == nil and
        testConditionInitialize.stationType == nil then
            goto continue
        end

        -- loop handle use all test condition case with not empty product or stationType.
        for _, oneTestConditionData in ipairs(testConditionUsing or {}) do
            if not compilerHelpers.isSubset(oneTestConditionData.product,
                                            testConditionInitialize.product) or
            (not compilerHelpers.isSubset(oneTestConditionData.stationType,
                                          testConditionInitialize.stationType)) then
                E:usingTestConditionNotInitialized(testConditionName,
                                                   testConditionInitialize.location,
                                                   oneTestConditionData.location)
            end
        end
        ::continue::
    end
end

-- @arg coveragePathsToTestSpecs: table.
--      key: yaml file path
--      value: array of main row test names; each item is a 1-key-value table
--             key: "testSpec"
--             value: array: 1. technology 2. coverage 3. testParameters
-- @arg baseDir: base folder of yaml file paths.
-- @arg conditions : conditions values read in from conditions table
function M.processTestDefs(coveragePathsToTestSpecs,
                           baseDirs,
                           stationActionDirectories,
                           testSpecToRow,
                           testConditionInfo,
                           testConditionNames,
                           isPipeline)
    local dependentTests = {}
    -- key: test names in string
    -- value: test def table
    local processedMainTests = {}

    for coveragePath, specsUsedByMain in pairs(coveragePathsToTestSpecs) do
        local coveragePathMsg = "Test definition path: " .. coveragePath
        E:pushLocation(coveragePathMsg)
        local coverage = M.loadCoverage(baseDirs, coveragePath)
        M.checkDuplicateTestDefinition(coverage, coveragePath)
        checkTestDefinitionKeys(coverage)
        local mainTests = specsUsedByMain
        for _, mainTest in ipairs(mainTests) do
            -- finding matching test def in yaml file; error out (inside) when no matching is found.
            -- rdar://107747047 ([Refactor][TODO] Unify how we store test name): get ride of 'testSpec'
            local mainTestNames = mainTest.testSpec
            -- trying to find a matching test def for each main row.
            local testDef = M.findMatchingTestDef(mainTestNames, coverage)
            testDef.coveragePath = coveragePath

            local testName = C.encodeTestSpec(mainTestNames)
            local location = 'Yaml: ' .. coveragePath .. ', Blcok: ' .. testName
            local testInfo = testSpecToRow[testName]
            -- do the checking

            M.checkTestDefinition(testDef, dependentTests,
                                  stationActionDirectories, testInfo,
                                  testConditionInfo, testConditionNames,
                                  location, isPipeline)

            local testNameString = C.encodeTestSpec(mainTestNames)
            processedMainTests[testNameString] = testDef
            -- TODO: use tree to store test def for a given main test
            -- instead of encoded string.

            testDef.specializedSpec = mainTestNames

            -- run Lua-expression-like-inputs using `testParameters` as local var
            -- whose value comes from Main table
            M.runLuaExpressionInputs(testDef)
            -- rdar://107747227: update the way runner handle outputs using action name instead of action index
            -- handle "lookup:[inputs, name]"
            M.updateActionArgsFromInputs(testDef)
        end

        -- Pop testDefPath
        E:popLocation()
    end

    return dependentTests, processedMainTests
end

-- Scan coveragePathsToTestSpecs for ambiguous wildcard matches
function M.scanForAmbiguousWildcards(coveragePathsToTestSpecs)
    for coveragePath, specsUsedByMain in pairs(coveragePathsToTestSpecs) do
        E:pushLocation(coveragePath)

        for _, specUsedByMain in ipairs(specsUsedByMain) do
            C.checkAmbiguousWildcards(specUsedByMain)
        end

        E:popLocation()
    end
end

-- Convert action deps to encoded action spec
function M.convertActionDeps(testSpecToDefinition)
    for _, testDef in pairs(testSpecToDefinition) do
        local specializedSpec = testDef.specializedSpec

        for _, action in ipairs(testDef.actions) do
            local depsTbl = {}

            for _, dep in ipairs(action.deps or {}) do
                C.addDep({
                    -- TODO: only [3] might be updated.
                    -- can we update this when parsing test definition for the main test?
                    -- we know TestParameters from main already.
                    specializedSpec[1],
                    specializedSpec[2],
                    specializedSpec[3],
                    dep
                }, depsTbl, true)
            end

            action.deps = depsTbl
        end
    end
end

-- Ensure inputs & outputs can be found in coverage
-- For inputs, look for the tests & actions it points to; error out if not found
function M.ensureInputsOutputsInCoverage(dependentTests,
                                         testSpecToDefinition,
                                         testSpecToRow,
                                         testsAllDAGs)
    -- dependentTest: find.output(s)
    for _, dependentTest in ipairs(dependentTests) do
        -- requireBy: the test definition that use data from another test
        -- dependency: name of the test + varname that generate the data
        local requiredBy = dependentTest.requiredBy
        local dependency = dependentTest.dependency

        E:pushLocation(requiredBy.coveragePath)

        local errorLocation = 'Test definition :' .. C.encodeTest(requiredBy)
        E:pushLocation(errorLocation)

        local matchingTests = M.findMatchingTests(testSpecToDefinition,
                                                  dependency)
        if next(matchingTests) == nil then
            -- try to search in other dags.
            -- currently only support from teardown to main
            -- check current dag:
            --     - don't have main: in main
            --     - have main but don't have teardown: in teardown: search in main.
            --     - otherwise: invalid currently; error out
            if testsAllDAGs[MAIN] == nil then
                E:noMatchingTestFound(dependency)
            elseif testsAllDAGs[TEARDOWN] == nil then
                -- in teardown; trying to see if getting data from main tests
                local matchingMainTests =
                M.findMatchingTests(testsAllDAGs[MAIN].testSpecToDefinition,
                                    dependency)
                if next(matchingMainTests) == nil then
                    E:findOutputUseNonExistingTestInMain(
                    C.encodeTest(dependency))
                end

                dependency.dag = MAIN
            else
                assert('[internal] SHOULD NOT REACH HERE: ' ..
                       'Currently only have main and teardown DAG for ' ..
                       'user to schedule coverage')
            end
        end

        -- find.output: 1 matching test
        -- find.outputs: 1+ matching tests
        for _, matchingTest in ipairs(matchingTests or {}) do
            local testDef = matchingTest.testDef
            if not utils.isNonEmptyTable(testDef.outputs) then

                E:findOutputPointToTestWithoutOutputs(dependency, testDef)
            end
            if testDef.outputs[dependency.varName] == nil then
                E:findOutputPointToTestNotOutputingVariable(dependency, testDef,
                                                            dependency.varName)
            end
            -- testA's input use testB's output
            -- usedDef: testA
            -- encodedSpecializedSpec: testB
            -- TODO: can I store everything in testDef?
            local testName = C.encodeTest(testDef)
            local row = testSpecToRow[C.encodeTest(requiredBy)]
            local d = row.additionalDependencies
            if not d:contains(testName) then
                d:append(testName)
            end
        end

        -- Pop requiredBy
        E:popLocation()
        E:popLocation()
    end
end

-- in given tests table, find all matching tests and return their test def.
-- param tests: key: encoded test names as string; value: test definition
-- return: array of {meta={}, testDef = testDef}
function M.findMatchingTests(tests, testWithPattern)
    local ret = {}
    for _, testDef in pairs(tests) do
        local matchResult = { C.wildcardMatch(testDef, testWithPattern) }
        if matchResult[1] ~= nil then
            local meta = {}
            for i = 3, #matchResult do
                meta[i - 2] = matchResult[i]
            end

            table.insert(ret, { meta = meta, testDef = testDef })
        end
    end

    return ret
end

-- Link actions
-- convert action args's find.output into actionSpec + return index.
function M.linkActions(testSpecToDefinition)
    for _, testDef in pairs(testSpecToDefinition) do
        E:pushLocation(testDef.coveragePath)
        local specializedSpec = testDef.specializedSpec

        for _, action in ipairs(testDef.actions) do
            E:pushLocation('action ' .. action.name)

            for argIdx, arg in ipairs(action.args or {}) do
                if arg and arg.condition then
                    local input = testDef.testConditionInputs and
                                  testDef.testConditionInputs[arg.condition]
                    if input then
                        assert(utils.isNonEmptyTable(input))
                        action.args[argIdx] = { action = input }
                    end
                elseif utils.isNonEmptyTable(arg) and
                utils.isNonEmptyTable(arg.lookup) then
                    local encodedActionSpec

                    if arg.lookup[1] == 'inputs' then
                        -- Substitute inputs of type find.output
                        local inVarName = arg.lookup[2]
                        local input = testDef.inputs[inVarName]
                        if not utils.isNonEmptyTable(input) then
                            E:badDataType('input must be a nonempty table')
                        end

                        if utils.isNonEmptyTable(input['find.output']) then
                            local testNames = input['find.output']
                            local outVarName = input['find.output'].varName

                            local testNamesString = C.encodeTest(testNames)

                            local depTestDef =
                            testSpecToDefinition[testNamesString]
                            if not utils.isNonEmptyTable(depTestDef) then
                                -- may refer to test in another dag.
                                local actionArg = {}
                                actionArg.actionSpec = testNamesString
                                actionArg.dag = testNames.dag
                                actionArg.returnIdx = outVarName
                                action.args[argIdx] = { action = actionArg }

                                goto continue
                            end

                            local output = depTestDef.outputs[outVarName]

                            local returnIdx = output.returnIdx
                            encodedActionSpec =
                            C.encodeActionSpec({
                                depTestDef.technology,
                                depTestDef.coverage,
                                depTestDef.testParameters,
                                output.actionName
                            })
                            if not utils.isNonEmptyString(encodedActionSpec) then
                                local msg = 'encodedActionSpec '
                                msg = msg .. 'must be nonempty string, '
                                msg = msg .. 'perhaps not found in output = '
                                msg = msg .. pl.pretty.write(output)
                                E:intBadDataType(msg)
                            end

                            compilerHelpers.checkLookupReturnIdx(returnIdx)

                            action.args[argIdx] = {
                                action = {
                                    actionSpec = encodedActionSpec,
                                    returnIdx = returnIdx
                                }
                            }
                        elseif utils.isNonEmptyTable(input['find.outputs']) then
                            action.args[argIdx] = input['find.outputs']
                        else
                            -- only developer should see this
                            E:badDataType(
                            '[internal] input must have ' ..
                            'nonempty table for "find.output"' ..
                            ' or "find.outputs"')
                        end
                    else
                        -- Link arg references to other actions in test def

                        local dep, returnIdx = arg.lookup[1], arg.lookup[2] or 1
                        if not utils.isNonEmptyString(dep) then
                            E:badDataType('dep must be nonempty string')
                        end

                        if returnIdx == 'overallResult' then
                            returnIdx = common.DEVICE_RESULT_RETURN_IDX
                        end
                        compilerHelpers.checkLookupReturnIdx(returnIdx)

                        encodedActionSpec =
                        C.encodeActionSpec {
                            specializedSpec[1],
                            specializedSpec[2],
                            specializedSpec[3],
                            dep
                        }

                        if not utils.isNonEmptyString(encodedActionSpec) then
                            E:intBadDataType(
                            'encodedActionSpec must be a nonempty string')
                        end

                        action.args[argIdx] = {
                            action = {
                                actionSpec = encodedActionSpec,
                                returnIdx = returnIdx
                            }
                        }
                    end

                    if encodedActionSpec then
                        action.deps[encodedActionSpec] = false
                    end
                    ::continue::
                end
            end

            E:popLocation()
        end

        E:popLocation() -- coveragePath
    end
end

-- Link everything together
-- Since Atlas 2 has new test graph API, linking the actions across tests is just a sanity check for cycles
function M.linkMainGraph(sortedMainGraph,
                         testSpecToDefinition,
                         testSpecToRowIdx)
    for idx, row in ipairs(sortedMainGraph) do
        local encodedTestSpec = row.testSpec

        local testDef = testSpecToDefinition[encodedTestSpec]

        local firstNodes = C.firstCriticalSectionNodes(testDef.actions)

        -- Combine deps & convert deps to indices
        row.deps = {}
        local allDeps = row.encodedDeps or pl.List()
        allDeps = allDeps .. row.additionalDependencies
        for _, encodedDep in ipairs(allDeps) do
            local depTestDef = testSpecToDefinition[encodedDep]
            local specializedSpec = depTestDef.specializedSpec

            -- shark: seems to dup with Atlas code but necessary to find invalid deps
            --        at compile time
            local lastNodeNames = C.lastCriticalSectionNodes(depTestDef.actions)

            for _, targetAction in ipairs(firstNodes) do
                for _, sourceActionName in ipairs(lastNodeNames) do
                    C.addDep({
                        specializedSpec[1],
                        specializedSpec[2],
                        specializedSpec[3],
                        sourceActionName
                    }, targetAction.deps, false)
                end
            end

            table.insert(row.deps, testSpecToRowIdx[encodedDep])
        end

        -- Add testIdx to point back to row
        -- Add actions to point from row
        row.actions = {}
        for _, action in ipairs(testDef.actions) do
            action.testIdx = idx

            table.insert(row.actions, C.encodeActionSpec {
                testDef.specializedSpec[1],
                testDef.specializedSpec[2],
                testDef.specializedSpec[3],
                action.name
            })
        end

        -- Update row with test def info
        row.CoverageFile = nil
        row.Dependency = nil
        row.Disable = nil
        row.encodedDeps = nil
        row.additionalDependencies = nil
        row.inputs = testDef.inputs
        -- row.originalTestSpec        = testDef.originalTestSpec
        row.outputs = testDef.outputs
        row.testConditions = testDef.testConditions
        row.retry = testDef.retry
        row.TestCoverageCategory = nil
        row.wildcardTestSpec = C.encodeTestSpec(C.specNamesToIndices(testDef))
    end
end

function M.sortActionsAcrossAllCoverage(testSpecToDefinition)
    -- Create action table
    local actionSpecToAction = {}
    for _, testDef in pairs(testSpecToDefinition) do
        for _, action in ipairs(testDef.actions) do
            local actionSpec = {}
            for testSpecField = 1, 3 do
                actionSpec[testSpecField] =
                testDef.specializedSpec[testSpecField]
            end
            actionSpec[4] = action.name

            local encodedActionSpec = C.encodeActionSpec(actionSpec)
            actionSpecToAction[encodedActionSpec] = pl.tablex.deepcopy(action)
            actionSpecToAction[encodedActionSpec].actionSpec = encodedActionSpec
        end
    end

    -- Build action graph over all coverage
    -- Convert deps to encoded action specs
    local function getter(action)
        local deps = {}
        for encodedDepActionSpec in pairs(action.deps) do
            local depAction = actionSpecToAction[encodedDepActionSpec]
            if depAction == nil then
                E:actionNotFound(encodedDepActionSpec)
            end
            deps[#deps + 1] = depAction.actionSpec
        end
        return action.actionSpec, deps
    end

    local ret = {}
    for _, actionSpec in ipairs(C.sort(actionSpecToAction, getter)) do
        if actionSpecToAction[actionSpec] == nil then
            error('SchoonerInternal: sorted action not found in action list')
        end
        ret[#ret + 1] = actionSpecToAction[actionSpec]
    end

    return ret
end

local function addTestConditionsToAction(testConditions,
                                         sortedActionGraph)
    for testConditionName, testConditionValues in pairs(testConditions) do
        -- rdar://107820727 ([TODO] error check at addTestConditionsToAction)
        local action = sortedActionGraph[testConditionValues.actionIdx]

        if action.testConditions == nil then
            action.testConditions = {}
        end

        testConditionValues.actionName = nil
        testConditionValues.actionIdx = nil

        action.testConditions[testConditionName] = testConditionValues
    end
end

function M.populateActionGraphWithTestConditions(sortedMainGraph,
                                                 sortedActionGraph)
    for _, row in ipairs(sortedMainGraph) do
        if row.testConditions ~= nil then
            addTestConditionsToAction(row.testConditions, sortedActionGraph)
        end
    end
end

function M.convertToIndices(sortedMainGraph,
                            sortedActionGraph,
                            testSpecToDefinition)
    -- Use this for converting actions to indices
    local actionSpecToIdx = {}
    for idx, action in ipairs(sortedActionGraph) do
        actionSpecToIdx[action.actionSpec] = idx
    end

    -- Convert actions in main graph to indices
    -- Also convert test spec fields
    for _, row in ipairs(sortedMainGraph) do
        row.testName, row.subTestName = C.makeTestNames(row.Technology,
                                                        row.Coverage,
                                                        row.TestParameters)
        row.fullName = row.testName .. ' ' .. row.subTestName

        for idx, encodedActionSpec in ipairs(row.actions) do
            row.actions[idx] = actionSpecToIdx[encodedActionSpec]
            if not utils.isValidNumber(row.actions[idx]) then
                E:actionIndexNotFound(encodedActionSpec)
            end
        end
    end

    -- Convert outputs to indices
    for _, testDef in pairs(testSpecToDefinition) do
        for _, output in pairs(testDef.outputs or {}) do
            output.actionSpec = C.encodeActionSpec2(testDef, output.actionName)
            output.actionIdx = actionSpecToIdx[output.actionSpec]
            if not utils.isValidNumber(output.actionIdx) then
                E:actionIndexNotFound(output.actionSpec)
            end
            output.actionSpec = nil
        end
    end

    -- Convert test conditions to indices
    for _, testDef in pairs(testSpecToDefinition) do
        for _, testCondition in pairs(testDef.testConditions or {}) do
            local actionSpec = C.encodeActionSpec2(testDef,
                                                   testCondition.actionName)
            testCondition.actionIdx = actionSpecToIdx[actionSpec]
            if not utils.isValidNumber(testCondition.actionIdx) then
                E:testConditionActionIndexNotFound(actionSpec)
            end
        end

        -- convert findOutputsActions arg to indices
        for _, action in pairs(testDef.findOutputsActions or {}) do
            for _, arg in pairs(action) do
                if arg.dag == nil then
                    arg.actionIdx = actionSpecToIdx[arg.actionSpec]
                    arg.actionSpec = nil
                end
            end
        end
    end

    -- Convert args of type action to indices
    for _, action in ipairs(sortedActionGraph) do
        for _, arg in ipairs(action.args or {}) do
            if utils.isNonEmptyTable(arg.action) and (arg.action.dag == nil) then
                arg.action.actionIdx = actionSpecToIdx[arg.action.actionSpec]
                arg.action.actionSpec = nil
            else
                assert('SHOULD NOT REACH HERE')
            end
        end
    end

    -- Convert deps to indices, eliminate deps with keep == false
    for _, action in ipairs(sortedActionGraph) do
        local scrubbedDeps = {}

        for encodedDepSpec, keep in pairs(action.deps) do
            if keep then
                table.insert(scrubbedDeps, actionSpecToIdx[encodedDepSpec])
            end
        end

        action.deps = pl.tablex.copy(scrubbedDeps)
    end
end

function M.dumpCompareFailInfo(failInfo)
    local typeOfFail = failInfo[1]

    if typeOfFail == helper.tableCompareFailType["typeFail"] then
        print("Compiler output type changed after writing to file")
    elseif typeOfFail == helper.tableCompareFailType["lengthFail"] then
        print("Compiler output length changed after writing to file")
    elseif typeOfFail == helper.tableCompareFailType["valueFail"] then
        local message
        print(failInfo[2])
        print("Before writing:")
        message = string.format("Type: %s, ", failInfo['table1'].type)
        if failInfo['table1'].value ~= nil then
            message = message .. "Value: " .. tostring(failInfo['table1'].value)
        end
        print(message)

        print("After writing:")
        message = string.format("Type: %s, ", failInfo['table2'].type)
        if failInfo['table2'].value ~= nil then
            message = message .. "Value: " .. tostring(failInfo['table2'].value)
        end
        print(message)
    end
end

-- ensure t only has key in keys; error out otherwise.
-- does not require all key in keys appear in t.
-- used to verify compiler config file.
local function verifyKeys(t, keys)
    for key, value in pairs(t) do
        if keys[key] == nil then
            E:unexpectedCompilerSetting(key, keys)
        end
        if type(value) ~= keys[key] then
            E:unexpectedCompilerSettingType(key, value, keys[key])
        end
    end
end

-- currently no option is defined so the file should be either empty or does not exist
-- in the future if we are to add any setting that is needed both in mink and on station
-- we can modify the allowed key list in common.compilerConfig
function M.applyCompilerConfiguration(atlas2Folder, args)
    local configSettings = common.compilerConfig
    local configFilePath = atlas2Folder .. configSettings.filePath
    if not helper.fileExist(configFilePath) then
        -- no config file; just use the default args.
        debugPrint('No compiler configuration file found.')
        return args
    end

    local setting = M.readYAML(configFilePath)
    verifyKeys(setting, configSettings.keys)
    -- no keys to handle for the moment. Ends here.
end

-- generate compiler input formations from given primary and secondary Atlas2 folders
-- primary(string): primary Atlas2 folder; will use tables in it, and output to this folder.
-- secondaries(array): secondard Atlas2 folders; will search yaml/action/plist in it.
-- return args: table with keys that is needed by compile()
function M.applyDefaultArgs(primary,
                            secondaries,
                            skipActionPresenceCheck,
                            skipMarkdownGeneration)
    local ret = {}
    local defaults = common.compilerDefaultLocations

    -- if requested, do not pass actions folder into compiler
    -- so compiler do not check if action file appear in yaml exists
    if skipActionPresenceCheck then
        defaults.actions = nil
    end

    if skipMarkdownGeneration then
        defaults.markdown = nil
    end

    -- getPath return file path if the file exists or is considered mandatory
    local getPath = function(isOptional, path)
        if not isOptional then
            local msg = '[Internal]: nil path provided for '
            msg = msg .. 'required Schooner compiler input'
            assert(path ~= nil, msg)
        end
        return (not isOptional or helper.fileExist(path)) and path or nil
    end
    local addIfNotNil = function(t, isOptional, path)
        local actualPath = getPath(isOptional, path)
        if actualPath then
            table.insert(t, actualPath)
        end
    end

    for key, setting in pairs(defaults) do
        local path = setting.path
        if not setting.multiple then
            -- only apply primary Atlas2 folder
            ret[key] = getPath(setting.optional, primary .. path)
        else
            -- apply both primary and secondary Atlas2 folders.
            local items = {}
            addIfNotNil(items, setting.optional, primary .. path)
            for _, atlas2 in ipairs(secondaries or {}) do
                addIfNotNil(items, setting.optional, atlas2 .. path)
            end
            if next(items) ~= nil then
                ret[key] = items
            end
        end

        -- specially, for limit table version, read the file and get the value
        if key == 'limitTableVersion' and ret[key] ~= nil then
            ret[key] = helper.readFile(ret[key])
        end
    end
    debugPrint('compiler args before apply setting: ' .. dump(ret))
    M.applyCompilerConfiguration(primary, ret)
    debugPrint('compiler args after apply setting: ' .. dump(ret))
    return ret
end

function M.compileAndVerifyAtlas2Folders(primary,
                                         secondaries,
                                         skipActionPresenceCheck,
                                         skipMarkdownGeneration)
    debugPrint(
    'primary: ' .. primary .. ', secondaries: ' .. dump(secondaries) ..
    ', skipActionPresenceCheck: ' .. tostring(skipActionPresenceCheck) ..
    ', skipMarkdownGeneration: ' .. tostring(skipMarkdownGeneration))
    M.compileAndVerify(M.applyDefaultArgs(primary, secondaries,
                                          skipActionPresenceCheck,
                                          skipMarkdownGeneration))
end

function M.compileAndVerify(args)
    local compiledSequence = M.compile(args.main, args.limit, args.condition,
                                       args.sample, args.limitTableVersion, nil,
                                       args.plists, args.actions,
                                       args.testDefinition, args.markdown)
    local targetFile = io.open(args.output, 'w')
    targetFile:write('return  ' .. pl.pretty.write(compiledSequence))
    targetFile:close()
    -- Load coverage table from targetFile and compare with compiledSequence
    local loadfile = function(filename)
        local data = helper.readFile(filename)
        return Atlas.loadRestricted(data, nil, nil)
    end
    local readBackSequence = loadfile(args.output)
    local compareSuccess, failInfo = helper.compareTable(compiledSequence,
                                                         readBackSequence)
    if not compareSuccess then
        M.dumpCompareFailInfo(failInfo)
        error("Compiler output changed after writing to file")
    end
end

return M
