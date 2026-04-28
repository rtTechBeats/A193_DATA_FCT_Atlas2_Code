-------------------------------------------------------------------
----***************************************************************
----   LogFormatGenerator for convert device.log to flow.log and pivot.csv
----   Author: Apple & USISX ATESW Callon, Katherine
----***************************************************************
-------------------------------------------------------------------
local LogFormatConfig = require("LogFormatConfig")
local pivotFileGenerator = {}
local lcsv = require("lcsv/lcsv")
local max_line_len = 1024

-- @ Pattern
local recordPattern = "([%w%/:%.%s]+) category.*%[%%record%%%]%s+%[<([%S%s]+)>\z
%s+<([%S%s]+)>%s+<([%S%s]+)>%]%s+lower:%s+([%S%s]+)%s+higher:\z
%s+([%S%s]+)%s+value:%s+([%S%s]+)%s+unit:%s+([%S%s]+)%s+\z
result:%s+([%S%s]+)%s+failMsg:%s([%S%s]+)"
local recordPatternAbnormal = "([%d%/:%.%s]+) category.*%[%%record%%%]%s+\z
%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]%s+\z
lower:%s+([%S%s]+)%s+higher:%s+([%S%s]+)%s+value:%s*([%S%s]+)%s*[...]?"
local testStartPattern = "([%w%/:%.%s]+) category.*%[TEST START%]%s?%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]"
local testPassPattern = "([%w%/:%.%s]+) category.*%[TEST PASSED%]%s?%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]"
local testFailPattern = "([%w%/:%.%s]+) category.*%[TEST FAILED%]%s?%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]"
local fixtureStartPattern =
    "([%w%/:%.%s]+) category.*%[%%fixture cmd%%%]%s+method:%s+([%S%s]+)%s+args:%s+([%S%s]+)%s+timeout:%s+([%S%s]+)"
local fixtureStartPatternAbnormal =
    "([%w%/:%.%s]+) category.*%[%%fixture cmd%%%]%s+method:%s+([%S%s]+)%s+args:%s+([%S%s]+)"
local fixtureFinishPattern = "([%d%/:%.%s]+) category.*%[%%fixture response%%%]([%S%s]+)"
local fixtureFinishMorePattern = "([%w%/:%.%s]+) category.*%<default%>%s+([%S%s]+)"
local dutCmdStartPattern = "([%w%/:%.%s]+) category.*%[%%%%dut cmd%%%%%]([%S%s]+)"
local dutCmdFinishPattern = "([%w%/:%.%s]+) category.*%[%%%%dut response%%%%%]([%S%s]+)"
local dutCmdFinishMorePattern = "([%w%/:%.%s]+) category.*%<default%>%s+([%S%s]+)"
local flowDebugPattern = "([%w%/:%.%s]+) category.*%[%%%%flow debug%%%%%]%s+([%S%s]+)"
local flowDebugMorePattern = "([%w%/:%.%s]+) category.*%<default%>%s+([%S%s]+)"

local dutRespStart = false
local fixtureRespStart = false
local dutFlowDebug = false

local pivotDict = {}
local flowLog = {}
local pivotHeader = {
    "slot", "testname", "subtestname", "subsubtestname", "unit", "lower", "higher", "timestamp", "duration", "result",
    "value", "failMsg", "thread"
}

local tempRecord = nil
local tempCount = 0
local accumulatedValueLength = 256

--Notes: max line count to search in device log
local maxCountToSearch = 30

local LAST_TIMESTAMP_WITH_NO_THREAD = "Last_Timestamp_With_No_Thread"
local GROUP_LAST_TIMESTAMP = "Group_Last_Timestamp"
local THREAD_LAST_TIMESTAMP = "Thread_Last_Timestamp_"
local MINIMUM_THREAD_INDEX = "Minimum_Thread_Index"
local PARSER_SEPRATOR = "============ Parse Device Log Separator ==========="

-- ! @brief calculate the different value with to time string
-- ! @details change the time string format and get the differnt value.
-- ! @param preTimeStr, postTimeStr
-- ! @return different time value
local function timeStrDiff(preTimeStr, postTimeStr)
    assert(preTimeStr ~= nil, string.format("parameter1 %s is Null!", preTimeStr))
    assert(postTimeStr ~= nil, string.format("parameter2 %s is Null!", postTimeStr))

    local _, _, Y, M, D, h, m, s, ms = string.find(preTimeStr, "(%d+)/(%d+)/(%d+)%s*(%d+):(%d+):(%d+)%.(%d+)")
    local time1, ms1 = os.time({year = Y, month = M, day = D, hour = h, min = m, sec = s}), tonumber(ms)
    local _, _, Y2, M2, D2, h2, m2, s2, mse2 = string.find(postTimeStr, "(%d+)/(%d+)/(%d+)%s*(%d+):(%d+):(%d+)%.(%d+)")
    local time2, ms2 = os.time({year = Y2, month = M2, day = D2, hour = h2, min = m2, sec = s2}), tonumber(mse2)

    return (time2 - time1 + (ms2 - ms1) / 1000000)
end

-- ! @brief change "," or ";" with " "
-- ! @param valueStr
-- ! @return trimed string, value length 256
local function pivotTrim(valueStr)
    local processed = string.gsub(valueStr or "", '[,;]', ' ')

      if #processed > accumulatedValueLength then
          return string.sub(processed, 1, accumulatedValueLength) .. " ..."
      else
          return processed
      end
end

-- ！remove extra spaces at begin and end
-- ！@param str: input string
-- ！@return string after trimmed
-- ！e.g. trim(" a == b  ") => "a == b"
local function trim(str)
    if not str then
        return nil
    else
        return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
    end
end

-- ！this function to judgement and filter the special string from plugin
-- ！@param str: input string
-- ！@return true/false
local function specialLogStringFilter(line)
    if LogFormatConfig.specialFilterFlg == true then
        if string.find(line, LogFormatConfig.specialFilterPattern) == nil then
            return true
        else
            return false
        end
    else
        return true
    end
end


local function processAccumulatedRecord()
    if tempRecord then
        local recordFormatStr = "%s%-"..tostring(LogFormatConfig.RECORD_INDENTATION).."s%-"..
            tostring(LogFormatConfig.PREFIX_LEN).."s %-36s lower: %-5s higher: %-5s value: %-10s unit: %-5s msg: %s%s"

        local recordName = LogFormatConfig.FLOW_LOG_RECORD_NAME_FORMAT and 
            string.format(LogFormatConfig.FLOW_LOG_RECORD_NAME_FORMAT, 
                tempRecord.testname, 
                tempRecord.subtestname,
                tempRecord.subsubtestname) 
            or tempRecord.subsubtestname

        local recordStr = string.format(recordFormatStr,
            trim(tempRecord.timestamp), "",
            LogFormatConfig.RECORD_PREFIX,
            recordName,
            trim(tempRecord.lower),
            trim(tempRecord.higher),
            trim(tempRecord.accumulatedValue),
            trim(tempRecord.unit or ""),
            trim(tempRecord.failMsg or ""),
            LogFormatConfig.RECORD_SUFFIX)

        flowLog[#flowLog + 1] = recordStr

        pivotDict[#pivotDict + 1] = {
            timestamp = tempRecord.timestamp,
            testname = tempRecord.testname,
            subtestname = tempRecord.subtestname,
            subsubtestname = tempRecord.subsubtestname,
            lower = tempRecord.lower,
            higher = tempRecord.higher,
            value = pivotTrim(tempRecord.accumulatedValue),
            unit = tempRecord.unit or "",
            result = tempRecord.result or "N/A",
            message = pivotTrim(tempRecord.failMsg or "")
        }
        tempRecord = nil
        tempCount = 0
    end
end

-- ! @brief Parser info from device.log
-- ! @details parser info by pattern
-- ! @param filePath, source data file
-- ! @returns true/false
local function parserDeviceLog(filePath)
    assert(filePath ~= nil, "Error: file path is null!")
    tempRecord = nil
    tempCount = 0
    print(PARSER_SEPRATOR)
    local fileHandle = io.open(filePath)
    for line in fileHandle:lines() do
        if string.find(line, PARSER_SEPRATOR) then
            break
        end
        if dutRespStart == true then
            if (string.find(line, "%[INFO%]") == nil) and (string.find(line, "%[DEBUG%]") == nil) then
                if string.find(line, "was stalled due to overlogging") == nil then
                    local timestamp, command = string.match(line, dutCmdFinishMorePattern)
                    local logFormatPattern = tostring(LogFormatConfig.DUT_RESP_INDENTATION + LogFormatConfig.PREFIX_LEN)
                    local dutMoreFormatStr = "%s%-" .. logFormatPattern .. "s %s"
                    local dutMoreStr = string.format(dutMoreFormatStr, trim(timestamp), "", trim(command))
                    flowLog[#flowLog + 1] = dutMoreStr
                    goto continue
                end
            else
                dutRespStart = false
            end
        end

        if fixtureRespStart then
            if (string.find(line, "%[INFO%]") == nil) and (string.find(line, "%[DEBUG%]") == nil) then
                if string.find(line, "was stalled due to overlogging") == nil then
                    local timestamp, content = string.match(line, fixtureFinishMorePattern)
                    local fixtureMoreFormatStr = "%s%-" ..
                                                     tostring(
                                                         LogFormatConfig.FIXTURE_RESP_INDENTATION +
                                                             LogFormatConfig.PREFIX_LEN) .. "s %s"
                    local fixtureMoreStr = string.format(fixtureMoreFormatStr, trim(timestamp), "", trim(content))
                    flowLog[#flowLog + 1] = fixtureMoreStr
                    goto continue
                end
            else
                fixtureRespStart = false
            end
        end

        if dutFlowDebug == true then
            if (string.find(line, "%[INFO%]") == nil) and (string.find(line, "%[DEBUG%]") == nil) and
                specialLogStringFilter(line) then
                if string.find(line, "was stalled due to overlogging") == nil then
                    local timestamp, command = string.match(line, flowDebugMorePattern)
                    local flowDebugMoreFormatStr = "%s%-" ..
                                                       tostring(
                                                           LogFormatConfig.FLOW_DEBUG_INDENTATION +
                                                               LogFormatConfig.PREFIX_LEN) .. "s %s"
                    local flowDebugMoreStr = string.format(flowDebugMoreFormatStr, trim(timestamp), "", trim(command))
                    flowLog[#flowLog + 1] = flowDebugMoreStr
                    goto continue
                end
            else
                dutFlowDebug = false
            end
        end

        -- if dutRespStart == false and dutFlowDebug == false and string.find(line, "SMTLoggingHelper.lua") then
        if dutRespStart == false and dutFlowDebug == false and
            (string.find(line, "SMTActionHelper.lua") or string.find(line, "SMTLoggingHelper.lua") or
                string.find(line, "logging.lua")) or (tempRecord and tempCount < maxCountToSearch) then
            if string.find(line, "%[%%record%%%]") or (tempRecord and tempCount < maxCountToSearch) then
                local timestamp, testname, subtestname, subsubtestname, lower, higher, value, unit, result, message =
                    string.match(line, recordPattern)
                if timestamp ~= nil then
                    local oneLineTable = {
                        timestamp = timestamp,
                        testname = testname,
                        subtestname = subtestname,
                        subsubtestname = subsubtestname,
                        lower = lower,
                        higher = higher,
                        value = pivotTrim(value),
                        unit = unit,
                        result = result,
                        message = pivotTrim(message)
                    }
                    pivotDict[#pivotDict + 1] = oneLineTable

                    local recordFormatStr = "%s%-" .. tostring(LogFormatConfig.RECORD_INDENTATION) .. "s%-" ..
                                                tostring(LogFormatConfig.PREFIX_LEN) ..
                                                "s %-36s lower: %-5s higher: %-5s value: %-10s unit: %-5s msg: %s%s"
                    local recordName
                    if LogFormatConfig.FLOW_LOG_RECORD_NAME_FORMAT then
                        recordName = string.format(LogFormatConfig.FLOW_LOG_RECORD_NAME_FORMAT, testname, subtestname,
                                                   subsubtestname)
                    else
                        recordName = subsubtestname
                    end
                    local recordStr = string.format(recordFormatStr, trim(timestamp), "", LogFormatConfig.RECORD_PREFIX,
                                                    recordName, trim(lower), trim(higher), trim(value), trim(unit),
                                                    trim(message), LogFormatConfig.RECORD_SUFFIX)
                    flowLog[#flowLog + 1] = recordStr
                else
                    local ts_abn, tn_abn, sstn_abn, ssstn_abn, l_abn, h_abn, v_abn = string.match(line, recordPatternAbnormal)

                    if ts_abn then
                        local content = string.match(line, "<default>(%s*.*)")
                        -- max_line_len is 1024
                        if #line >= max_line_len and string.sub(content, -3) == "..." then
                            -- Since the line itself is an ultra-long log, 
                            -- it is sufficient to print only the first 128 chars to locate the position of the abnormal log.
                            print("Log line exceeds max length: " .. max_line_len .." => "..line:sub(1, 128) .. "...")
                        else
                            tempRecord = {
                                timestamp = ts_abn,
                                testname = tn_abn,
                                subtestname = sstn_abn,
                                subsubtestname = ssstn_abn,
                                lower = l_abn,
                                higher = h_abn,
                                accumulatedValue = trim(v_abn),
                                unit = nil,
                                result = nil,
                                failMsg = nil
                            }
                            tempCount = tempCount + 1
                        end
                    elseif tempRecord then
                        local preUnit, u, r, msg = string.match(
                            line,
                            "<default>%s*(.-)%s*unit:%s*([%S]*)%s*result:%s*([%S]*)%s*failMsg:%s*(.*)"
                        )
                        if preUnit then
                            tempRecord.accumulatedValue = tempRecord.accumulatedValue .. " " .. trim(preUnit)
                            tempRecord.unit = u
                            tempRecord.result = r
                            tempRecord.failMsg = msg
                            processAccumulatedRecord()
                        else
                            local content = string.match(line, "<default>%s*(.*)")
                            if content then
                                content = trim(content)
                                if content ~= "" then
                                    tempRecord.accumulatedValue = tempRecord.accumulatedValue .. " " .. content
                                    tempRecord.accumulatedValue = trim(tempRecord.accumulatedValue)
                                end
                            end
                            tempCount = tempCount + 1
                        end
                    end
                end

            elseif string.find(line, "%[TEST START%]") then
                local timestamp, testname, subtestname, subsubtestname = string.match(line, testStartPattern)
                if timestamp ~= nil then
                    local startFormatStr = "%s%s%-" .. tostring(LogFormatConfig.TEST_START_INDENTATION) ..
                                               "s%s%s%s%s%s%s"
                    local startStr = string.format(startFormatStr, LogFormatConfig.TEST_SEPARATOR, timestamp, "",
                                                   LogFormatConfig.TEST_NAME_PREFIX, testname,
                                                   LogFormatConfig.SUBTEST_NAME_CONNECTOR, subtestname,
                                                   LogFormatConfig.SUBSUBTEST_NAME_CONNECTOR, subsubtestname)
                    flowLog[#flowLog + 1] = startStr
                else
                    print("TEST START abnormal Line:", line)
                end

            elseif string.find(line, "%[TEST PASSED%]") then
                local testPassTimestamp, _, _, _ = string.match(line, testPassPattern)
                if testPassTimestamp ~= nil then
                    local passFormatStr = "%s%-" .. tostring(LogFormatConfig.TEST_RESULT_INDENTATION) .. "s%sPASS"
                    local passStr = string.format(passFormatStr, testPassTimestamp, "",
                                                  LogFormatConfig.TEST_RESULT_PREFIX)
                    flowLog[#flowLog + 1] = passStr
                else
                    print("TEST PASSED abnormal Line:", line)
                end

            elseif string.find(line, "%[TEST FAILED%]") then
                local testFailTimestamp, _, _, _ = string.match(line, testFailPattern)
                if testFailTimestamp ~= nil then
                    local failFormatStr = "%s%-" .. tostring(LogFormatConfig.TEST_RESULT_INDENTATION) .. "s%sFAIL"
                    local failStr = string.format(failFormatStr, testFailTimestamp, "",
                                                  LogFormatConfig.TEST_RESULT_PREFIX)
                    flowLog[#flowLog + 1] = failStr
                else
                    print("TEST FAILED abnormal Line:", line)
                end

            elseif string.find(line, "%[%%fixture cmd%%%]") then
                local timestamp, method, args, timeout = string.match(line, fixtureStartPattern)
                if timestamp ~= nil then
                    local fixStartFormatStr = "%s%-" .. tostring(LogFormatConfig.FIXTURE_CMD_INDENTATION) .. "s%-" ..
                                                  tostring(LogFormatConfig.PREFIX_LEN) ..
                                                  "s method: %s, args: %s, timeout: %s%s"
                    local fixStartStr = string.format(fixStartFormatStr, trim(timestamp), "",
                                                      LogFormatConfig.FIXTURE_CMD_PREFIX, trim(method), trim(args),
                                                      trim(timeout), LogFormatConfig.FIXTURE_CMD_SUFFIX)
                    flowLog[#flowLog + 1] = fixStartStr
                else
                    local testStartTimestamp, testStartMethod, testStartArgs = string.match(line,
                                                                                            fixtureStartPatternAbnormal)
                    if testStartTimestamp ~= nil then
                        local fixStartFormatStr =
                            "%s%-" .. tostring(LogFormatConfig.FIXTURE_CMD_INDENTATION) .. "s%-" ..
                                tostring(LogFormatConfig.PREFIX_LEN) .. "s method: %s, args: %s, %s"
                        local fixStartStr = string.format(fixStartFormatStr, trim(testStartTimestamp), "",
                                                          LogFormatConfig.FIXTURE_CMD_PREFIX, trim(testStartMethod),
                                                          trim(testStartArgs), LogFormatConfig.FIXTURE_CMD_SUFFIX)
                        flowLog[#flowLog + 1] = fixStartStr
                    else
                        print("fixture cmd abnormal Line:", line)
                    end
                end

            elseif string.find(line, "%[%%fixture response%%%]") then
                fixtureRespStart = true
                local timestamp, response = string.match(line, fixtureFinishPattern)
                if timestamp ~= nil then
                    local fixFinishFormatStr = "%s%-" .. tostring(LogFormatConfig.FIXTURE_RESP_INDENTATION) .. "s%-" ..
                                                   tostring(LogFormatConfig.PREFIX_LEN) .. "s %s%s"
                    local fixFinishStr = string.format(fixFinishFormatStr, trim(timestamp), "",
                                                       LogFormatConfig.FIXTURE_RESP_PREFIX, trim(response),
                                                       LogFormatConfig.FIXTURE_RESP_SUFFIX)
                    flowLog[#flowLog + 1] = fixFinishStr
                else
                    print("fixture response abnormal Line:", line)
                end

            elseif string.find(line, "%[%%%%dut cmd%%%%%]") then
                local timestamp, command = string.match(line, dutCmdStartPattern)
                if timestamp ~= nil then
                    local dutStartFormatStr = "%s%-" .. tostring(LogFormatConfig.DUT_CMD_INDENTATION) .. "s%-" ..
                                                  tostring(LogFormatConfig.PREFIX_LEN) .. "s %s%s"
                    local dutStartStr = string.format(dutStartFormatStr, trim(timestamp), "",
                                                      LogFormatConfig.DUT_CMD_PREFIX, trim(command),
                                                      LogFormatConfig.DUT_CMD_SUFFIX)
                    flowLog[#flowLog + 1] = dutStartStr
                else
                    print("dut cmd abnormal Line:", line)
                end

            elseif string.find(line, "%[%%%%dut response%%%%%]") then
                dutRespStart = true
                local timestamp, response = string.match(line, dutCmdFinishPattern)
                if timestamp ~= nil then
                    local dutFinishFormatStr = "%s%-" .. tostring(LogFormatConfig.DUT_RESP_INDENTATION) .. "s%-" ..
                                                   tostring(LogFormatConfig.PREFIX_LEN) .. "s %s%s"
                    local dutFinishStr = string.format(dutFinishFormatStr, trim(timestamp), "",
                                                       LogFormatConfig.DUT_RESP_PREFIX, trim(response),
                                                       LogFormatConfig.DUT_RESP_SUFFIX)
                    flowLog[#flowLog + 1] = dutFinishStr
                else
                    print("dut response abnormal Line:", line)
                end

            elseif string.find(line, "%s+%[%%%%flow debug%%%%%]%s+") then
                dutFlowDebug = true
                local timestamp, response = string.match(line, flowDebugPattern)
                if timestamp ~= nil then
                    local flowDebugFormatStr = "%s%-" .. tostring(LogFormatConfig.FLOW_DEBUG_INDENTATION) .. "s%-" ..
                                                   tostring(LogFormatConfig.PREFIX_LEN) .. "s %s%s"
                    local flowDebugStr = string.format(flowDebugFormatStr, trim(timestamp), "",
                                                       LogFormatConfig.FLOW_DEBUG_PREFIX, trim(response),
                                                       LogFormatConfig.FLOW_DEBUG_SUFFIX)
                    flowLog[#flowLog + 1] = flowDebugStr
                else
                    print("flow debug abnormal Line:", line)
                end
            end
        end
        ::continue::
    end
    fileHandle:close()

    if flowLog ~= nil and pivotDict ~= nil then
        return true
    else
        return false
    end

end

local function getThreadGroupsFromMainTable()
    -- load main csv table
    local mainTablePath = Atlas.assetsPath .. "/Coverage/MainTable.csv"
    local file = lcsv.open(mainTablePath, "r")
    local csvLines = lcsv.toLines(file:read('*a'))
    file:close()
    local csvContent = lcsv.parseAll(csvLines, true)

    local threadGroupsInMainTable = {}
    local threadGroup = {}

    local groupThreadPattern = "group%d+_thread%d+"
    local groupPattern = "group(%d+)"

    for _, v in pairs(csvContent) do
        -- print(k, v)
        local tech = v.Technology
        local testParams = v.TestParameters
        local testName = v.Coverage

        -- skip group separator lines and teardown lines
        if (tech == "-" and testParams == "-" and testName == "-") or
            (tech == "=" and testParams == "-" and testName == "=") then
            goto continue
        end

        local notes = v.Notes

        if notes then
            -- print(notes)
            local match = string.find(notes, groupThreadPattern)
            if not match then
                -- no group thread in notes, set the last dmns group index
                if next(threadGroup) then
                    local lastGroupIndex = math.maxinteger
                    for _, value in pairs(threadGroup) do
                        -- print("value: " .. value)
                        local groupStr = string.match(value, groupPattern)
                        local groupIndex = tonumber(groupStr) or 1
                        if groupIndex < lastGroupIndex then
                            lastGroupIndex = groupIndex
                        end
                    end
                    threadGroup[MINIMUM_THREAD_INDEX] = lastGroupIndex
                    table.insert(threadGroupsInMainTable, threadGroup)
                end
                threadGroup = {}
            else
                -- To ensure the key name is unique one
                local groupThreadStr = string.sub(notes, match)
                local compositeKey = tech .. "|" .. testName
                threadGroup[compositeKey] = groupThreadStr
            end
        end
        ::continue::
    end
    return threadGroupsInMainTable
end

-- ! @brief Generate pivot log by slot
-- ! @details write record message into pivot.csv
-- ! @param pivotFilePath
-- ! @returns N/A
local function pivotExport(pivotFilePath, slotID, failureSummaryPath)
    assert(pivotFilePath ~= nil, "Error: pivot.csv Path is null!")
    local csvFile = io.open(pivotFilePath, "a+")
    local failureSummary
    if failureSummaryPath then
        failureSummary = io.open(failureSummaryPath, "a+")
        if failureSummary then
            failureSummary:write(table.concat(pivotHeader, ",") .. "\n")
        else
            print("Error: fail to open file: " .. failureSummaryPath)
        end
    end

    local timestampMap = {}
    local lastTimestamp
    local threadGroupsInMainTable = getThreadGroupsFromMainTable()

    local g_pattern = "group(%d+)"

    if csvFile ~= nil then
        csvFile:write(table.concat(pivotHeader, ",") .. "\n")
        -- local deviceName = "slot" .. slotID
        for i = 1, #pivotDict do
            local presentLine = pivotDict[i]
            local group_thread_info = ""

            if #threadGroupsInMainTable > 0 then
                local isHasThread = false
                -- local minimumThreadIndex = 0
                local lastGroupIndex = 0

                local testName = presentLine.testname
                local keyName = presentLine.subtestname
                -- Using the unique one key name
                local compositeKey = testName .. "|" .. keyName
                for index = 1, #threadGroupsInMainTable do
                    local threadGroup = threadGroupsInMainTable[index]
                    if threadGroup[compositeKey] then
                        group_thread_info = threadGroup[compositeKey]
                        lastGroupIndex = threadGroup[MINIMUM_THREAD_INDEX]
                        isHasThread = true
                        break
                    end
                end

                if isHasThread then
                    -- local threadIndex = tonumber(string.sub(thread, 1, -2)) or 1
                    local groupStr = string.match(group_thread_info, g_pattern)
                    local groupIndex = tonumber(groupStr)
                    if not groupIndex then
                        error("Invalid group index, cannot convert to number: " .. groupStr)
                    end
                    if timestampMap[group_thread_info] == nil then
                        if groupIndex > lastGroupIndex then
                            local previousGroupIndex = groupIndex - 1
                            local previousGroupLastTimestamp = THREAD_LAST_TIMESTAMP .. previousGroupIndex
                            lastTimestamp = timestampMap[previousGroupLastTimestamp]
                        else
                            lastTimestamp = timestampMap[LAST_TIMESTAMP_WITH_NO_THREAD]
                        end
                    else
                        lastTimestamp = timestampMap[group_thread_info]
                    end

                    timestampMap[group_thread_info] = presentLine.timestamp
                    timestampMap[GROUP_LAST_TIMESTAMP] = presentLine.timestamp
                    local threadLastTimestamp = THREAD_LAST_TIMESTAMP .. groupIndex
                    timestampMap[threadLastTimestamp] = presentLine.timestamp
                else
                    if not timestampMap[GROUP_LAST_TIMESTAMP] then
                        lastTimestamp = timestampMap[LAST_TIMESTAMP_WITH_NO_THREAD]
                    else
                        lastTimestamp = timestampMap[GROUP_LAST_TIMESTAMP]
                        timestampMap[GROUP_LAST_TIMESTAMP] = nil
                    end
                    timestampMap[LAST_TIMESTAMP_WITH_NO_THREAD] = presentLine.timestamp
                end
            else
                lastTimestamp = timestampMap[LAST_TIMESTAMP_WITH_NO_THREAD]
                timestampMap[LAST_TIMESTAMP_WITH_NO_THREAD] = presentLine.timestamp
            end

            local duration
            if i > 1 then
                duration = tostring(timeStrDiff(lastTimestamp, presentLine.timestamp))
            else
                --[[ flowLog[1] is the item start line of 1st item, generated by Common.lua,
                presentLine.timestamp is the line of record. --]]
                duration = tostring(timeStrDiff(flowLog[1], presentLine.timestamp))
            end

            if duration == "" then
                duration = "N/A"
            end

            local content = slotID .. "," .. presentLine.testname .. "," .. presentLine.subtestname .. ",\"" ..
                                presentLine.subsubtestname .. "\"," .. presentLine.unit .. "," .. presentLine.lower ..
                                "," .. presentLine.higher .. "," .. presentLine.timestamp .. "," .. duration .. "," ..
                                presentLine.result .. "," .. presentLine.value .. "," .. presentLine.message .. "," ..
                                group_thread_info .. "\n"
            csvFile:write(content)
            if (presentLine.result:gsub("%s+", "") ~= "PASS") and failureSummary then
                failureSummary:write(content)
            end
        end
        csvFile:close()
    else
        print("Error: open pivot file fail!")
    end
    if failureSummary then
        failureSummary:close()
    end
end

-- ! @brief Generate flow log by slot
-- ! @details write the content into flow.log
-- ! @param flowLogFilePath
-- ! @returns N/A
local function flowLogExport(flowLogFilePath)
    assert(flowLogFilePath ~= nil, "Error: flow.log Path is null!")

    local logFile = io.open(flowLogFilePath, "a+")
    if logFile ~= nil then
        for i = 1, #flowLog do
            local string2filterDetected = false
            if LogFormatConfig.LINE_TO_FILTER then
                for _, pattern in ipairs(LogFormatConfig.LINE_TO_FILTER) do
                    if string.find(flowLog[i], pattern) then
                        string2filterDetected = true
                    end
                end
            end
            if string2filterDetected == false then
                logFile:write(flowLog[i] .. "\n")
            end
        end
        logFile:close()
    else
        print("Error: open pivot file fail!")
        logFile:close()
    end
end

-- ! @brief generate a flow.log and pivot.csv, and this function call by CSV
-- ! @details get decice.log file path and generate the flow.log, pivot.csv
-- ! @param N/A
-- ! @returns pass: pass or fail
function pivotFileGenerator.generateFlowLog(deviceLogPath, slot, flowLogPath, pivotPath, failureSummaryPath)
    -- @ get file path
    -- local systemLogPath = string.gsub(userLogPath,"user","system")
    assert(deviceLogPath ~= nil, "Error: system logpath is null!")
    -- local deviceLogPath = systemLogPath .. "/device.log"
    -- local flowLogPath = systemLogPath .. "/flow.log"
    -- local pivotPath = systemLogPath .. "/pivot.csv"
    flowLog = {}
    pivotDict = {}

    local result = true
    local bRet, ret = xpcall(parserDeviceLog, debug.traceback, deviceLogPath)
    if bRet and ret then
        flowLogExport(flowLogPath)
        pivotExport(pivotPath, slot, failureSummaryPath)
    else
        result = false
        error("Error: parser device.log fail, need to check!")
    end

    return result
end

-- ! @brief filter records.csv to generate failureRecords.csv
-- ! @param device device instance
-- ! @returns N/A
function pivotFileGenerator.generateFailureRecordsCsv(device)
    local userLogPath = Group.getDeviceUserDirectory(device)
    local systemLogPath = string.gsub(userLogPath, "user", "system")
    local recordsCsvPath = systemLogPath .. "/records.csv"
    local failureRecordsCsvPath = userLogPath .. "/failureRecords.csv"

    local file = lcsv.open(recordsCsvPath, "r")
    local csvLines = lcsv.toLines(file:read('*a'))
    file:close()
    local testRecords = lcsv.parseAll(csvLines, true)
    local failureRecordsCsvFile = io.open(failureRecordsCsvPath, "a+")
    if not failureRecordsCsvFile then
        print("Error: open failure records csv file fail!")
        failureRecordsCsvFile:close()
        return
    end

    failureRecordsCsvFile:write(table.concat(pivotHeader, ",") .. "\n")
    local content
    for _, record in ipairs(testRecords) do
        local result = record["status"]
        if result == "FAIL" then
            content = "" .. "," .. record.testName .. "," .. record.subTestName .. ",\"" .. record.subSubTestName ..
                          "\"," .. record.measurementUnits .. "," .. record.lowerLimit .. "," .. record.upperLimit ..
                          "," .. "" .. "," .. "" .. "," .. record.status .. "," .. record.measurementValue .. "," ..
                          record.failureMessage .. "," .. "" .. "\n"
            failureRecordsCsvFile:write(content)
        end
    end

    failureRecordsCsvFile:close()
end

return pivotFileGenerator

