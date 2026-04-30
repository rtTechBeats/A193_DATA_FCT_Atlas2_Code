-------------------------------------------------------------------
----***************************************************************
---- DUT Communication Schooner CSV APIs
----***************************************************************
-------------------------------------------------------------------
local DUTCmd = {}

-- local Log = require "Common/logging"
local Log = require("INVT/Modules/SMTLoggingHelper")

local comFunc = require("Common/Utilities")
local unitTool = require ("Common/UnitTool")
-- local DutCmdCore = require("VendorProxy").require("DutCmdCore")
local DutCmdCore = require("INVT/Modules/DutCmdCore")
local DutCmdCoreUsb = require("INVT/Modules/DutCmdCoreUsbUart")
local constant = require("INVT/constants")
local time = require("INVT/Modules/Time")

local DEFAULT_TIMEOUT = 3

local function processCommandInput(input)
    local commandStr = ""
    if type(input) == "table" then
        if input["command"] ~= nil then
            commandStr = input["command"]
        else
            for _, item in pairs(input) do
                commandStr = commandStr .. item
            end
        end
    else
        commandStr = input
    end
    return commandStr
end

-- !@brief load communication channel
-- !@param channel: string type UART or USBC
-- !@return boolean result
function DUTCmd.communicateMux(input)
    local channel = processCommandInput(input)
    local status, response = xpcall(DutCmdCore.commMux, debug.traceback, channel)
    if not status then
        Log.LogError("communicateMux failed,", response)
        return false
    else
        return response
    end
end

-- !@brief Open DUT communicateOpen
-- !@return boolean result
function DUTCmd.open()
    local status, response = xpcall(DutCmdCore.open, debug.traceback)
    if not status then
        Log.LogError("open failed,", response)
        return false
    else
        return response
    end
end

-- !@brief Close DUT communicateOpen
-- !@return boolean result
function DUTCmd.close()
    local status, response = xpcall(DutCmdCore.close, debug.traceback)
    if not status then
        Log.LogError("close failed,", response)
        return false
    else
        return response
    end
end

-- !@brief open DUT communicateOpen
-- !@return boolean result
function DUTCmd.reconnectComm()
    local status, response = xpcall(DutCmdCore.close, debug.traceback)
    if not status then
        Log.LogError("close failed,", response)
        return false
    end
    status, response = xpcall(DutCmdCore.open, debug.traceback)
    if not status then
        Log.LogError("open failed,", response)
        return false
    else
        return response
    end
end

-- !@brief clear data
-- !@param command: string type
-- !@return boolean result
function DUTCmd.clearBuffer(additionalParameters)
    local cycle = additionalParameters.cycle or 3
    local timeout = additionalParameters.timeout or 0.1
    for _ = 1, cycle do
        local _, retVal = xpcall(DutCmdCore.readData, debug.traceback, timeout, nil)
        if retVal == nil or string.find(tostring(retVal), "Timed out") then
            break
        end
    end
    return true
end

-- !@brief set delimiter
-- @param: string type
-- !@return boolean result
function DUTCmd.setDelimiter(additionalParameters)
    local delimiter = additionalParameters.delimiter or ""
    local status, retVal = xpcall(DutCmdCore.setDelimiter, debug.traceback, delimiter)
    if not status then
        Log.LogError("setDelimiter failed,", retVal)
        return false
    end
    return retVal
end

-- !@brief send DUT command
-- !@param command: string type
-- !@return boolean result
function DUTCmd.cmdOnly(params)
    Log.LogFlowDebug("send params: "..comFunc.dump(params))

    local command = params.command
    local timeout = (params or {}).timeout and params.timeout or 1

    local status, retVal = xpcall(DutCmdCore.cmdOnlyCore, debug.traceback, command, timeout)
    if not status then
        Log.LogError("send failed,", retVal)
        return false
    end
    return retVal
end

-- !@brief send DUT command with Uart.write
-- !@param command: hex string
-- !@return boolean result
function DUTCmd.sendData(input)
    local command = processCommandInput(input)
    local status, retVal = xpcall(DutCmdCore.sendData, debug.traceback, command)
    if not status then
        Log.LogError("sendData failed,", retVal)
        return false
    end
    return retVal
end

-- !@brief read DUT response
-- !@param delimiter: string type
-- !@param timeout: number type
-- !@param expectedKeyWord: string type
-- !@return string result
function DUTCmd.readData(additionalParameters)
    local timeout = additionalParameters.timeout or 0.1
    local delimiter = additionalParameters.delimiter
    local expectedKeyWord = additionalParameters.expectedKeyWord

    local status, retVal = xpcall(DutCmdCore.readData, debug.traceback, timeout, delimiter, expectedKeyWord)
    if not status then
        Log.LogError("readData failed,", retVal)
        return false
    end

    return retVal
end

-- !@brief send DUT command and read DUT response
-- !@param command: string type
-- !@param delimiter: string type
-- !@param timeout: number type
-- !@param expectedKeyWord: string type
-- !@param needParser: boolean type, MDParse only catch one value
-- !@return string result
function DUTCmd.sendRead(input, additionalParameters)
    local command = processCommandInput(input)
    local delimiter = additionalParameters.delimiter
    local timeout = additionalParameters.timeout or DEFAULT_TIMEOUT
    local expectedKeyWord = additionalParameters.expectedKeyWord
    local needParser = additionalParameters.needParser

    local status, retVal = xpcall(DutCmdCore.sendRead, debug.traceback, command, timeout, expectedKeyWord,
                                delimiter, needParser)

    if not status then
        Log.LogError("sendRead failed,", retVal)
        return false
    end

    return retVal
end

-- !@brief Schooner CSV API
-- !@brief Send command, parse response with MD Parser and create records
-- !@param Command command string to send to device
-- !@param Timeout time in microsecond to wait for test done
-- ! @return data parsed from MDParser and match with the variable list in Output field
function DUTCmd.diags(params)
    Log.LogFlowDebug("diags params: "..comFunc.dump(params))

    local commandStr = params.command
    local expect = params.expect
    local needParse = params.needParse
    local autoRecord = params.autoRecord
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local delimiter = params.delimiter
    local timeout = (params or {}).timeout and params.timeout or 5
    local inputs = params.inputs
    local limitTable = (params or {}).limitTable
    local unit = (limitTable or {}).unit
    local convertUnit = (params or {}).csvUnit

    if inputs then
        commandStr = string.format(commandStr, inputs)
    end

    local status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, commandStr, expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, constant.DEBUGGING_LOG_DISABLED, delimiter)
    if not status or not response then
        time.sleep(1)
        -- status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "\n", expect, needParse,
        --                         autoRecord, timeout, testName, subsubtest, constant.DEBUGGING_LOG_DISABLED, "[m")
        -- time.sleep(0.5)
        status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, commandStr, expect, needParse,
                                autoRecord, timeout, testName, subsubtest, constant.DEBUGGING_LOG_DISABLED, delimiter)
    end

    if not status or not response then
        Log.LogError("sendAndParseCommand failed,", response)
        return false
    end


    -- Convert unit if necessary
    if convertUnit and convertUnit ~= "" and unit and unit ~= "" then
        local convertStatus, convertedValue = xpcall(unitTool.convertUnit, debug.traceback, response, convertUnit, unit)
        if not convertStatus then
            Log.LogFlowDebug("Failed to convert unit from " .. convertUnit .. " to " .. unit)
            error("Failed to convert unit from " .. convertUnit .. " to " .. unit)
        end
        response = convertedValue
    end
    return response
end

-- !@brief Schooner CSV API
-- !@brief Send command, parse response with MD Parser and create records
-- !@param Command command string to send to device
-- !@param Timeout time in microsecond to wait for test done
-- ! @return data parsed from MDParser and match with the variable list in Output field
function DUTCmd.diagsUsb(params)
    Log.LogFlowDebug("diags params: "..comFunc.dump(params))

    local commandStr = params.command
    local expect = params.expect
    local needParse = params.needParse
    local autoRecord = params.autoRecord
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local delimiter = params.delimiter
    local attributeKey = params.attributeKey
    local timeout = (params or {}).timeout and params.timeout or 5
    local inputs = params.inputs
    local limitTable = (params or {}).limitTable
    local unit = (limitTable or {}).unit
    local convertUnit = (params or {}).csvUnit

    if inputs then
        commandStr = string.format(commandStr, inputs)
    end

    local status, response = xpcall(DutCmdCoreUsb.sendAndParseCommandCore, debug.traceback, commandStr, expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, constant.DEBUGGING_LOG_DISABLED, delimiter)
    if not status or not response then
        time.sleep(1)
        -- status, response = xpcall(DutCmdCoreUsb.sendAndParseCommandCore, debug.traceback, "\n", expect, needParse,
        --                         autoRecord, timeout, testName, subsubtest, constant.DEBUGGING_LOG_DISABLED, "[m")
        -- time.sleep(0.5)
        status, response = xpcall(DutCmdCoreUsb.sendAndParseCommandCore, debug.traceback, commandStr, expect, needParse,
                                autoRecord, timeout, testName, subsubtest, constant.DEBUGGING_LOG_DISABLED, delimiter)
    end

    if not status or not response then
        Log.LogError("sendAndParseCommand failed,", response)
        return false
    end

    if attributeKey then
        local testResult = DataReporting.createAttribute(attributeKey, response)
        DataReporting.submit(testResult)
    end
    
    -- Convert unit if necessary
    if convertUnit and convertUnit ~= "" and unit and unit ~= "" then
        local convertStatus, convertedValue = xpcall(unitTool.convertUnit, debug.traceback, response, convertUnit, unit)
        if not convertStatus then
            Log.LogFlowDebug("Failed to convert unit from " .. convertUnit .. " to " .. unit)
            error("Failed to convert unit from " .. convertUnit .. " to " .. unit)
        end
        response = convertedValue
    end
    return response
end

-- !@brief Schooner CSV API
-- !@brief Send command, parse response with MD Parser and create records
-- !@param Command command string to send to device
-- !@param Timeout time in microsecond to wait for test done
-- ! @return data parsed from MDParser and match with the variable list in Output field
function DUTCmd.detectDiags(params)
    Log.LogFlowDebug("diags params: "..comFunc.dump(params))

    local targetString = params.targetString
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local timeout = params.timeout or 5

    local status, response = xpcall(DutCmdCore.detectCore, debug.traceback, targetString, timeout, testName, subsubtest)
    if not status then
        Log.LogError("detectCore failed,", response)
        return false
    else
        return response
    end
end

-- !@brief Schooner CSV API
-- !@brief Send command, parse response with MD Parser and create records
-- !@param Command command string to send to device
-- !@param Timeout time in microsecond to wait for test done
-- ! @return data parsed from MDParser and match with the variable list in Output field
function DUTCmd.detectDiagsUsb(params)
    Log.LogFlowDebug("diags params: "..comFunc.dump(params))

    local targetString = params.targetString
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local timeout = params.timeout or 5

    local status, response = xpcall(DutCmdCoreUsb.detectCore, debug.traceback, targetString, timeout, testName, subsubtest)
    if not status then
        Log.LogError("detectCore failed,", response)
        return false
    else
        return response
    end
end

function DUTCmd.checkIfSysBoot(params)
    Log.LogFlowDebug("diags params: "..comFunc.dump(params))
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local timeout = params.timeout or 1

    local status, response = xpcall(DutCmdCore.readBuffer, debug.traceback, timeout, testName, subsubtest)
    if not status then
        Log.LogError("checkIfSysBoot failed,", response)
        return false
    end

    if string.find(response, "Booting X3988") or string.find(response, "Found TPS25751") then
        Log.LogError("System Reboot: ", response)
        return false 
    end

    return "Not_Reboot"
end

-- !@brief send multiple DUT command and read DUT multiple response
-- !@param command: string type
-- !@param delimiter: string type
-- !@param timeout: number type
-- !@param expectedKeyWord: string type
-- !@return string result
function DUTCmd.sendReadMultipleCommands(additionalParameters)
    local commands = additionalParameters.Commands
    assert(commands ~= nil, "parameter is invalid, commands is nil")
    local timeout = additionalParameters.timeout
    assert(timeout ~= nil, "parameter is invalid, timeout is nil")
    local delimiter = additionalParameters.delimiter
    local expectedKeyWord = additionalParameters.expectedKeyWord
    local cmdList = comFunc.splitString(commands, ";")
    assert(#cmdList > 0, "commands is invalid")

    timeout = timeout / #cmdList
    local bRet, retVal
    for i = 1, #cmdList do
        bRet, retVal = xpcall(DutCmdCore.sendRead, debug.traceback, cmdList[i], timeout, expectedKeyWord,
                              delimiter, false)
        if not bRet or not retVal then
            Log.LogError("sendRead failed,", retVal)
            return false
        end
    end
    return retVal
end

-- function alias
-- !@brief Schooner CSV API
-- !@brief diags command need to return result if params output is existed
-- DUTCmd.diags = DUTCmd.sendRead

-- !@brief parse DUT response
-- !@param command: string type
-- !@param reps: string type
-- !@param pattern: number type
-- !@return string result
function DUTCmd.parse(input, additionalParameters)
    local resp = input
    local command = additionalParameters.Commands
    local parseKey = additionalParameters.parseKey
    local pattern = additionalParameters.pattern
    local retVal, bRet
    -- parse and return one value with pattern or MDParser
    if pattern then
        retVal = string.match(resp, pattern)
    elseif command then
        local MDParser = Device.getPlugin("MDParser")
        local bRet, pData = xpcall(MDParser.parse, debug.traceback, command, resp)
        if not bRet then 
            Log.LogError("MDParser response failed: "..tostring(command))
            return false
        end
        Log.LogInfo("MDParser:"..comFunc.dump(pData))
        if parseKey then
            retVal = pData[parseKey]
        else
            for _, v in pairs(pData) do
                if v ~= nil then
                    retVal = comFunc.trim(v)
                else
                    Log.LogError("parse failed!")
                    return false
                end
            end
        end
    else
        Log.LogError("Undefined pattern or commands!")
        return false
    end
    return retVal
end

local ActionHelper = require("SMTActionHelper")

local CSVInterfaceTable = {delegate = DUTCmd}

setmetatable(CSVInterfaceTable, ActionHelper.MetaTableFlowLogging)

return CSVInterfaceTable

