local log = require("Common/logging")
local delay = require("Internal/TimeCore").delay
local UnitTool = require("Common/UnitTool")
local comFunc = require("Common/Utilities")
local eloadVisa = device.getPlugin("eloadVisa")
local time = require("INVT/Modules/Time")
local Log = require("INVT/Modules/SMTLoggingHelper")
local eloadIT = {}
-- inherit base functions from VISAInstrument before adding new functions


-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias.
-- !param command string, command data sent to the instrument.
-- !@return result if successful, false if failed
function write(cmd)
    Log.LogFlowDebug("Send cmd to Eload: "..cmd)
    local status, resp = pcall(eloadVisa.sendCommand, cmd)
    if not status then
        log.LogError(resp)
        error(resp)
    end
    Log.LogFlowDebug("Response from Eload: "..comFunc.dump(resp))
    return resp
end

-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias.
-- !param command string, command data sent to the instrument.
-- !@return true if successful, false if failed
function query(cmd)
    local resp = write(cmd)
    if not resp then
        error(resp)
    end
    if type(resp) == "table" and resp.output ~= nil then
        return comFunc.trim(resp.output)
    end
    return comFunc.trim(resp)
end

-- !@brief Schooner csv API
-- !param name string, the alias for instrument.
-- !@return true if successful, false if failed
function eloadIT.resetEload(params)
    local cmd = "*RST"
    local status, result = xpcall(query, debug.traceback, cmd)
    if status and result then
        log.LogFlowDebug("Eload Reset Pass")
        return true
    end
    log.LogFlowDebug("Eload Reset Failed with : ", result)
    return false
end



-- !@brief Schooner csv API
-- !param name string, the alias for instrument. 
-- !param range string (optional), set the range of the instrument.
    -- range:[0.1,1,10,100,1000,AUTO], unit is V, default is AUTO.
-- !@return DC Voltage if successful, false if failed
function eloadIT.enableInstrEload(params)
    local current = params.current
    local current_cmd = string.format("CURR:CC %s", current)
    local mode_cmd = "MODE CC"
    local enable_cmd = "LOAD ON"
    local status, result = xpcall(query, debug.traceback, mode_cmd)
    if not status then
        log.LogFlowDebug("Eload set mode fail")
        return false
    end
    time.sleep(0.2)
    local status, result = xpcall(query, debug.traceback, current_cmd)
    if not status then
        log.LogFlowDebug("Eload set current fail")
        return false
    end
    time.sleep(0.2)
    local status, result = xpcall(query, debug.traceback, enable_cmd)
    if not status then
        log.LogFlowDebug("Eload enable fail")
        return false
    end
    time.sleep(0.2)
    return true
end

-- !@brief Schooner csv API
-- !param name string, the alias for instrument. 
-- !param range string (optional), set the range of the instrument.
    -- range:[0.1,1,10,100,750,AUTO], unit is V, default is AUTO.
-- !param band string (optional), set the band of the instrument.
    -- band:[3,20,200], unit is Hz, default is 20.
-- !@return AC Voltage if successful, false if failed
function eloadIT.measureCurrentByInstrEload(params)    

    local cmd = "MEAS:CURR?"
    local status, result = xpcall(query, debug.traceback, cmd)
    if not status then
        log.LogFlowDebug("Eload measure current fail")
        error(result)
    end
    return tonumber(result)
end


-- !@brief Schooner csv API
-- !param name string, the alias for instrument. 
-- !param range string (optional), set the range of the instrument.
    -- range:[0.000001,0.00001,0.0001,0.001,0.01,0.1,1,3,AUTO], unit is A, default is AUTO.
-- !@return DC Current if successful, false if failed
function eloadIT.disableInstrEload(params)
    local cmd = "LOAD OFF"
    local status, result = xpcall(query, debug.traceback, cmd)
    if not status then
        log.LogFlowDebug("Eload disable fail")
        error(result)
    end
    return true
end



local ActionHelper = require("SMTActionHelper")

local CSVInterfaceTable = {delegate = eloadIT}

setmetatable(CSVInterfaceTable, ActionHelper.MetaTableFlowLogging)

return CSVInterfaceTable
