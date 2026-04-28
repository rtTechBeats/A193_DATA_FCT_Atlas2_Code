-------------------------------------------------------------------
----***************************************************************
---- DUTCmd.lua provide functions to communicate with
---- DUT via UART or USBC
----***************************************************************
-------------------------------------------------------------------
local rtLib = require("INVT/Modules/RTCommonLib")
local comFunc = require("Common/Utilities")
local PluginsLoader = require("INVT/Modules/PluginsLoader")
local DutCommunicate = PluginsLoader.getPlugin("USBC")
local Helper = require("INVT/Modules/SMTLoggingHelper")
local Utilities = Device.getPlugin("Utilities")
local time = require("INVT/Modules/Time")

local DUTCmd = {}
local DefTimeOut = 1

-- !@brief communication channel mux
-- !@return open boolean result
function DUTCmd.commMux(channel)
    if channel:upper() == "UART" then
        DutCommunicate = PluginsLoader.getPlugin("UART")
    elseif channel:upper() == "USBC" then
        DutCommunicate = PluginsLoader.getPlugin("USBC")
    elseif channel:upper() == "CASEUART" then
        DutCommunicate = PluginsLoader.getPlugin("CaseUart")    
    else
        -- error("Undefined DUT Communicate")
        DutCommunicate = PluginsLoader.createComm(channel, Device.userDirectory.."/uart.log")
    end
    return DUTCmd.open()
end


-- !@brief open DUT uart
-- !@return boolean result
function DUTCmd.open()
    if DutCommunicate.isOpened() == 1 then
        return true
    end
    --!@ Some time occured resource busy
    for i=1, 5, 1 do
        local status, _ = pcall(DutCommunicate.open)
        if status then break end
        Helper.LogFlowDebug("[Warning] Resource busy or USBC port not exists occured!")
        time.sleep(0.2)
    end
    local bRet = DutCommunicate.isOpened() == 1
    return bRet
end

-- !@brief close DUT uart
-- !@return boolean result
function DUTCmd.close()
    if DutCommunicate.isOpened() == 1 then
        return DutCommunicate.close()
    end
    return true
end

-- !@brief clear DUT response(read redundancy infomation to clear the Uart buffer)
-- !@param timeout: number type
-- !@return string result
function DUTCmd.clear(timeout)
    local timeout = timeout or DefTimeOut
    -- read data
    DutCommunicate.setTimeoutIsException(0)
    local _, response = pcall(DutCommunicate.readData, timeout)
    DutCommunicate.setTimeoutIsException(1)

    return response
end

-- !@brief set delimiter with setDelimiter()
-- !@param command: string type
-- !@return boolean result
function DUTCmd.setDelimiter(delimiter)
    -- check the delimiter
    DutCommunicate.setDelimiter(delimiter)
    return true
end

-- !@brief send DUT command with Uart.write
-- !@param command: string type
-- !@return boolean result
function DUTCmd.send(command)
    Helper.LogDutCommStart(command)
    DutCommunicate.write(command .. "\n")
    return true
end

-- !@brief send DUT command with Uart.write
-- !@param command: hex string
-- !@return boolean result
function DUTCmd.sendData(command)
    Helper.LogDutCommStart(command)
    local cmdData = Utilities.dataFromHexString(command)
    DutCommunicate.writeData(cmdData)
    return true
end

-- !@brief read DUT response by Uart.read and return the string by expectedKeyWord
-- !@param timeout: number type
-- !@param delimiter: string type
-- !@return string result
function DUTCmd.read(timeout, delimiter)
    local timeout = timeout or DefTimeOut
    local msg = string.format("DUTCmd.read(timeout=%s, delimiter=%s)", timeout, delimiter)
    msg = msg:gsub("\r", "\\r")
    msg = msg:gsub("\n", "\\n")
    Helper.LogFlowDebug(msg)
    DUTCmd.setDelimiter(delimiter)
    -- read data
    local retVal = DutCommunicate.read(timeout)
    Helper.LogDutCommFinish(retVal)
    return retVal
end

-- !@brief read DUT response by Uart.readData
-- !@param timeout: number type
-- !@param expectedKeyWord: string type
-- !@param delimiter: string type
-- !@return string result
function DUTCmd.readData(timeout, expectedKeyWord, delimiter)
    local timeout = timeout or DefTimeOut
    local delimiter = delimiter or "" --default read all buffer
    local msg = string.format("DUTCmd.readData(timeout=%s, expectedKeyWord=%s, delimiter=%s)", 
                              timeout, expectedKeyWord, delimiter)
    msg = msg:gsub("\r", "\\r")
    msg = msg:gsub("\n", "\\n")
    Helper.LogFlowDebug(msg)
    DUTCmd.setDelimiter(delimiter)

    local retStr, retHex, retBuf = "", "", ""
    local emptyCount = 0
    local recvTail = true
    local startTime = time.time()
    -- read Data
    while time.time() - startTime <= timeout do
        DutCommunicate.setTimeoutIsException(0)
        local retValData = DutCommunicate.readData(0.1)
        DutCommunicate.setTimeoutIsException(1)
        -- retValData={length = 16, bytes = 0xFFFF...}
        retBuf = Utilities.dataToHexString(retValData)
        -- overall hex string data
        retHex = retHex .. retBuf
        -- convert hex Data to ASCII
        retStr = retStr .. rtLib.hex2ascii(retBuf)
        -- check empty count
        emptyCount = #retBuf == 0 and #retHex >= 1 and not expectedKeyWord and
                     emptyCount + 1 or emptyCount + 0
        if emptyCount == 5 then
            break
        end
        if #retBuf == 0 and expectedKeyWord and retStr:find(expectedKeyWord) and recvTail then
            recvTail = false
            goto continue
        end
        if not recvTail then break end
        ::continue::
    end
    local hexInfo = #retHex > 498 and "..."..retHex:sub(-495, -1) or retHex
    Helper.LogFlowDebug("[Recv Hex]"..hexInfo)
    Helper.LogDutCommFinish("[Recv ASCII]"..retStr)
    return retStr, retHex
end

-- !@brief sendReadStr
-- !@param command: string type
-- !@param timeout: number type
-- !@return string result
function DUTCmd.sendReadStr(command, timeout, delimiter)
    DUTCmd.send(command)
    return DUTCmd.read(timeout, delimiter)
end

-- !@brief sendReadByHex
-- !@param command: Hex string
-- !@param timeout: number type
-- !@param expectedKeyWord: string type
-- !@return string result
function DUTCmd.sendReadHex(command, timeout, expectedKeyWord, delimiter)
    DUTCmd.clear(0.02)
    DUTCmd.sendData(command)
    return DUTCmd.readData(timeout, expectedKeyWord, delimiter)
end

-- !@brief sendCmdByByte
-- !@param command: string type
-- !@param characterSize: number type
-- !@param delay: number type
-- !@param timeout: number type
-- !@return string result
function DUTCmd.sendCmdByByte(command, characterSize, delay, timeout, delimiter)
    Helper.LogDutCommStart(command)
    command = command .. "\n"
    if #command <= characterSize then
        DutCommunicate.write(command)
    else
        for i = 1, #command, characterSize do
            DutCommunicate.write(string.sub(command, i, i + characterSize - 1))
            time.sleep(delay)
        end
    end
    return DUTCmd.read(timeout, delimiter)
end

-- !@brief send DUT command and read DUT response with Uart.send then get the return value by expectedKeyWord and MDParser
-- !@param command: string type
-- !@param delimiter: string type
-- !@param timeout: number type
-- !@param expectedKeyWord: string type
-- !@param needParser: boolean type, MDParse only catch one value
-- !@return string result
function DUTCmd.sendRead(command, timeout, expectedKeyWord, delimiter, needParser)
    local command = command and command or ""
    local timeout = timeout or DefTimeOut
    local msg = string.format("DUTCmd.sendRead(command=%s, timeout=%s, expectedKeyWord=%s, delimiter=%s, needParser=%s)", 
                               command, timeout, expectedKeyWord, delimiter, needParser)
    msg = msg:gsub("\r", "\\r")
    msg = msg:gsub("\n", "\\n")
    Helper.LogFlowDebug(msg)

    DUTCmd.open()
    DUTCmd.setDelimiter(delimiter)

    -- !@ send cmd by byte api
    -- local _, retVal = pcall(DUTCmd.sendCmdByByte, command, 6, 0.2, timeout, delimiter)
    -- !@ send cmd by string api
    -- local _, retVal = pcall(DUTCmd.sendReadStr, command, timeout, delimiter)
    local _, retVal, retHex = pcall(DUTCmd.sendReadHex, command, timeout, expectedKeyWord, delimiter)
    
    -- when the read action "Timed out" or the read info is nil, then resend "\n" and read the DUT buffer again.
    if retVal == nil or string.find(tostring(retVal), "Timed out") then
        -- !@ send cmd by byte api
        -- local _, retVal = pcall(DUTCmd.sendCmdByByte, command, 6, 0.2, timeout, delimiter)
        -- !@ send cmd by string api
        -- local _, retVal = pcall(DUTCmd.sendReadStr, command, timeout, delimiter)
        local _, retVal, retHex = pcall(DUTCmd.sendReadHex, "", timeout, expectedKeyWord, delimiter)
        Helper.LogFlowDebug("resend \\n and read the DUT buffer again:" .. retVal)
        DUTCmd.clear(0.02)
    end

    local bReult = true
    -- parse the value with expectedKeyWord
    if expectedKeyWord then
        if string.find(retVal, expectedKeyWord) then
            Helper.LogFlowDebug("ok: find the expected key word")
        else
            bReult = false
            Helper.LogFlowDebug("error: can't find the expected key word")
        end
    end
    -- parse and return one value with MDParser
    if needParser then
        local MDParser = Device.getPlugin("MDParser")
        local result, pData = xpcall(MDParser.parse, debug.traceback, command, retVal)

        if not result then error("MDParser response failed: " .. tostring(command)) end
        Helper.LogFlowDebug("MDParser:"..comFunc.dump(pData))
        for _, v in pairs(pData) do
            if v ~= nil then
                retVal = comFunc.trim(v)
            else
                bReult = false
                Helper.LogFlowDebug("parse failed!")
            end
        end
    end

    return bReult and retVal, retHex or "", ""

end

return DUTCmd
