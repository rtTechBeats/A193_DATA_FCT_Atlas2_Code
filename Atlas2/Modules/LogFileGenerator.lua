-------------------------------------------------------------------
----***************************************************************
----   LogFormatGenerator for convert device.log to flow.log and pivot.csv
----   Author: Apple & USISX ATESW Callon, Katherine
----***************************************************************
-------------------------------------------------------------------
local LogFormatConfig = require("LogFormatConfig")

local logFileGenerator = {}

-- @ Pattern
local recordPattern =
    "([%w%/:%.%s]+) category.*%[%%record%%%]%s+%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]%s+lower:%s+([%S%s]+)%s+higher:%s+([%S%s]+)%s+value:%s+([%S%s]+)%s+unit:%s+([%S%s]+)%s+result:%s+([%S%s]+)%s+failMsg:%s([%S%s]+)"
local recordPatternAbnormal =
    "([%w%/:%.%s]+) category.*%[%%record%%%]%s+%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]%s+lower:%s+([%S%s]+)%s+higher:%s+([%S%s]+)%s+value:%s+([%S%s]+)%s+..."
local testStartPattern = "([%w%/:%.%s]+) category.*%[TEST START%]%s?%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]"
local testPassPattern = "([%w%/:%.%s]+) category.*%[TEST PASSED%]%s?%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]"
local testFailPattern = "([%w%/:%.%s]+) category.*%[TEST FAILED%]%s?%[<([%S%s]+)>%s+<([%S%s]+)>%s+<([%S%s]+)>%]"
local fixtureStartPattern =
    "([%w%/:%.%s]+) category.*%[%%fixture cmd%%%]%s+method:%s+([%S%s]+)%s+args:%s+([%S%s]+)%s+timeout:%s+([%S%s]+)"
local fixtureStartPatternAbnormal =
    "([%w%/:%.%s]+) category.*%[%%fixture cmd%%%]%s+method:%s+([%S%s]+)%s+args:%s+([%S%s]+)"
local fixtureFinishPattern = "([%w%/:%.%s]+) category.*%[%%fixture response%%%]%s+([%S%s]+)"
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
    "value", "failMsg"
}
local tempRecord = nil
local accumulatedValueLength = 256


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
    end
end
-- ! @brief Parser info from device.log
-- ! @details parser info by pattern
-- ! @param filePath, source data file
-- ! @returns true/false
local function parserDeviceLog(filePath)
    assert(filePath ~= nil, "Error: file path is null!")
    tempRecord = nil
    local fileHandle = io.open(filePath)
    for line in fileHandle:lines() do
        if dutRespStart == true then
            if (string.find(line, "%[INFO%]") == nil) and (string.find(line, "%[DEBUG%]") == nil) then
                if string.find(line, "was stalled due to overlogging") == nil then
                    local timestamp, command = string.match(line, dutCmdFinishMorePattern)
                    local dutMoreFormatStr = "%s%-" ..
                                                 tostring(
                                                     LogFormatConfig.DUT_RESP_INDENTATION + LogFormatConfig.PREFIX_LEN) ..
                                                 "s %s"
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

        if dutRespStart == false and dutFlowDebug == false and
            (string.find(line, "SMTActionHelper.lua") or string.find(line, "SMTLoggingHelper.lua") or
                string.find(line, "logging.lua")) or tempRecord then
            if string.find(line, "%[%%record%%%]") or tempRecord then
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
                local timestamp, testname, subtestname, subsubtestname = string.match(line, testPassPattern)
                if timestamp ~= nil then
                    local passFormatStr = "%s%-" .. tostring(LogFormatConfig.TEST_RESULT_INDENTATION) .. "s%sPASS"
                    local passStr = string.format(passFormatStr, timestamp, "", LogFormatConfig.TEST_RESULT_PREFIX)
                    flowLog[#flowLog + 1] = passStr
                else
                    print("TEST PASSED abnormal Line:", line)
                end

            elseif string.find(line, "%[TEST FAILED%]") then
                local timestamp, testname, subtestname, subsubtestname = string.match(line, testFailPattern)
                if timestamp ~= nil then
                    local failFormatStr = "%s%-" .. tostring(LogFormatConfig.TEST_RESULT_INDENTATION) .. "s%sFAIL"
                    local failStr = string.format(failFormatStr, timestamp, "", LogFormatConfig.TEST_RESULT_PREFIX)
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
                    local timestamp, method, args = string.match(line, fixtureStartPatternAbnormal)
                    if timestamp ~= nil then
                        local fixStartFormatStr =
                            "%s%-" .. tostring(LogFormatConfig.FIXTURE_CMD_INDENTATION) .. "s%-" ..
                                tostring(LogFormatConfig.PREFIX_LEN) .. "s method: %s, args: %s, %s"
                        local fixStartStr = string.format(fixStartFormatStr, trim(timestamp), "",
                                                          LogFormatConfig.FIXTURE_CMD_PREFIX, trim(method), trim(args),
                                                          LogFormatConfig.FIXTURE_CMD_SUFFIX)
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
        failureSummary:write(table.concat(pivotHeader, ",") .. "\n")
    end
    if csvFile ~= nil then
        csvFile:write(table.concat(pivotHeader, ",") .. "\n")
        -- local deviceName = "slot" .. slotID
        for i = 1, #pivotDict do
            local presentLine = pivotDict[i]
            local duration = "N/A"
            if i > 1 then
                local lastLine = pivotDict[i - 1]
                duration = tostring(timeStrDiff(lastLine.timestamp, presentLine.timestamp))
            else
                duration = tostring(timeStrDiff(flowLog[1], presentLine.timestamp)) -- flowLog[1] is the item start line of 1st item, generated by Common.lua, presentLine.timestamp is the line of record.
            end
            local lineContent = slotID .. "," .. presentLine.testname .. "," .. presentLine.subtestname .. ",\"" ..
                                    presentLine.subsubtestname .. "\"," .. presentLine.unit .. "," .. presentLine.lower ..
                                    "," .. presentLine.higher .. "," .. presentLine.timestamp .. "," .. duration .. "," ..
                                    presentLine.result .. "," .. presentLine.value .. "," .. presentLine.message .. "\n"
            csvFile:write(lineContent)
            if presentLine.result:gsub("%s+", "") ~= "PASS" then
                failureSummary:write(lineContent)
            end
        end
        csvFile:close()
        if failureSummary then
            failureSummary:close()
        end
    else
        print("Error: open pivot file fail!")
        csvFile:close()
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
function logFileGenerator.generateFlowLog(deviceLogPath, slot, flowLogPath, pivotPath, failureSummaryPath)
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

return logFileGenerator

