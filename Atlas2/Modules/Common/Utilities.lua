-------------------------------------------------------------------
----***************************************************************
----common functions
----***************************************************************
-------------------------------------------------------------------
local CommonFunc = {}
-- special string used to store nil value
-- to distinguish a variable that is not defined.
CommonFunc.NIL = 'NIL_VARIABLE_VALUE'

-- string split by a single delimiter.
-- Delimiter ",,," will be treated as ",,,".
-- Empty element between delimiters will be treated as empty string.
-- @param input: string type
-- @param delimiter: string type
-- @return string array after split
-- e.g. splitString("a,b,,,c,d",",") => {"a","b","","","c","d"}
function CommonFunc.splitString(input, delimiter)
    if not input or not delimiter then
        return nil
    end
    input = tostring(input)
    delimiter = tostring(delimiter)
    if delimiter == '' then
        return false
    end
    local pos, arr = 0, {}
    for st, sp in function()
        return string.find(input, delimiter, pos, true)
    end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

-- string split by a mixed delimiter.
-- Delimiter "&|" will be treated as any delimiter composed by consecutive "&" and "|".
-- @param input: string type
-- @param delimiter: string type
-- @return string array after split
-- e.g. splitBySeveralDelimiter("a&&b||c&&d","&|") => {"a","b","c","d"}
function CommonFunc.splitBySeveralDelimiter(input, delimiter)
    if not input or not delimiter then
        return nil
    end
    local resultStrArr = {}
    string.gsub(input, '[^' .. delimiter .. ']+', function(w)
        table.insert(resultStrArr, w)
    end)
    return resultStrArr
end

-- gain delimiter sequence in a string.
-- Delimiter "&|" will be treated as any delimiter composed by consecutive "&" and "|".
-- @param input: string type
-- @param delimiter: string type
-- @return delimiter array in a string
-- e.g. gainDelimiterSequence("a&&b||c&&d","&|") => {"&&","||","&&"}
function CommonFunc.gainDelimiterSequence(input, delimiter)
    if not input or not delimiter then
        return nil
    end
    local resultStrArr = {}
    string.gsub(input, '[' .. delimiter .. ']+', function(w)
        table.insert(resultStrArr, w)
    end)
    return resultStrArr
end

-- remove extra spaces at begin and end
-- @param str: input string
-- @return string after trimmed
-- e.g. trim(" a == b  ") => "a == b"
function CommonFunc.trim(str)
    if not str then
        return nil
    else
        return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
    end
end

-- present table as key-value string format
-- @param o: input table
-- @return key-value string format
-- e.g. dump({"a","b","c",["d"] = 4, ["e"] = 5,}) => { [1] = a,[2] = b,[3] = c,["d"] = 4,["e"] = 5,}
function CommonFunc.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. CommonFunc.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

-- deepCompare if 2 object are the same, support table recursively value compare
-- @param t1: a table to compare
-- @param t2: a table to compare against t1.
function CommonFunc.deepCompare(t1, t2)
    local type1 = type(t1)
    local type2 = type(t2)
    if type1 ~= type2 then
        return false
    end
    if type(t1) ~= 'table' and type(t2) ~= 'table' then
        return t1 == t2
    end

    -- keys that has been compared
    local compared = {}
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not CommonFunc.deepCompare(v1, v2) then
            return false
        end
        compared[k1] = true
    end

    for k2 in pairs(t2) do
        if not compared[k2] then
            return false
        end
    end
    return true
end

-- return true if given table1 and table2 are identical: same length, same values.
-- return false and the different node index.
-- used to check if CSV title row is expected.
-- only works for array; do not support dictionary with key-value pairs.
function CommonFunc.arrayCmp(t1, t2)
    local i = 1
    while true do
        if t1[i] == nil and t2[i] == nil then
            return true
        end
        if t1[i] ~= t2[i] then
            return false, i
        end
        i = i + 1
    end
end

-- check if file exists at designated path
-- @param path: string type
-- @return whether the file exists
-- e.g. fileExists("/Users/gdlocal/Library/Atlas2/Assets/Main.csv") => true
function CommonFunc.fileExists(path)
    if not path then
        return nil
    end
    local file = io.open(path, "rb")
    if file then
        file:close()
        return true
    end
    return false
end

-- read file contents
-- @param path: string type
-- @return file contents, string type
function CommonFunc.fileRead(path)
    if not path then
        return nil
    end
    local file = io.open(path, "r")
    if file then
        local data = file:read("*all")
        file:close()
        return data
    end
    return ""
end

-- check if key exists in a dictionary
-- e.g. hasKey({["d"] = 4, ["e"] = 5,},"d") => true
function CommonFunc.hasKey(tab, key)
    if not tab or not key then
        return nil
    end
    for k in pairs(tab) do
        if k == key then
            return true
        end
    end
    return false
end

-- check if value exists in an array
-- e.g. hasVal({"d", "e",},"d") => true
function CommonFunc.hasVal(valueArr, valueStr)
    for _, value in ipairs(valueArr) do
        if value == valueStr then
            return true
        end
    end
    return false
end

-- return keys of a table
-- e.g. tableKeys({4,5,["a"]="44",}) => {1,2,"a",}
function CommonFunc.tableKeys(input_table)
    if not input_table then
        return nil
    end
    local output_keys = {}
    for k in pairs(input_table) do
        table.insert(output_keys, k)
    end
    return output_keys
end

-- system sleep
function CommonFunc.sleep(n)
    os.execute("sleep " .. tonumber(n))
end

-- run function catch_f if function f throws any exception
function CommonFunc.try(f, catch_f)
    local status, exception = xpcall(f, debug.traceback)
    if not status then
        catch_f(exception)
    end
end

-- parse given conditions string to table
-- {
--     {'left':left, 'right':right, 'operator':'!='}
--     {'left':left, 'right':right, 'operator':'==', 'relationToLeft':'&&'}
-- }
function CommonFunc.parseCondition(str, errorMsg)
    local ret = {}
    local errMsg
    if CommonFunc.trim(str) == "" or CommonFunc.trim(str) == nil then
        return ret
    end

    if errorMsg ~= nil then
        assert(type(errorMsg) == "string", "the 2nd args passed should be of type string")
        errMsg = errorMsg
    else
        errMsg = ""
    end

    local compareStr = ""
    -- Prefixing `&&` to the expression so the whole string matches `&& singleExpression` pattern,
    -- when condition expression is like `singleExpression (&& or || singleExpression)*`.
    local tempStr = "&& " .. str
    for relationToLeft, expression in string.gmatch(tempStr, "([&|]+)([^&|]+)") do
        compareStr = compareStr .. relationToLeft .. expression

        -- check relation operator, need to be '&&' or '||'
        if relationToLeft ~= "&&" and relationToLeft ~= "||" then
            error(tostring(errMsg) .. string.format('Invalid relationship between condition: %s', relationToLeft))
        end

        local left, operator, right = string.match(expression, "^%s*([^!=&| ]+)%s*([!=]+)%s*([^!=&| ]+)%s*$")

        -- check left and right, should not contain one of '!=&| '; check operator, should be '!=' or '=='
        if left == nil or operator == nil or right == nil then
            error(tostring(errMsg) .. string.format('Invalid sub condition expression: %s', expression))
        elseif operator ~= "!=" and operator ~= "==" then
            error(tostring(errMsg) .. string.format('Invalid operator: %s', operator))
        end

        table.insert(ret, {left = left, right = right, operator = operator, relationToLeft = relationToLeft})
    end

    if tempStr ~= compareStr then
        error(tostring(errMsg) .. string.format('Invalid condition expression: %s', str))
    end

    -- remove the first relation operator '&&'
    ret[1].relationToLeft = nil
    return ret
end

-- calculate boolean logic for condition column
-- @param str: input condition string
-- @return boolean value
-- e.g. calConditionVal(" sn == 2 && ver != 4",{["sn"] = "2",["ver"] = "4",["boardid"] = "C"}) => false
function CommonFunc.calConditionVal(str, conditionValueTable)
    if type(str) ~= "string" then
        error("Invalid condition (" .. tostring(str) .. "); expect a string equation")
    end

    local conditions = CommonFunc.parseCondition(str)
    local conditionResult = nil
    for index, condition in ipairs(conditions) do
        -- values
        local left = condition.left
        local right = condition.right
        -- == != within one condition
        local operator = condition.operator
        -- && || between conditions equations
        local relationToLeft = condition.relationToLeft
        local leftValue
        local rightValue
        if conditionValueTable[left] == nil and conditionValueTable[right] == nil then
            error('Condition ' .. left .. ' or ' .. right .. ' value not set')
        end

        if conditionValueTable[left] then
            leftValue = conditionValueTable[left]
        else
            leftValue = tostring(left)
        end

        if conditionValueTable[right] then
            rightValue = conditionValueTable[right]
        else
            rightValue = tostring(right)
        end

        local currentResult = nil
        if operator == '==' then
            currentResult = leftValue == rightValue
        elseif operator == '!=' then
            -- support only !=
            currentResult = leftValue ~= rightValue
        end

        -- accumulating result
        if relationToLeft == nil then
            -- first item
            assert(index == 1, 'condition.relationToLeft is nil but is not the 1st item')
            conditionResult = currentResult
        elseif relationToLeft == '&&' then
            conditionResult = conditionResult and currentResult
        elseif relationToLeft == '||' then
            conditionResult = conditionResult or currentResult
        end
    end

    return conditionResult
end

-- parse and return parameter list for further indexing, support dictionaries and arrays
-- @param paraStr: input parameter string
-- @return parameter dictionary or array
-- e.g. parseParameter("{\"Input\":\"success\",\"Output\":\"SN\",\"timeout\": 50}")
--      => { ["Input"] = "success",["Output"] = "SN",["timeout"] = "50",}
--      parseParameter("[a,b,c,1,2,3]")
--      => {"a","b","c","1","2","3"}
function CommonFunc.parseParameter(paraStr)
    local paraList = {}
    local json = require("Serialization/JSONSerialization")
    if paraStr == "" then
        return paraList
    else
        return json.LoadFromData(paraStr)
    end
end

-- parse static conditions and store in an array
-- @param allowValStr: allowable value string, seperate by ";"
-- @return condition array
-- e.g. parseValArr("00011a;00011b;000111") => {"00011a","00011b","000111",}
function CommonFunc.parseValArr(allowValStr)
    local allowValArr
    allowValStr = CommonFunc.trim(allowValStr)
    allowValArr = CommonFunc.splitBySeveralDelimiter(allowValStr, ";")
    for i in ipairs(allowValArr) do
        allowValArr[i] = CommonFunc.trim(allowValArr[i])
    end
    return allowValArr
end

-- run shell commands
function CommonFunc.runShellCmd(cmd)
    local RunShellCommand = Device.getPlugin("RunShellCommand")
    return RunShellCommand.run(cmd)
end

-- create extra log
function CommonFunc.exLog(...)
    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    local homePath = RunShellCommand.run("echo ~")
    homePath = homePath.output
    homePath = CommonFunc.trim(homePath)
    local file = io.open(homePath .. "/Desktop/extra.log", "a+")
    if file then
        for _, v in ipairs({...}) do
            file:write(tostring(v))
        end
        file:close()
        return nil
    end
    return nil
end

-- return a cloned table.
function CommonFunc.clone(org)
    local function copy(orgs, res)
        for k, v in pairs(orgs) do
            if type(v) ~= "table" then
                res[k] = v;
            else
                res[k] = {};
                copy(v, res[k])
            end
        end
    end
    local res = {}
    copy(org, res)
    return res
end

-- create a read-only reference of a given table.
-- caller specify what error msg to report
-- when table write is attempted.
function CommonFunc.readOnly(t, msg)
    local proxy = {}
    local mt = {
        __index = t,
        __newindex = function()

            local message = msg or [[
                                    Not allowed to modify local/global/condition table;
                                    use tech csv Output column to set values.
                                ]]
            error(message, 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

-- the "map" operation: generate a new array by calling given function
-- to every item in current array
function CommonFunc.map(func, t)
    local ret = {}
    for i = 1, #t, 1 do
        ret[i] = func(t[i])
    end
    return ret
end

-- process message to fit in failure reason:
-- 1. remove line returns
-- 2. trim to 512 bytes
function CommonFunc.trimFailureMsg(msg)
    -- remove all \r and \n so this does not corrupt records.csv
    msg = string.gsub(msg, '[\r\n]', '; ')

    -- insight does not allows error message > 512 bytes.
    if (#msg > 512) then
        msg = string.sub(msg, 1, 509) .. '...'
    end

    return msg
end

-- check if given string is boolean Y/N/y/n
function CommonFunc.isCharBooleanOrEmpty(c)
    return c ~= nil and CommonFunc.hasVal({'', 'Y', 'N'}, c:upper())
end

-- check if given item is nil or empty, for csv cell.
function CommonFunc.notNILOrEmpty(c)
    return c ~= nil and c ~= ''
end

-- return if given number has no fractional part
-- used to check if sampling rate is valid
-- sampling rate accept only uint 1-100.
function CommonFunc.isInt(i)
    return i % 1 == 0
end

-- Check Atlas minimum allowable running version
function CommonFunc.checkAtlasVersion(userVersion)
    local result = Atlas.compareVersionTo(userVersion)
    if result == Atlas.versionComparisonResult.lessThan then
        error("Atlas version " .. Atlas.version .. " is lower then expected version(" .. userVersion .. ")")
    end
end

-- remove new line
-- @param str: input string
-- @return string after trimmed
function CommonFunc.trimNewLine(str)
    return string.gsub(str, '\n', '')
end

-- Convert hex to string
function CommonFunc.hex2str(hex)
    local str, _ = hex:gsub("(%x%x)[ ]?", function(word)
        return string.char(tonumber(word, 16))
    end)
    return str
end

-- Convert string to hex
function CommonFunc.str2hex(str)
    local hex, _ = str:gsub("(.)", function(char)
        return string.format("%02X", string.byte(char, 1, 1))
    end)
    return hex
end

-- Convert string starting with ^ to \n
-- @param delimiter: input delimiter
-- @return string after process.
-- e.g. "^]" -> "\n]"
function CommonFunc.convertCaretToNewLine(str)
    if str then
        str = string.gsub(str, "^^", "\n")
    end
    return str
end

-- Remove the value defined in table
-- @param tab: The table whose value needs to be deleted
-- @param value: The value to be removed
function CommonFunc.removeTabValue(tab, value)
    local filterTab = {}
    for k, v in pairs(tab) do
        if v ~= value then
            filterTab[k] = v
        end
    end
    return filterTab
end

-- ! @brief Convert value to binary.
-- ! @param v_dec<number> ,the number(Decimal or hexadecimal)that needs be converted.
function CommonFunc.dec2bin(v_dec)
    local bin_str = ""
    if v_dec == 0 then
        return 0
    end
    while v_dec > 0 do
        local rr = v_dec % 2
        bin_str = rr .. bin_str
        v_dec = math.floor((v_dec - rr) / 2)
    end
    return bin_str
end

-- ! @brief Convert hexString to float.
-- ! @param hexString<string> The hexString that needs to be converted. like: "0xBAA137F3"
-- ! @return <float number>, like: -0.0012299999361858
function CommonFunc.hex2float(hexString)
    if hexString == nil then
        return 0
    end
    local t = type(hexString)
    if t == "string" then
        hexString = string.pack("<I", hexString)
    end
    return string.unpack("<f", hexString)
end

-- ! @brief Convert a number to bytes.
-- ! @param num(number) number need to be converted. such as: 0x229
-- ! @return bytes table. such as {2，41}
function CommonFunc.numberToBytes(num)
    local bytes = {}
    while num > 0 do
        local byte = math.floor(num % 0x100)
        table.insert(bytes, 1, byte)
        num = math.floor(num / 0xFF)
    end
    return bytes
end

-- ! @brief Convert a string to a table of hexadecimal byte representations.
-- ! @param data<string>, The input string to be converted.
-- ! @return <table>, A table containing the hexadecimal byte values of the string.
function CommonFunc.stringToByteTable(data)
    local hexadecimal_character = {}
    for i = 1, #data do
        table.insert(hexadecimal_character, string.format("0x%02X", string.byte(string.sub(data, i, i))))
    end
    return hexadecimal_character
end

-- ! @brief Convert a table of byte values to a string.
-- ! @param ret<table>, A table containing byte values (numbers) to be converted to characters.
-- ! @return <string>, A string constructed from the byte values in the input table.
function CommonFunc.stringFromByteTable(data)
    if not data or next(data) == nil then
        error("Empty data input!")
    end
    local result = ""
    for _, v in pairs(data) do
        if 32 <= v and v <= 126 then
            result = result .. string.char(v)
        end
    end
    return tostring(result)
end

-- ! @brief Calculate basic statistics (max, min, average, Vpp, RMS) for a given array of numbers.
-- ! @param array<table>, A table containing numerical values for statistical calculation.
-- ! @return <table>, A table containing the calculated statistics:
--      - maximum: The maximum value in the array.
--      - minimum: The minimum value in the array.
--      - average: The average of all values in the array.
--      - vpp: The peak-to-peak value (maximum - minimum).
--      - rms: The root mean square value, calculated as math.sqrt(rmsBase/count)).
function CommonFunc.calculateStatistics(array)
    local result = {}
    local count, sum, rmsBase = 0, 0, 0
    local max, min = array[1], array[1]
    for index, value in ipairs(array) do
        count = index
        sum = sum + value
        if max < value then
            max = value
        end
        if value < min then
            min = value
        end
        rmsBase = rmsBase + value ^ 2
    end
    local average = sum / count
    if (tostring(average) == "nan") then
        error("The data obtained is empty")
    end
    result.maximum = tonumber(max)
    result.minimum = tonumber(min)
    result.average = tonumber(average)
    result.vpp = tonumber(max) - tonumber(min)
    result.rms = math.sqrt(rmsBase / count)
    return result
end

-- ! @brief Convert scientific notation to number
-- ! @param str(string) str of scientific notation. like: -1.33E+3
-- ！@return number. like: -1330
function CommonFunc.convertToNumber(str)
    if not str then
        error("str input is nil.")
    end
    local base, exponent = string.match(str, '([+-]%d+[.%d+]?)E([+-]%d+)')
    if base and exponent then
        return tonumber(base) * 10 ^ tonumber(exponent)
    end
    return tonumber(str) or 0
end

-- ! @brief Check input data type, make lua wrapper to comparable for single input or dictionary
-- ! @param input(string/dict) input of lua wrapper
-- ! @param additionalParameters(dict) additionalParameters of lua wrapper if exist
-- ! @param key(string) the key of a specific value
-- ! @return string, dictionary
-- ! @case1 processInputByKey("command1", {["expect"]="PASS"}, "command") should return: "command1", {["expect"] = "PASS"}
-- ! @case2 processInputByKey({["command"] = "command1", ["expect"] = "PASS"}) should return: "command1", {["command"] = "command1", ["expect"] = "PASS"}
function CommonFunc.processInputByKey(input, additionalParameters, key)
    assert(key and key ~= "", "Empty key parameter input!")
    if type(input) == "table" then
        assert(input[key] ~= nil, string.format("The key: %s is not found in input table", key))
        return input[key], input
    else
        return input, additionalParameters
    end
end

-- ! @brief Calculate the complementary set of two tables.
-- ! @param t1<table>, The first table (source table).
-- ! @param t2<table>, The second table (comparison table).
-- ! @return <table>, A table containing key-value pairs from t1 that are not present in t2.
-- ! @example complementarySetTable({a = 1, b = 2, c = 3}, {b = 2}) => {a = 1, c = 3}
function CommonFunc.complementaryTable(t1, t2)
    assert(type(t1) == "table", "t1 must be a table")
    assert(type(t2) == "table", "t2 must be a table")

    local result = {}
    for k, v in pairs(t1) do
        if t2[k] == nil then
            result[k] = v
        end
    end
    return result
end

return CommonFunc
