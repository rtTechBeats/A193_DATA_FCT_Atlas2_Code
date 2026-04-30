local DutCmdCoreUsbUart = {}
local parser = require("INVT/Modules/ParserCore")
local comFunc = require("Common/Utilities")
local Log = require("Common/logging")
local time = require("Time")
local record = require("Common/record")
local PluginsLoader = require("INVT/Modules/PluginsLoader")
local runShellCmd = PluginsLoader.getPlugin("RunShellCommand")
local constants = require("INVT/constants")

DutCmdCoreUsbUart.CMD_ONLY = true
DutCmdCoreUsbUart.SEND_AS_DATA = true
local PARAMETRIC_MAX_LEN = 2 ^ 256

-- !@brief send command to device and ingore response
-- !@param command command string to send to device
-- !@param timeout time in microsecond to wait for test done
-- !@param channel support KIS/UART/a/b, a for DMNS KIS, b for DMNS SecondaryCore
-- ! @return true if successful, false if failed
function DutCmdCoreUsbUart.cmdOnlyCore(command, timeout, channel)

    if not command then
        Log.LogError("command is nil, please check the test parameter")
        return false
    end

    local status, result = xpcall(DutCmdCoreUsbUart.sendCmd, debug.traceback, command, timeout, not DutCmdCoreUsbUart.SEND_AS_DATA,
                                  DutCmdCoreUsbUart.CMD_ONLY)
    if not status then
        Log.LogError(result)
        return false
    end

    return true
end

function DutCmdCoreUsbUart.getDutComm(timeout)
    
    local dutChannel = PluginsLoader.getPlugin("USBUart")
    local status, response = xpcall(dutChannel.open, debug.traceback, 0.5)

    if dutChannel.isOpened() ~= 1 then
        local slotID = "slot"..string.match(Device.identifier, "S=%a*(%d+)")
        local dutUSBUrl = constants.StationURL[slotID].dutUSBCURL
        local dutUSBDev = dutUSBUrl:match("(/dev/cu.*)?")
        local startTime = time.time()
        while time.time() - startTime <= timeout do
            Log.LogFlowDebug("[Send shell command]: ls /dev/cu.*")
            local retVal = runShellCmd.run("ls /dev/cu.*", 3000).output
            Log.LogFlowDebug("[shell Receive] "..retVal)
            if retVal:match(dutUSBDev) then 
                Log.LogFlowDebug("Found Device...")
                break
            end
            time.sleep(1)
        end

        local status, response = xpcall(dutChannel.open, debug.traceback, 1)
        if not status then
            Log.LogFlowDebug("Open DUT comm Fail: ", response)
        end
    end
    return dutChannel
end

-- ! @brief Dut Cmd module internal function
-- ! @brief read target detectString in uart buffer
-- ! @param target detectString
-- ! @param timeout time in second to wait for reading buffer
-- !@param channel support KIS/UART/a/b, a for DMNS KIS, b for DMNS SecondaryCore
-- ! @return true if detect successful, false if failed
function DutCmdCoreUsbUart.detectCore(targetString, timeout, testName, subsubtest)
    local extraName = testName .. "_" .. subsubtest

    if not targetString or targetString == "" then
        Log.LogError("No valid string to detect")
        return false
    end

    local dutChannel = DutCmdCoreUsbUart.getDutComm(20)
    local status = nil
    local response = nil
    
    if dutChannel.isOpened() == 1 then
        Log.LogFlowDebug("Start clear boot buffer...")
        dutChannel.setDelimiter(nil)
        for i = 1, 15 do
            time.sleep(0.5)
            dutChannel.setTimeoutIsException(0)
            status, response = pcall(dutChannel.read, timeout)
            dutChannel.setTimeoutIsException(1)
            Log.LogFlowDebug("Data buffer:", response)
            if response == '' and i > 2 then
                break
            end
        end
    else
        Log.LogError("Something error, channel should not be closed at the moment!")
        return false
    end

    dutChannel.setDelimiter(targetString)
    status, response = xpcall(dutChannel.send, debug.traceback, "\n", 3)
    dutChannel.setDelimiter("[m")
    -- status, response = xpcall(dutChannel.send, debug.traceback, "detect diags\n", 3)
    if not status then 
        Log.LogError("Detect Diags Failed: " .. response)
        return false
    else
        if not response:match(targetString) then
            Log.LogError("Detect Diags Failed: " .. response)
            return false
        else
            Log.LogFlowDebug("Detect Diags Sucess: " .. response)
        end
    end

    return true
end

function DutCmdCoreUsbUart.readBuffer(timeout, testName, subsubtest)
    local extraName = testName .. "_" .. subsubtest
    local dutChannel = DutCmdCoreUsbUart.getDutComm(3)
    local status = nil
    local response = nil
    local boot_buffer = ""

    if dutChannel.isOpened() == 1 then
        Log.LogFlowDebug("Start read boot buffer...")
        for i = 1, 15 do
            dutChannel.setTimeoutIsException(0)
            status, response = pcall(dutChannel.read, timeout)
            dutChannel.setTimeoutIsException(1)
            Log.LogFlowDebug("Data buffer:", response)
            time.sleep(1)
            if response == '' and i > 5 then
                break
            end
            boot_buffer = boot_buffer .. response
        end
    else
        Log.LogError("Something error, channel should not be closed at the moment!")
        return false
    end

    return boot_buffer
end

local function clearBufferBeforeSend(timeout)
    local event = "cps8200_evt"
    local dut = PluginsLoader.getPlugin("USBUart")
    
    for i = 1, 3 do
        -- status, response = pcall(dut.read, 0.1, "[m")
        dut.setTimeoutIsException(0)
        local status, response = pcall(dut.read, timeout)
        Log.LogInfo("Clear Buffer before send:", response)
        time.sleep(0.05)

        if response and response:match(event) then
            local count = 0
            while response ~= '' and count <= 20 do
                count = count + 1
                status, response = pcall(dut.read, timeout)
                Log.LogInfo("Clear Buffer before send:", response)
                time.sleep(0.05)
            end
        end

        dut.setTimeoutIsException(1)
    end
end


-- !@brief Lua script API
-- !@brief send command to device and capture response
-- !@param command the command string to send to device
-- !@param timeout time in second to wait for action done
-- !@param sendAsData boolean data to define if the command needs to be send in hex mode
-- !@param cmdOnly boolean data to define if skipping reading response
-- !@param channel support KIS/UART/a/b, a for DMNS KIS, b for DMNS SecondaryCore
-- !@param delimiterList support pass one delimiter or delimiterList,{"  exec socstn.cmd", "SEGPE>"}
-- !@return command response string if cmdOnly is false
function DutCmdCoreUsbUart.sendCmd(command, timeout, sendAsData, cmdOnly, disableLogging, delimiterList, hangTimeout)
    if command == nil then
        error("command is nil, please check the test parameter")
    end
    local command = command.."\n"

    local dut = DutCmdCoreUsbUart.getDutComm(3)
    if dut.isOpened() ~= 1 then 
        error("Dut channel closed...")
    end

    if hangTimeout then
        dut.setHangTimeout(tonumber(hangTimeout))
    end

    local cmdReturn
    -- Support for passing multiple delimiters, and tests will pass only when all delimiters are received.
    local sendCmdAndWaitDelimiter = function(sendType, cmd, readType, utilities)
        local cmdResp = ""
        local cmdDuration
        local isFirstDelimiter = true
        local tag = Device.identifier .. "-" .. cmd .. "-" .. tostring(math.random(os.time()))
        -- Convert string starting with ^ to \n
        local processSpecialDelimiter = function(delimiter)
            return string.gsub(delimiter, "^^", "\n")
        end

        if delimiterList and type(delimiterList) == "table" and next(delimiterList) ~= nil then
            Timer.tick(tag)
            for _, delimiter in ipairs(delimiterList) do
                delimiter = processSpecialDelimiter(delimiter)
                if isFirstDelimiter then
                    dut.setDelimiter(delimiter)
                    cmdReturn = dut[sendType](cmd, timeout)
                    cmdDuration = Timer.tock(tag)
                    isFirstDelimiter = false
                else
                    if sendAsData then
                        delimiter = utilities.dataFromHexString(comFunc.str2hex(delimiter))
                    end
                    cmdResp = dut[readType](timeout - cmdDuration, delimiter)
                end
                cmdReturn = cmdReturn .. cmdResp
            end
        else

            if delimiterList and type(delimiterList) == "string" then
                delimiterList = processSpecialDelimiter(delimiterList)
                dut.setDelimiter(delimiterList)
            end
            cmdReturn = dut[sendType](cmd, timeout)
        end
        return cmdReturn
    end

    Log.LogDutCommStart(command)
    if sendAsData == true then
        -- Send cmd and retrieve response as Data, be sure to register Utilities plugin for device first.
        local Utilities = Device.getPlugin("Utilities")
        local cmdData = Utilities.dataFromHexString(comFunc.str2hex(command))
        if cmdOnly then
            cmdReturn = dut.writeData(cmdData)
        else
            local returnData = sendCmdAndWaitDelimiter("sendData", cmdData, "readData", Utilities)
            cmdReturn = comFunc.hex2str(Utilities.dataToHexString(returnData))
        end
    else
        -- Send cmd and retrieve response as String
        Log.LogInfo("sending command now...")

        if cmdOnly then
            cmdReturn = dut.write(command)
            dut.close()
        else
            -- Clear buffer
            -- dutChannel.setDelimiter(nil)
            clearBufferBeforeSend(0.1)
            cmdReturn = sendCmdAndWaitDelimiter("send", command, "read")
            dut.close()
        end
    end
    if not disableLogging then
        Log.LogDutCommFinish(cmdReturn)
    end

    
    return cmdReturn
end

-- This function check if command fail is completely communication related
-- @param expect:expect string to search in uart.log
-- @return true if is communication issue, false if not
local function confirmCommunicationIssue(expect)
    local isCommunicationIssue = false
    -- we check logger file to see if TEST PASS string is there
    local currentCommandingPath = PluginsLoader.getPlugin("USBUart")
    for _, path in ipairs(commhelper.availableCommPaths()) do
        if path ~= currentCommandingPath then
            local log = commhelper.getSMTLogFile(path)
            local f = io.open(log, "r")
            if f then
                local testLog = f:read("a*")
                if string.match(testLog, expect) then
                    Log.LogInfo("Found TEST PASS print, it is not a true failure")
                    isCommunicationIssue = true
                end
                f:close()
            else
                error("No Post log file found at " .. log)
            end
        else
            Log.LogDebug(currentCommandingPath .. " is current commanding path, skip check")
        end
    end
    Log.LogInfo("Check DUT communication issue result: ", isCommunicationIssue)
    return isCommunicationIssue
end

function DutCmdCoreUsbUart.checkDiagsCommunicationCore(needConfirmCommunicationIssue, command, expect, timeout, testName,
                                                subsubtest)
    local cmdDuration, tag
    local dut = PluginsLoader.getPlugin("USBUart")
    local extraName = testName .. "_" .. subsubtest
    if needConfirmCommunicationIssue == "YES" then
        local newCmd = string.gsub(command, "%p", "_")
        tag = Device.identifier .. "-" .. newCmd .. "-" .. tostring(os.clock())
        Timer.tick(tag)
    end

    local disableLogging = constant.DEBUGGING_LOG_DISABLED
    local status, response = xpcall(DutCmdCoreUsbUart.sendCmd, debug.traceback, command, timeout, not DutCmdCoreUsbUart.SEND_AS_DATA,
                                    not DutCmdCoreUsbUart.CMD_ONLY, nil, disableLogging)

    if needConfirmCommunicationIssue == "YES" then
        cmdDuration = Timer.tock(tag)
    end
    if not status then
        if needConfirmCommunicationIssue == "YES" and expect then
            if cmdDuration < timeout then
                time.delay((timeout - cmdDuration) * 1000)
            end
            if confirmCommunicationIssue(expect) then
                local failureMsg = "Communication FAIL: " .. response
                Log.LogError(failureMsg)
                error(failureMsg)
                return false
            end
        end
        local errMsg = "sendCmd failed: " .. tostring(response)
        Log.LogError(errMsg)
        return false
    end

    if expect then
        -- the 4th parameter turns off pattern matching if set to true
        local s, _ = string.find(response, expect, 1, true)
        if s == nil then
            local failureMsg = "expecting string '" .. expect .. "' is not found"
            Log.LogError(failureMsg)
            return false
        end
    end
    return true
end

-- !@brief Send command, parse response with MD Parser
-- !@param command command string to send to device
-- !@param output variable need to parse
-- !@param expect expected string
-- !@param autoRecord whether to support auto-record
-- !@param timeout time in second to wait for test done
-- !@param channel support KIS/UART/a/b, a for DMNS KIS, b for DMNS SecondaryCore
-- !@param delimiterList support pass one delimiter or delimiterList,{"  exec socstn.cmd", "SEGPE>"}
-- !@return result if params output is existed
function DutCmdCoreUsbUart.sendAndParseCommandCore(command, expect, needParse, autoRecord, timeout, testName,
                                            subsubtest, disableLogging, delimiter)
    local extraName = testName .. "_" .. subsubtest
    local delimiterList = delimiter

    -- The delimiterList can be passed in two ways in testPlan
    -- 1. Only one delimiter: "delimiterList" = "]:-)" or "delimiterList" = "[']:-)']"
    -- 2.Multiple delimiters:"delimiterList" = "['^]', ']:-)']"
    if delimiterList and string.match(delimiterList, "^%['.+'%]$") then
        -- delimiterList type is string, need convert to table
        delimiterList = comFunc.splitBySeveralDelimiter(delimiterList, "[,' ")
        -- remove last ]
        table.remove(delimiterList, #delimiterList)
    end

    -- Get DUT response
    local status, response = xpcall(DutCmdCoreUsbUart.sendCmd, debug.traceback, command, timeout, not DutCmdCoreUsbUart.SEND_AS_DATA,
                                    not DutCmdCoreUsbUart.CMD_ONLY, disableLogging, delimiterList)

    if not status then
        local errorMsg = "send command failed: " .. tostring(response)
        error(errorMsg)
    end

    if expect then
        local start, _ = string.find(response, expect, 1, true)
        if start == nil then
            local errorMsg = "expecting string '" .. expect .. "' is not found"
            error(errorMsg)
        end
    end

    -- expected param autoRecord value type is boolean, Schooner treat true/false as variable, use string as WA
    if (needParse and needParse == "TRUE") or autoRecord then
        local parseStatus, parseResult = xpcall(parser.mdParse, debug.traceback, command, response)
        if not parseStatus then
            local errorMsg = "parse command failed: " .. tostring(parseResult)
            error(errorMsg)
        end
        Log.LogInfo("md parse result:" .. comFunc.dump(parseResult))

        if autoRecord then
            for k, v in pairs(parseResult) do
                local subsubtestname = subsubtest and subsubtest .. "_" .. k or k
                local keyResult
                if tonumber(v) and tonumber(v) > PARAMETRIC_MAX_LEN then
                    keyResult = true
                else
                    keyResult = v
                end
                record.createBinaryRecord(keyResult, subsubtest, subsubtestname, v)
            end
        end

        local count = 0
        local key = nil
        for k, v in pairs(parseResult) do
            key = k
            count = count + 1
        end
        if count == 1 then
            parseResult = parseResult[key]
        end

        return parseResult
    else
        return response
    end
end


return DutCmdCoreUsbUart
