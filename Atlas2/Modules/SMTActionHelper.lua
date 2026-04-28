local Log = require("Common/logging")
local comFunc = require ("Common/Utilities")
local record = require ("Common/record")

local common = {}
common.testResult = true

local failMsg = ""
local testName = Device.test
local subtestname = Device.subtest

local function getlimitTable()
    -- it should be init in group level
    -- if not init, it will be empty table
    local variablePlugin = Device and Device.getPlugin("VariableTable") or nil
    local limitTable = variablePlugin and variablePlugin.getVar("limitsTable") or {}
    return limitTable
end

local function hasKey(table, key)
    return table ~= nil and key ~= nil and table[key] ~= nil
end

local function trim(str)
    return str:gsub("^%s*(.-)%s*$", "%1")
end

local function parse_list(str)
    str = str:gsub("^%s*%[%s*", ""):gsub("%s*%]%s*$", "")
    local elements = {}
    for elem in str:gmatch("[^,]+") do
        elem = elem:gsub("^%s*(.-)%s*$", "%1")
        if elem:match('^["\']') then
            elem = elem:gsub('^["\'](.*)["\']$', "%1")
            table.insert(elements, elem)
        elseif elem:lower():match('^0x') then
            elem = tonumber(elem:gsub("^0x", ""), 16)
            table.insert(elements, elem)
        else
            elem = tonumber(elem)
            table.insert(elements, elem)
        end
    end
    return elements
end

local function check_array_limit(input, array_limit_str)
    array_limit_str = trim(array_limit_str)
    if array_limit_str:match("^not%s+") then
        local sub_rule = array_limit_str:gsub("^not%s+", "")
        local elements = parse_list(sub_rule)
        return not comFunc.hasVal(elements, input)
    else
        local elements = parse_list(array_limit_str)
        return comFunc.hasVal(elements, input)

    end
end

local function filterVar(...)
    local vars = {...}
    local stringLimit, arrayLimit, subsubtestname = "", "", ""
    local isTargetFound = false
    for _, tbl in pairs(vars) do
        if isTargetFound then
            break
        end
        if type(tbl) == "table" then
            -- These keys are in same table and come from Compiler
            stringLimit = hasKey(tbl, "stringLimit") and tbl.stringLimit or stringLimit
            arrayLimit = hasKey(tbl, "arrayLimit") and tbl.arrayLimit or arrayLimit
            subsubtestname = hasKey(tbl, "subsubtest") and tbl.subsubtest or subsubtestname
            -- Use VariableTable limitsTable to get upperLimit, lowerLimit, unit
            -- upperLimit = hasKey(tbl, "upperLimit") and tbl.upperLimit or upperLimit
            -- lowerLimit = hasKey(tbl, "lowerLimit") and tbl.lowerLimit or lowerLimit
            -- unit = hasKey(tbl, "unit") and tbl.unit or unit
            -- WA for StringLimit - rdar://102753342, this key would be generated 100% for now
            if subsubtestname and subsubtestname ~= "" then
                isTargetFound = true
            end
        end
    end
    return stringLimit, arrayLimit, subsubtestname
end

local function proceedStringLimitRecords(targetStr, expectedStr, subsubtestname)
    -- String limit case - binary record
    failMsg = ''
    if targetStr == expectedStr then
        common.testResult = true
    else
        failMsg = 'String value [' .. tostring(targetStr) .. '] out of limit; expecting ' .. tostring(expectedStr)
        common.testResult = false
    end
    local ret = record.createRecord(common.testResult, testName, subtestname, subsubtestname, nil, failMsg)
    if not ret then
        common.testResult = false
    end
end

local function proceedNumberRecords(targetValue, limit, subsubtestname)
    failMsg = ''
    if limit ~= nil and tonumber(targetValue) then
        local isLimitPass = false
        common.testResult = true
        if limit.lowerLimit ~= "" and limit.upperLimit ~= "" then
            if limit.lowerLimit <= tonumber(targetValue) and tonumber(targetValue) <= limit.upperLimit then
                isLimitPass = true
            end
        elseif limit.lowerLimit == "" and limit.upperLimit ~= "" then
            if tonumber(targetValue) <= limit.upperLimit then
                isLimitPass = true
            end
        elseif limit.lowerLimit ~= "" and limit.upperLimit == "" then
            if tonumber(targetValue) >= limit.lowerLimit then
                isLimitPass = true
            end
        else
            Log.LogError("Unexpected limit value, pls check testPlan for more details!")
        end

        if not isLimitPass then
            failMsg = "Out of limit"
            common.testResult = false
        end
    end
    local ret = record.createRecord(targetValue, testName, subtestname, subsubtestname, limit, failMsg)
    if not ret then
        common.testResult = false
    end
end

local function proceedCommonRecords(targetValue, subsubtestname)
    failMsg = ''
    common.testResult = true
    if type(targetValue) == "boolean" then
        common.testResult = targetValue
        if not targetValue then
            failMsg = "Function return false"
        end
    else
        if type(targetValue) == "number" and (targetValue == math.huge or targetValue == -math.huge) then
            failMsg = "target value is inf"
            targetValue = false
        elseif tonumber(targetValue) and (tonumber(targetValue) == math.huge or tonumber(targetValue) == -math.huge) then
            targetValue = true
        end
    end
    local ret = record.createRecord(targetValue, testName, subtestname, subsubtestname, nil, failMsg)
    if not ret then
        common.testResult = false
    end

end

local function proceedArrayLimitRecords(targetValue, limit, subsubtestname)
    failMsg = ''
    if check_array_limit(targetValue, limit) then
        common.testResult = true
    else
        common.testResult = false
        failMsg = 'Target value [' .. tostring(targetValue) .. '] is not in allow list: ' .. tostring(limit)
    end
    local ret = record.createRecord(common.testResult, testName, subtestname, subsubtestname, nil, failMsg)

    if not ret then
        common.testResult = false
    end
end


common.RECORD_PATTEN =
    "[%%record%%]   [<%s> <%s> <%s>]   lower: %s   higher: %s  value: %s   unit: %s    result: %s   failMsg: %s"

common.FAIL_MSG = {
    BINARY_LIMIT_FAIL = "Binary records failure",
    STRING_NOT_MATCHED = "String value not matched",
    NUMBER_LIMIT_FAIL = "Out of limit"
}
common.MetaTableFlowLogging = {
    __index = function(t, key)
        return function(...)
            local delegate = rawget(t, "delegate")
            local stringLimit
            local arrayLimit
            local subsubtestname
            local upperLimit = ""
            local lowerLimit = ""
            local unit = ""
            local ret
            failMsg = ""

            -- get all elements
            stringLimit, arrayLimit, subsubtestname = filterVar(...)

            -- update device progress
            Device.updateProgress(testName .. ", " .. subtestname .. ", " .. subsubtestname)

            -- get limit from limitsTable
            local keyName = string.format("%s_%s_%s", testName, subtestname, subsubtestname)
            local limitTable = getlimitTable()
            if limitTable and limitTable[keyName] then
                upperLimit = limitTable[keyName].upperLimit or ""
                lowerLimit = limitTable[keyName].lowerLimit or ""
                unit = limitTable[keyName].unit or ""
            end

            -- limit for record
            local limit = {}
            limit.upperLimit = upperLimit
            limit.lowerLimit = lowerLimit
            limit.unit = unit

            -- add limitTable to additionalParams
            local vars = table.pack(...)
            if type(vars[vars.n]) == "table" then
                vars[vars.n].limitTable = {
                upperLimit = upperLimit,
                lowerLimit = lowerLimit,
                unit = unit
            }
            end

            common.testResult = true

            Log.LogFlowStart(testName, subtestname, subsubtestname)
            local result = {xpcall(delegate[key], debug.traceback, table.unpack(vars, 1, vars.n))}
            --[[
            Description for return length
            Case1: = 1 - func no returns
                    - binary records
            Case2: = 2 - binary/string/number returns
                    a.string -> stringlimit (binary records)
                    b.number -> numberlimit (parametric records)
                    c.binary -> binary records
            Case3: > 2 - multi-value returns
                    - binary records
            ]]

            -- remove first element for outputs return
            ret = comFunc.clone(result)
            table.remove(ret, 1)

            -- Fail to execute func, treat it as a fail case - binary record
            if not result[1] then
                common.testResult = false
                failMsg = "Error from function: " .. tostring(result[2])
                local errorSubsubtestname = 'ERROR_FROM_FUNCTION ' .. subsubtestname
                record.createRecord(false, testName, subtestname, errorSubsubtestname, nil, failMsg)
                Log.LogInfo(string.format(common.RECORD_PATTEN, testName, subtestname, tostring(subsubtestname),
                                          tostring(lowerLimit), tostring(upperLimit), "", unit or "",
                                          common.testResult and 'PASS' or 'FAIL', failMsg))
                return false
            else
                -- String limit case - binary record
                if stringLimit and stringLimit ~= "" then
                    -- We treat the element[2] as target string value
                    proceedStringLimitRecords(result[2], stringLimit, subsubtestname)
                elseif arrayLimit and arrayLimit ~= "" then
                    -- Handling for array limit case
                    proceedArrayLimitRecords(result[2], arrayLimit, subsubtestname)
                elseif (upperLimit and upperLimit ~= "") or (lowerLimit and lowerLimit ~= "") then
                    -- handling for number limit case
                    proceedNumberRecords(result[2], limit, subsubtestname)
                else
                    -- Common func return style, use result[2] as target result value
                    proceedCommonRecords(result[2], subsubtestname)
                end
            end
            Log.LogInfo(string.format(common.RECORD_PATTEN, testName, subtestname, tostring(subsubtestname),
                                      tostring(lowerLimit), tostring(upperLimit), result and result[2] or "",
                                      unit or "", common.testResult and 'PASS' or 'FAIL', failMsg))

            if common.testResult then
                Log.LogFlowPass(testName, subtestname, subsubtestname)
            else
                Log.LogFlowFail(testName, subtestname, subsubtestname)
            end

            return table.unpack(ret)
        end
    end
}

return common
