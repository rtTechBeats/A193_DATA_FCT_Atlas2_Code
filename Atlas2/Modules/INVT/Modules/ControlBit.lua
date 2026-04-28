-------------------------------------------------------------------
----***************************************************************
---- ControlBit Functions
----***************************************************************
-------------------------------------------------------------------
local helper = require("INVT/Modules/SMTLoggingHelper") 
local utilities = Device.getPlugin("Utilities")
local constant = require("INVT/constants")
local rtLib = require("INVT/Modules/RTCommonLib")
local dutCmd = require("INVT/Modules/DutCmdCore")
local pluginsLoader = require("INVT/Modules/PluginsLoader")
local runShellCmd = pluginsLoader.getPlugin("RunShellCommand")

local ControlBit = {}
ControlBit.plugin = pluginsLoader.getPlugin("ControlBit")

local timeOut = 1

-- !@brief get dut mlbsn
local function getSN()
    error("not implement yet")
end

-- !@brief get cb nonce
local function getNonce()
    local timeout = timeOut
    local nonceCmd = "055a02003280"
    local bRet, retVal, retHex = xpcall(dutCmd.sendRead, debug.traceback, nonceCmd, timeout)
    --!@ check command response
    if not bRet or not retHex then
        error('Error: get cb nonce fail')
    end
    --!@ check response is correct
    if retHex:sub(13, 14) ~= "01" then
        error("Error: cb nonce response incorrect")
    end

    local nonce = retHex:sub(15, 54)
    helper.LogFlowDebug("[CB Nonce]" .. nonce)
    return nonce
end

-- !@brief get dut passkey
local function getPassKey(offset)
    local cbLib = constant.LIB_PATH .. "/ControlBit"
    local pattern = "passKey%=(%w+)"
    local nonce = getNonce()
    local passKey = ControlBit.plugin.generatePassKey(offset, nonce)
    if #passKey ~= 40 then
        error("Error: get passKey failed")
    end
    return passKey
end

-- !@brief read control bit
-- !@param offset: station ID offset
-- !@returns current status, status table
function ControlBit.readCB(offset)
    local timeout = timeOut
    local readCmd = "055a03003480" .. offset
    local bRet, retVal, retHex = xpcall(dutCmd.sendRead, debug.traceback, readCmd, timeout)
    --!@ check command response
    if not bRet or not retHex then
        error('Error: read cb status fail')
    end

    local cbStatus = retHex:sub(15, 16)
    local pattern = "%w%w"
    local timeStamp = {}
    for d in retHex:sub(23, 30):gmatch(pattern) do
        table.insert(timeStamp, d)
    end
    timeStamp = rtLib.table_reverse(timeStamp)
    timeStamp = table.concat(timeStamp)

    local statusTab = {
        ["Test Status"] = cbStatus,
        ["Relative Fail Count"] = retHex:sub(17, 18),
        ["Absolute Fail Count"] = retHex:sub(19, 20),
        ["Erase Count"] = retHex:sub(21, 22),
        ["Timestamp"] = timeStamp,
        ["SW Version"] = retHex:sub(31, 78),
        ["Error Code"] = retHex:sub(79, -1)
    }

    helper.LogFlowDebug("")
    helper.LogFlowDebug("[Test Status] " .. cbStatus)
    helper.LogFlowDebug("[Relative Fail Count] " .. retHex:sub(17, 18))
    helper.LogFlowDebug("[Absolute Fail Count] " .. retHex:sub(19, 20))
    helper.LogFlowDebug("[Erase Count] " .. retHex:sub(21, 22))
    helper.LogFlowDebug("[Timestamp] " .. timeStamp)
    helper.LogFlowDebug("[SW Version] " .. retHex:sub(31, 78))
    helper.LogFlowDebug("[Error Code] " .. retHex:sub(79, -1))
    helper.LogFlowDebug("")

    return cbStatus, statusTab
end

-- !@brief write control bit
-- !@param offset: station ID offset
-- !@param status: write CB {U,I,F,P}
function ControlBit.writeCB(offset, status)
    local timeout = timeOut
    local writeCmd = "055A34003580" .. offset
    local statusTab = {U = "00", I = "01", F = "02", P = "03"}
    local status = statusTab[tostring(status):upper()] or error("Pleas input correct status {U, I, F, P}")
    local rawTimeStamp = string.format("%.8x", os.time())
    local pattern = "%w%w"
    local timeStamp = {}
    local overlayVer = constant.StationInfo.stationOverlay

    for d in rawTimeStamp:gmatch(pattern) do
        table.insert(timeStamp, d)
    end
    timeStamp = rtLib.table_reverse(timeStamp)
    timeStamp = table.concat(timeStamp)

    overlayVer = overlayVer:match("[vV](%d+%.%d+)") or error("Parser station overlay failed")
    overlayVer = string.format("%.4x", overlayVer:gsub("%.", ""))
    overlayVer = overlayVer:sub(1, 2) == "00" and overlayVer:sub(3, 4)
    overlayVer = overlayVer .. string.rep("0", 48 - #overlayVer)

    local passKey = status == "03" and getPassKey(offset) or string.rep("0", 40)
    helper.LogFlowDebug("[PassKey] "..passKey)

    writeCmd = writeCmd..status..timeStamp..passKey..overlayVer
    local bRet, retVal, retHex = xpcall(dutCmd.sendRead, debug.traceback, writeCmd, timeout)
    --!@ check command response
    if not bRet or not retHex then
        error('Error: write cb status fail')
    end
    --!@ check response is correct
    if retHex:sub(13, 14) ~= "01" then
        error("Error: cb write response incorrect")
    end

    return retHex
end


-- !@brief clear control bit
-- !@param offset: station ID offset
function ControlBit.clearCB(offset)
    local timeout = timeOut
    local clearCmd = "055a20003680" .. offset .. offset
    local rawTimeStamp = string.format("%.8x", os.time())
    local pattern = "%w%w"
    local timeStamp = {}
    local overlayVer = constant.StationInfo.stationOverlay

    for d in rawTimeStamp:gmatch(pattern) do
        table.insert(timeStamp, d)
    end
    timeStamp = rtLib.table_reverse(timeStamp)
    timeStamp = table.concat(timeStamp)

    overlayVer = overlayVer:match("[vV](%d+%.%d+)$") or error("Parser station overlay failed")
    overlayVer = string.format("%.4x", overlayVer:gsub("%.", ""))
    overlayVer = overlayVer:sub(1, 2) == "00" and overlayVer:sub(3, 4)
    overlayVer = overlayVer .. string.rep("0", 48 - #overlayVer)

    clearCmd = clearCmd..timeStamp..overlayVer
    local bRet, retVal, retHex = xpcall(dutCmd.sendRead, debug.traceback, clearCmd, timeout)
    --!@ check command response
    if not bRet or not retHex then
        error('Error: clear cb fail')
    end
    --!@ check response is correct
    if retHex:sub(13, 14) ~= "01" then
        error("Error: cb clear response incorrect")
    end
    return retHex
end

return ControlBit
