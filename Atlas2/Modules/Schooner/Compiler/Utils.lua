local pl = require('pl.import_into')()

local M = {}

-------------------------------------------------------------------------------
--- Types ---
-------------------------------------------------------------------------------

function M.isValidType(t, typeName) return t ~= nil and type(t) == typeName end

function M.isNonEmptyArray(a) return M.isValidTable(a) and #a > 0 end

function M.isValidBoolean(b) return M.isValidType(b, 'boolean') end

function M.isValidFunction(f) return M.isValidType(f, 'function') end

function M.isValidNumber(n) return M.isValidType(n, 'number') end

function M.isValidString(s) return M.isValidType(s, 'string') end

function M.isNonEmptyChar(s) return M.isNonEmptyString(s) and s:len() == 1 end

function M.isSingleLetter(s) return M.isNonEmptyChar(s) and s:match('[%a]') == s end

function M.isNonEmptyString(s) return M.isValidString(s) and s:len() > 0 end

function M.isValidTable(t) return M.isValidType(t, 'table') end

function M.isNonEmptyTable(t) return M.isValidTable(t) and pl.tablex.size(t) > 0 end

function M.isEmptyTable(t) return M.isValidTable(t) and pl.tablex.size(t) == 0 end

-------------------------------------------------------------------------------
--- Plists ---
-------------------------------------------------------------------------------

-- This passes data & date entries as is
function M.read_plist(path)
    -- Read & parse plist as XML
    local plistFile = io.open(path, 'r')
    local contents = plistFile:read('*all')
    plistFile:close()

    local firstTag, secondTag = '<%?%s*xml.->%s*', '<!.->%s*'
    contents = contents:gsub(firstTag .. secondTag, '')

    local rawPlist = pl.xml.parse(contents)

    -- Convert raw table into something useful
    local handleTag -- forward reference

    local function handlePlistTag(tbl) return handleTag(tbl[1] or {}) end

    local function handleArrayTag(tbl)
        local array = {}

        for _, elem in ipairs(tbl) do
            table.insert(array, handleTag(elem))
        end

        return array
    end

    local function handleBooleanTag(tbl) return tbl.tag == 'true' end

    local function handleDictTag(tbl)
        local dict = {}

        local key = nil
        for _, elem in ipairs(tbl) do
            if elem.tag == 'key' then
                key = tostring(elem[1]) or error('Key missing')
            else
                if M.isValidString(key) then
                    dict[key] = handleTag(elem)
                end
            end
        end

        return dict
    end

    local function handleNumberTag(tbl)
        return tonumber(tbl[1]) or
               error('"' .. pl.pretty.write(tbl[1]) .. '" is not a valid number')
    end

    local function handleStringTag(tbl)
        return tostring(tbl[1]) or
               error('"' .. pl.pretty.write(tbl[1]) .. '" is not a valid string')
    end

    local dispatchTable = {
        array = handleArrayTag,
        dict = handleDictTag,
        ['false'] = handleBooleanTag,
        integer = handleNumberTag,
        plist = handlePlistTag,
        real = handleNumberTag,
        string = handleStringTag,
        ['true'] = handleBooleanTag
    }

    handleTag = function(tbl)
        local processedTag = dispatchTable[tbl.tag](tbl)

        if processedTag ~= nil then
            return processedTag
        else
            return tbl
        end
    end

    return handleTag(rawPlist)
end

function M.write_plist(path, tbl)
    local plistHeader = '<?xml version="1.0" encoding="UTF-8"?>\n' ..
                        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ' ..
                        '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n' ..
                        '<plist version="1.0">'
    local plistFooter = '\n</plist>\n'

    local handleType -- forward reference

    local function handleBooleanType(obj)
        if obj then
            return pl.xml.new('true')
        else
            return pl.xml.new('false')
        end
    end

    local function handleNumberType(obj)
        local tagType
        if math.type(obj) == 'integer' then
            tagType = 'integer'
        else
            tagType = 'real'
        end

        local numberTag = pl.xml.new(tagType)
        numberTag[1] = tostring(obj)

        return numberTag
    end

    local function handleStringType(obj)
        local stringTag = pl.xml.new('string')
        stringTag[1] = obj

        return stringTag
    end

    local function handleTableType(obj)
        if #obj == 0 then
            local dictTag = pl.xml.new('dict')

            for k, v in pl.tablex.sort(obj) do
                local keyTag = pl.xml.new('key')
                keyTag[1] = tostring(k)

                table.insert(dictTag, keyTag)
                table.insert(dictTag, handleType(v))
            end

            return dictTag
        else
            local arrayTag = pl.xml.new('array')

            for _, v in ipairs(obj) do
                table.insert(arrayTag, handleType(v))
            end

            return arrayTag
        end
    end

    local dispatchTable = {
        boolean = handleBooleanType,
        number = handleNumberType,
        string = handleStringType,
        table = handleTableType
    }

    handleType = function(obj)
        local objType = type(obj)

        return (dispatchTable[objType] or error('Unnown type ' .. objType))(obj)
    end

    local xmlString =
    plistHeader .. pl.xml.tostring(handleType(tbl), '', '\t') .. plistFooter

    local plistFile = io.open(path, 'w')
    plistFile:write(xmlString)
    plistFile:close()
end

-------------------------------------------------------------------------------
--- Misc ---
-------------------------------------------------------------------------------

-- From BurgundyUtils.lua
-- Works in both Group and Action phase

function M.stringify(o, delimiter)
    if delimiter == nil then
        delimiter = ' '
    end

    if type(o) == 'table' then
        local s = ''
        for _, v in pairs(o) do
            -- if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. M.stringify(v) .. delimiter
        end

        if delimiter ~= '' then
            s = s:sub(1, -2)
        end

        return s
    else
        return tostring(o)
    end
end

function M.log(print_func, test, action, message)
    message = M.stringify(message)

    local logHeader = "<<" .. test .. "/" .. action .. ">>  "
    if (message ~= nil) then
        print_func(logHeader .. message)
    else
        print_func(logHeader .. "nil")
    end
end

function M.absolutePath(path)
    -- This should come from an Atlas API like getResource
    if Atlas then
        return string.gsub(Atlas.assetsPath, 'Assets', path)
    end
    if Device then
        return string.gsub(Device.assetsPath, 'Assets', path)
    end
    if Group then
        return string.gsub(Group.assetsPath, 'Assets', path)
    end

    error("Can't find Atlas, Group, or Device. Is this running in Atlas 2?")
end

-- From Burgundy/BurgundyInnerHelpers.lua
function M.tokenize(string, delimiter)
    local tokens = {}

    for x in string.gmatch(string, "[^" .. delimiter .. "]+") do
        table.insert(tokens, x)
    end

    return tokens
end

function M.getArgsInMain(actionFileName)
    if actionFileName == nil then
        error("actionFileName cannot be nil")
    end

    local actionPath = M.absolutePath("Actions/" .. actionFileName .. ".lua")
    if not M.exists(actionPath) then
        actionPath = actionFileName
    end

    local actionFile = io.open(actionPath, "rb")
    if actionFile == nil then
        error("Could not file action file: " .. actionPath)
    end
    local actionText = actionFile:read("*all")
    actionFile:close()

    -- Find the main function
    return string.match(actionText, "function%s+main%((.-)%)")
end

-- From Burgundy/BurgundyInnerHelpers.lua
-- Given main arg signature, convert dictionary of key/value args into positional
function M.keyValueToPositional(actionFileName,
                                keyValueArgs,
                                argSignature,
                                ignoreTooMany)
    if keyValueArgs == nil or argSignature == nil then
        error("keyValueArgs and argSignature cannot be nil")
    end

    if argSignature == "" then
        if keyValueArgs ~= nil and next(keyValueArgs) ~= nil then
            error("Action " .. actionFileName .. " takes no arguments")
        end

        return {}
    end

    -- Scrub
    argSignature = string.gsub(argSignature, " ", "")
    argSignature = string.gsub(argSignature, "\n", "")
    local argNames = M.tokenize(argSignature, ",")

    if pl.tablex.size(keyValueArgs) > pl.tablex.size(argNames) and
    not ignoreTooMany then
        error("Provided too many arguments for " .. actionFileName)
    end

    local argValues = {}
    local index = 0
    for _, k in ipairs(argNames) do
        index = index + 1
        argValues[index] = keyValueArgs[k]
    end

    return argValues
end

function M.doesTablePathExist(tbl, path_str, leaf_type)
    if not M.isValidTable(tbl) then
        return false
    end

    if leaf_type == nil then
        leaf_type = 'table'
    end
    if not M.isNonEmptyString(leaf_type) then
        local msg = 'leaf_type must be a valid Lua type string '
        msg = msg .. 'such as "number", "string", "table", ...'
        error(msg)
    end

    local pathSegments = pl.stringx.split(path_str, '.')

    local lastIdx = #pathSegments
    for segmentIdx, pathSegment in ipairs(pathSegments) do
        tbl = tbl[pathSegment]
        if segmentIdx == lastIdx then
            if type(tbl) ~= leaf_type then
                return false
            end
        else
            if not M.isNonEmptyTable(tbl) then
                return false
            end
        end
    end

    return true
end

-- Atlas 2 seems to reserialize some pointers as tables with boolean metatables (invalid)
function M.cleanUpBadMetatables(tbl)
    for k, v in pairs(tbl) do
        local mtType = type(getmetatable(v))
        if mtType ~= 'nil' and mtType ~= 'table' then
            tbl[k] = nil
        end

        if type(tbl[k]) == 'table' then
            tbl[k] = M.cleanUpBadMetatables(v)
        end
    end

    return tbl
end

function M.createItemAtTablePath(tbl, path_str, item)
    local pathSegments = pl.stringx.split(path_str, '.')
    local tblAlias = tbl

    if not M.isValidTable(tblAlias) then
        error('tbl must be a valid table')
    end

    local lastIdx = #pathSegments
    for idx, pathSegment in ipairs(pathSegments) do
        if not M.isValidTable(tblAlias[pathSegment]) then
            tblAlias[pathSegment] = {}
        end

        if idx == lastIdx then
            tblAlias[pathSegment] = item
        else
            tblAlias = tblAlias[pathSegment]
        end
    end
end

-- Find proper length (max index) of table with nil value.
-- ex: {1, nil, 2} should have length 3.
function M.findProperLength(t)
    local length = 0
    for index, _ in pairs(t) do
        if length < index then
            length = index
        end
    end
    return length
end

function M.basename(path)
    local sepItems = pl.stringx.split(path, '/')
    if M.isNonEmptyTable(sepItems) then
        return sepItems[#sepItems]
    else
        return ''
    end
end

function M.dirname(path)
    local dirname = '/'

    local sepItems = pl.stringx.split(path, '/')
    table.remove(sepItems)

    if M.isNonEmptyTable(sepItems) then
        dirname = pl.stringx.join('/', sepItems)
    end

    return dirname
end

-- pl has same function, but depends on lfs
function M.exists(name)
    local f = io.open(name)
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function M.format(templateStr, subTable)
    template = pl.text.Template(templateStr)

    local newSubTable = {}
    for k, v in pairs(subTable) do
        newSubTable[tostring(k)] = pl.pretty.write(v)
    end

    return template:safe_substitute(newSubTable)
end

function M.extractModuleNames(paths)
    local moduleNames = {}

    for _, path in ipairs(paths or {}) do
        local sepItems = pl.stringx.split(path, '/')
        if M.isNonEmptyTable(sepItems) then
            local basename = sepItems[#sepItems]
            local moduleNameParts = pl.stringx.split(basename, '.lua')
            if M.isNonEmptyTable(moduleNameParts) then
                table.insert(moduleNames, moduleNameParts[1])
            end
        end
    end

    return moduleNames
end

function M.parse(s, pattern, varNames)
    local matches = table.pack(string.gmatch(s, pattern)())
    local numItems = math.min(matches.n, pl.tablex.size(varNames))

    local matchTable = {}
    for idx = 1, numItems do
        matchTable[varNames[idx]] = matches[idx]
    end

    return matchTable
end

function M.requirePlugin(plugin_name)
    if Atlas ~= nil and M.isValidFunction(Atlas.loadPlugin) then
        package.loaded[plugin_name] = Atlas.loadPlugin(plugin_name)
    else
        package.loaded[plugin_name] = require(plugin_name)
    end

    return package.loaded[plugin_name]
end

-- os.clock() apparently returns the sum of the time of all participating threads
-- So will use os.time() for round seconds, os.clock() for fractional part
function M.sleep(s)
    local intPart = math.floor(s)
    local endTime = os.time() + intPart
    repeat
    until os.time() >= endTime

    local fracPart = s - intPart
    endTime = os.clock() + fracPart
    repeat
    until os.clock() >= endTime
end

-- Originally from Matchbox CommonFunc.lua
-- run function catch_f if function f throws any exception
function M.try(f, catch_f)
    local didSucceed, resultOrException = pcall(f)
    if not didSucceed then
        catch_f(resultOrException)
    else
        return resultOrException
    end
end

function M.unnil(obj)
    if obj == nil then
        return 'nil'
    else
        return obj
    end
end

-------------------------------------------------------------------------------
--- Sampling ---
-------------------------------------------------------------------------------

-- Used to skip tables during sample() / acyclicCopy()
M.skipMeKey = 'f3d6db2a-8d9c-11ea-965c-cb8c8be06cc9'

function M._acyclicCopy(t, cache)
    if type(t) ~= 'table' then
        return t
    end
    if cache[t] then
        return tostring(cache[t])
    end
    if t[M.skipMeKey] ~= nil then
        return tostring(t)
    end

    if not pl.types.is_iterable(t) then
        error('table is not iterable')
    end

    local res = {}
    cache[t] = res
    for k, v in pairs(t) do
        k = M._acyclicCopy(k, cache)
        v = M._acyclicCopy(v, cache)
        res[k] = v
    end

    return res
end

-- 'Medium' copy. Not as complete as deepcopy
-- Used for pretty-printing tables with cycles
-- Modified pl.tablex.deepcopy()
function M.acyclicCopy(t) return M._acyclicCopy(t, {}) end

-- mask - 'I' - info, 'G' - globals, 'L' - locals, 'T' - traceback, 'U' - upvalues
function M.sample(mask)
    if not M.isValidString(mask) then
        mask = 'IGLTU'
    end

    local shouldGetInfo = string.match(mask, 'I')
    local shouldGetGlobals = string.match(mask, 'G')
    local shouldGetLocals = string.match(mask, 'L')
    local shouldGetTraceback = string.match(mask, 'T')
    local shouldGetUpvalues = string.match(mask, 'U')

    local info

    -- Get needed info
    local whatStr = ''
    if shouldGetUpvalues then
        -- Get calling function for upvalues
        whatStr = 'f'
    end

    if shouldGetInfo then
        -- Get currentline, name, namewhat, linedefined, short_src, source, and what for calling function
        whatStr = whatStr .. 'lnS'
    end

    if whatStr == '' then
        info = {}
    else
        info = debug.getinfo(2, whatStr)
    end

    local globals, locals, upvalues, idx = {}, {}, {}, 1

    if shouldGetGlobals then
        for name, value in pairs(_G) do
            if name ~= '_G' then
                globals[name] = M.acyclicCopy(value)
            end
        end

        info.globals = globals
    end

    -- locals and upvalues from
    -- https://stackoverflow.com/questions/2834579/print-all-local-variables-accessible-to-the-current-scope-in-lua
    if shouldGetLocals then
        while true do
            local name, value = debug.getlocal(2, idx)
            if name ~= nil then
                locals[name] = M.acyclicCopy(value)
            else
                break
            end

            idx = 1 + idx
        end

        info.locals = locals
        idx = 1
    end

    if shouldGetUpvalues then
        local func = info.func
        while true do
            local name, value = debug.getupvalue(func, idx)
            if name ~= nil then
                upvalues[name] = M.acyclicCopy(value)
            else
                break
            end

            idx = 1 + idx
        end

        info.upvalues = upvalues
    end

    if shouldGetTraceback then
        info.traceback = debug.traceback()
    end

    -- Clean up
    info.func = nil
    info.short_src = nil

    return info
end

function M.show(...)
    local varNames = table.pack(...)

    -- Get all vars in scope
    local varNameToValue = {}
    for level = 2, math.maxinteger do
        if debug.getinfo(level) == nil then
            break
        end

        for localIdx = 1, math.maxinteger do
            local name, value = debug.getlocal(level, localIdx)
            if name == nil then
                break
            end

            if varNameToValue[name] == nil then
                varNameToValue[name] = { value = value }
            end
        end
    end

    local pieces = {}
    for _, varName in ipairs(varNames) do
        local value = (varNameToValue[varName] or {}).value or _G[varName]

        table.insert(pieces, varName .. ' = ' .. pl.pretty.write(value))
    end

    print('Line ' .. debug.getinfo(2, 'l').currentline .. ': ' ..
          pl.stringx.join(', ', pieces))
end

return M
