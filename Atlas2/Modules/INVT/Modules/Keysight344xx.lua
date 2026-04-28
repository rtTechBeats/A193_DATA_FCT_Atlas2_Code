local VISAInstrument = require("Internal/Instrument/VISAInstrument")
local log = require("Common/logging")
local delay = require("Internal/TimeCore").delay
local UnitTool = require("Common/UnitTool")
local Keysight344xx = VISAInstrument or {}
-- inherit base functions from VISAInstrument before adding new functions
-- Keysight344xx = VISAInstrument

-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias. 
-- !param identifier string, define the ip or visa of the instrument. 
-- !@return true if successful, false if failed
function Keysight344xx.Keysight344xxConnect(params)
    local status, result = xpcall(VISAInstrument.VISAConnect, debug.traceback, params.name, params.identifier)
    if status and result then
        log.LogInfo("Keysight344xx Connect Pass")
        return true
    end
    log.LogError("Keysight344xx Connect Failed with : ", result)
    return false
end

-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias.
-- !param command string, command data sent to the instrument.
-- !@return result if successful, false if failed
function Keysight344xx.Keysight344xxQuery(params)
    local status, result = xpcall(VISAInstrument.VISAQuery, debug.traceback, params.name, params.command)
    if status and result then
        log.LogInfo("Keysight344xx Query Pass")
        return commonFunc.trim(result)
    end
    log.LogError("Keysight344xx Query Failed with : ", result)
    return false
end

-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias.
-- !param command string, command data sent to the instrument.
-- !@return true if successful, false if failed
function Keysight344xx.Keysight344xxWrite(params)
    local status, result = xpcall(VISAInstrument.VISAWrite, debug.traceback, params.name, params.command)
    if status and result then
        log.LogInfo("Keysight344xx Write Pass")
        return true
    end
    log.LogError("Keysight344xx Write Failed with : ", result)
    return false
end

-- !@brief Schooner csv API
-- !param name string, the alias for instrument.
-- !@return true if successful, false if failed
function Keysight344xx.Keysight344xxClose(params)
    local status, result = xpcall(VISAInstrument.VISAClose, debug.traceback, params.name)
    if status and result then
        log.LogInfo("Keysight344xx Close Pass")
        return true
    end
    log.LogError("Keysight344xx Close Failed with : ", result)
    return false
end



-- !@brief Schooner csv API
-- !param name string, the alias for instrument. 
-- !param range string (optional), set the range of the instrument.
    -- range:[0.1,1,10,100,1000,AUTO], unit is V, default is AUTO.
-- !@return DC Voltage if successful, false if failed
function Keysight344xx.Keysight344xxVdc(params)
    local name = params.name
    local range = params.range
    local unit = params.unit or "V"
    local cmd_format = "MEAS:VOLT:DC? %s"
    range = range or "AUTO"
    local command = string.format(cmd_format, range)
    local response = VISAInstrument.VISAQuery(name, command)
    log.LogInfo("Keysight344xx Vdc response: ", response)
    if (response ~= nil) then
        local volt = string.match(tostring(response) .. ";", "(.-);")
        log.LogInfo("Keysight344xx Vdc: ", tonumber(volt))
        return UnitTool.convertUnit(tonumber(volt), "V", unit)
    else
        log.LogError("Keysight344xx Vdc Failed")
        return false
    end
end

-- !@brief Schooner csv API
-- !param name string, the alias for instrument. 
-- !param range string (optional), set the range of the instrument.
    -- range:[0.1,1,10,100,750,AUTO], unit is V, default is AUTO.
-- !param band string (optional), set the band of the instrument.
    -- band:[3,20,200], unit is Hz, default is 20.
-- !@return AC Voltage if successful, false if failed
function Keysight344xx.Keysight344xxVac(params)    
    local name = params.name
    local range = params.range  or "AUTO"
    local band = params.band  or "20"
    local command = "CONF:VOLT:AC " .. range
    VISAInstrument.VISAWrite(name, command)
    local command = "VOLT:AC:BAND " .. band
    VISAInstrument.VISAWrite(name, command)
    delay(300)
    local command = "READ?"
    local response = VISAInstrument.VISAQuery(name, command)
    if (response ~= nil) then
        local volt = string.match(tostring(response) .. ";", "(.-);")
        log.LogInfo("Keysight344xx Vac: ", tonumber(volt))
        return tonumber(volt);
    else
        log.LogError("Keysight344xx AC Voltage response error")
        return false
    end
end


-- !@brief Schooner csv API
-- !param name string, the alias for instrument. 
-- !param range string (optional), set the range of the instrument.
    -- range:[0.000001,0.00001,0.0001,0.001,0.01,0.1,1,3,AUTO], unit is A, default is AUTO.
-- !@return DC Current if successful, false if failed
function Keysight344xx.Keysight344xxCurrent(params)
    local name = params.name
    range = params.range or "AUTO"
    local unit = params.unit or "A"
    local cmd_format = "MEAS:CURR:DC? %s"
    local command = string.format(cmd_format, range)
    local response = VISAInstrument.VISAQuery(name, command)
    if (response ~= nil) then
        local current = string.match(tostring(response) .. ";", "(.-);")
        log.LogInfo("Keysight344xx read current: ", tonumber(current))
        return UnitTool.convertUnit(tonumber(current), "A", unit)
    else
        log.LogError("Keysight344xx get DMM DC Current response error")
        return false
    end
end


-- !@brief Schooner csv API
-- !param name string, the alias for instrument. 
-- !param mode string (optional), set the mode of the instrument.
    -- mode:[2-wire,4-wire], default is 2-wire.
-- !@return Resistance if successful, false if failed
function Keysight344xx.Keysight344xxRes(params)
    local name = params.name
    local mode = params.mode or "2-wire"

    if (mode == "2-wire") then
        local command = "Meas:Res?"
    else
        local command = "Meas:FRESistance?"
    end
    delay(300)
    local response = VISAInstrument.VISAQuery(name, command);
    if (response ~= nil) then
        local resistor = string.match(tostring(response) .. ";", "(.-);");
        log.LogInfo("Keysight344xx read Resistor: ", tonumber(resistor))
        return tonumber(resistor)
    else
        error("Keysight344xx read resistance error")
        return false
    end
end



local ActionHelper = require("SMTActionHelper")

local CSVInterfaceTable = {delegate = Keysight344xx}

setmetatable(CSVInterfaceTable, ActionHelper.MetaTableFlowLogging)

return CSVInterfaceTable
