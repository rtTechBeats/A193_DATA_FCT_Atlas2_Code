local VISAInstrument = require("Internal/Instrument/VISAInstrument")
local log = require("Common/logging")
local Instruments = VISAInstrument or {}


-- inherit base functions from VISAInstrument before adding new functions
-- Instruments = VISAInstrument


-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias. 
-- !param identifier string, define the ip or visa of the instrument. 
-- !@return true if successful, false if failed
function Instruments.InstrumentConnect(params)
    local status, result = xpcall(VISAInstrument.VISAConnect, debug.traceback, params.name, params.identifier)
    if status and result then
        log.LogInfo("VISAInstrument Connect Pass")
        return true
    end
    log.LogError("VISAInstrument Connect Failed with : ", result)
    return false
end


-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias. 
-- !param command string, command data sent to the instrument. 
-- !@return true if successful, false if failed
function Instruments.InstrumentQuery(params)
    local status, result = xpcall(VISAInstrument.VISAQuery, debug.traceback, params.name, params.command)
    if status and result then
        log.LogInfo("VISAInstrument Query Pass")
        return true
    end
    log.LogError("VISAInstrument Query Failed with : ", result)
    return false
end


-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias. 
-- !param command string, command data sent to the instrument. 
-- !@return true if successful, false if failed
function Instruments.InstrumentWrite(params)
    local status, result = xpcall(VISAInstrument.VISAWrite, debug.traceback, params.name, params.command)
    if status and result then
        log.LogInfo("VISAInstrument Write Pass")
        return true
    end
    log.LogError("VISAInstrument Write Failed with : ", result)
    return false
end


-- !@brief Schooner csv API
-- !param name string, the alias for instrument.
-- !@return true if successful, false if failed
function Instruments.InstrumentClose(params)
    local status, result = xpcall(VISAInstrument.VISAClose, debug.traceback, params.name)
    if status and result then
        log.LogInfo("VISAInstrument Close Pass")
        return true
    end
    log.LogError("VISAInstrument Close Failed with : ", result)
    return false
end


local ActionHelper = require("SMTActionHelper")

local CSVInterfaceTable = {delegate = Instruments}

setmetatable(CSVInterfaceTable, ActionHelper.MetaTableFlowLogging)

return CSVInterfaceTable
