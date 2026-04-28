-------------------------------------------------------------------
----***************************************************************
---- Feasa.lua provide functions to communicate with 
---- Feasa LED via UART
----***************************************************************
-------------------------------------------------------------------
local comFunc = require("Common/Utilities")
local Mutex = require("mutex")
local constant = require("INVT/constants")
local PluginsLoader = require("INVT/Modules/PluginsLoader")
local Helper = require("INVT/Modules/SMTLoggingHelper")
local Utilities = Device.getPlugin("Utilities")
local time = require("INVT/Modules/Time")

local Feasa = {}
local FeasaCommunicate = nil
local DefTimeOut = 1

-- !@brief communication mux
-- !@return open boolean result
function Feasa.CreateComm()
    local __inner = function()
        if FeasaCommunicate == nil then
            local groupNum, slotNum = string.match(Device.identifier, "G=(%d+):S=%a*(%d+)")
            local uartLogPath = Device.userDirectory.."/Feasa.log"
            local uartTab = constant.topology["groups"][tonumber(groupNum)]["FeasaLED"]
            local uartPath = uartTab["url"]
            assert(uartPath ~= nil, "uartPath is nil")
            local baudRate = tostring(uartTab["baudrate"] or 57600)
            local dataBit = tostring(uartTab["databit"] or 8)
            local parity = uartTab["parity"] or 'N'
            local stopBit = tostring(uartTab["stopbits"] or 1)
            local uartURL = "uart://"..uartPath.."?baud="..baudRate.."&mode="..dataBit..parity..stopBit
            Helper.LogFlowDebug("Feasa url: ", uartURL)
            Helper.LogFlowDebug("Feasa log : ", uartLogPath)
            FeasaCommunicate = PluginsLoader.createComm(uartURL, uartLogPath)
        end
        return FeasaCommunicate ~= nil
    end
    if FeasaCommunicate == nil then
        local id = "CreateComm-Feasa"
        local _mutex_plugin = Device.getPlugin("MutexPlugin")
        Mutex.runWithLock(_mutex_plugin, id, __inner)
    end
    return FeasaCommunicate ~= nil
end

-- !@brief measureLED
-- !@param channl: 01/02/03/04/05/06/all
-- !@param timeout: number type
-- !@return table type
function Feasa.measureLED(channel, types, timeout)
    local rgbiCommand = "getrgbi"..channel
    local absintCommand = "getabsint"..channel
    local xyCommand = "getxy"..channel
    local timeout = timeout or DefTimeOut
    if FeasaCommunicate == nil then
        Feasa.CreateComm()
    end
    Feasa.sendRead("setlin",timeout)
    Feasa.sendRead("putfactor02",timeout)
    -- if types == "white" then
    --     Feasa.sendRead("setcalibration00", timeout)
    --     Feasa.sendRead("putfactor04",timeout)
    -- else
    --     Feasa.sendRead("setcalibration01", timeout)
    --     Feasa.sendRead("putfactor03",timeout)
    -- end
    Feasa.sendRead("C2", timeout)
    local rgbiRetval= Feasa.sendRead(rgbiCommand, timeout)
    Helper.LogFlowDebug("[Feasa read RGBI]"..rgbiRetval)
    -- Feasa.sendRead("C2", timeout)
    -- local absintRetval= Feasa.sendRead(absintCommand, timeout)
    -- if absintRetval and tonumber(absintRetval) then
    --     absintRetval = tonumber(absintRetval) * 1000
    -- end
    -- Helper.LogFlowDebug("[Feasa read MCD]"..absintRetval)
    Feasa.sendRead("C2", timeout)
    local xyRetval= Feasa.sendRead(xyCommand, timeout)
    Helper.LogFlowDebug("[Feasa read XY]"..xyRetval)
    if not rgbiRetval or not xyRetval then
        return false
    end
    local retTab = {
        R=tonumber(rgbiRetval:sub(1,3)),
        G=tonumber(rgbiRetval:sub(5,8)),
        B=tonumber(rgbiRetval:sub(9,12)),
        I=tonumber(rgbiRetval:sub(13,18)),
        X=tonumber(xyRetval:sub(1,6)),
        Y=tonumber(xyRetval:sub(8,13))
    }
    Helper.LogFlowDebug("[Feasa Measure]"..comFunc.dump(retTab))
    return retTab
end

-- !@brief measureXY
-- !@param channl: 01/02/03/04/05/06/all
-- !@param timeout: number type
-- !@return table type
function Feasa.measureXY(channel, timeout)
    local command = "getxy"..channel
    local timeout = timeout or DefTimeOut
    if FeasaCommunicate == nil then
        Feasa.CreateComm()
    end
    Feasa.sendRead("C2", timeout)
    local retVal = Feasa.sendRead(command, timeout)
    local retTab = {
        X=tonumber(retVal:sub(1,6)),
        Y=tonumber(retVal:sub(8,13))
    }
    Helper.LogFlowDebug("[Feasa Measure]"..comFunc.dump(retTab))
    return retTab
end

-- !@brief setIntGain
-- !@param channl: 01/02/03/04/05/06/all
-- !@param timeout: number type
-- !@return table type
function Feasa.setIntGain(channel, gain, timeout)
    local command = "Setintgain"..channel..gain
    local timeout = timeout or DefTimeOut
    
    local bRet, retVal = Feasa.sendRead(command, 1)
    return retVal
end

-- !@brief getIntGain
-- !@param channl: 01/02/03/04/05/06/all
-- !@param timeout: number type
-- !@return table type
function Feasa.getIntGain(channel, timeout)
    local command = "Getintgain"..channel
    local timeout = timeout or DefTimeOut
    
    local bRet, retVal = Feasa.sendRead(command, 1)
    return retVal
end

-- !@brief getAbsInt
-- !@param channl: 01/02/03/04/05/06/all
-- !@param timeout: number type
-- !@return table type
function Feasa.getAbsInt(channel, led, timeout)
    local timeout = timeout or DefTimeOut
    
    Feasa.sendRead("setcalibration"..led, timeout)
    Feasa.sendRead("C2", 0.5)
    Feasa.sendRead("getabsint"..channel, timeout)
    return retVal
end

-- !@brief send Feasa command
-- !@param command: string type
-- !@param timeout: number type
-- !@return boolean, string
function Feasa.sendRead(command, timeout)
    local bRet, retVal
    local __inner = function()
        --!@ open Feasa
        if FeasaCommunicate.isOpened() ~= 1 then
            FeasaCommunicate.open()
        end
        --!@ clear buffer
        FeasaCommunicate.setDelimiter("")
        FeasaCommunicate.setTimeoutIsException(0)
        pcall(FeasaCommunicate.read, 0.02)
        FeasaCommunicate.setTimeoutIsException(1)
        --!@ send command
        Helper.LogFlowDebug("[Feasa Send] "..command)
        FeasaCommunicate.write(command .. "\n")
        --!@ read response
        FeasaCommunicate.setDelimiter("\n")
        bRet, retVal = pcall(FeasaCommunicate.read, timeout)
        Helper.LogFlowDebug("[Feasa Recv] "..retVal)
        --!@ close Feasa
        if FeasaCommunicate.isOpened() == 1 then
            return FeasaCommunicate.close()
        end
    end
    local timeout = timeout or DefTimeOut
    local id = "Feasa-sendRead"
    local _mutex_plugin = Device.getPlugin("MutexPlugin")
    Mutex.runWithLock(_mutex_plugin, id, __inner)
    return tostring(retVal)
end


return Feasa
