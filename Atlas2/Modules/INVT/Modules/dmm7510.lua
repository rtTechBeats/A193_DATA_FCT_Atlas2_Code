local log = require("Common/logging")
local UnitTool = require("Common/UnitTool")
local comFunc = require("Common/Utilities")
local time = require("INVT/Modules/Time")
local Log = require("INVT/Modules/SMTLoggingHelper")
local DMM7510 = {}
local dmmVisa = nil
local name = "dmm"
local port = "USB0::0x05E6::0x7510::04319519::INSTR"
-- inherit base functions from VISAInstrument before adding new functions


function DMM7510.connectDmmInstr(name, port)
    local visa = Atlas.loadPlugin("VisaInstrument")
    -- local rsrc = "USB0::0x067B::0x23C3::DGCQb103Y23::RAW"
    dmmVisa = visa.open(port, {timeoutMs = 5000, readBytes = 9600, readUntil = "\n"})
    Log.LogFlowDebug(string.format("Open Instrument %s successfully", name))
    local idn = dmmVisa.sendCommand("*RST\n")
    Log.LogFlowDebug("Query *RST: " .. tostring(idn.output))
    return dmmVisa
end

-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias.
-- !param command string, command data sent to the instrument.
-- !@return result if successful, false if failed
function DMM7510.write(cmd)
    if not dmmVisa then
        DMM7510.connectDmmInstr(name, port)
    end
    local cmd = cmd.."\n"
    Log.LogFlowDebug("Send cmd to DMM: "..cmd)
    local status, resp = pcall(dmmVisa.sendCommand, cmd)
    if not status then
        log.LogError(resp)
        error(resp)
    end
    Log.LogFlowDebug("Response from DMM: "..comFunc.dump(resp))
    return resp
end

-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias.
-- !param command string, command data sent to the instrument.
-- !@return true if successful, false if failed
function DMM7510.query(cmd)
    local resp = DMM7510.write(cmd)
    if not resp then
        error(resp)
    end
    if type(resp) == "table" and comFunc.trim(resp.code) == "0" then
        return comFunc.trim(resp.output)
    else
        error(comFunc.trim(resp.error))
    end
end

-- !@brief Schooner csv API
-- !param name string, the alias for instrument.
-- !@return true if successful, false if failed
function DMM7510.resetDmm(params)
    local cmd = "*RST"
    local status, result = xpcall(DMM7510.query, debug.traceback, cmd)
    if status and result then
        log.LogFlowDebug("DMM Reset Pass")
        return true
    end
    log.LogFlowDebug("DMM Reset Failed with : ", result)
    return false
end



-- !@brief Schooner csv API
-- !param name string, the alias for instrument. 
-- !param range string (optional), set the range of the instrument.
    -- range:[0.1,1,10,100,1000,AUTO], unit is V, default is AUTO.
-- !@return DC Voltage if successful, false if failed
function DMM7510.configDMMInstr(mode, range)
    local mode = tostring(mode)
    local range = tostring(range)
    local cmd_table = {}
    if mode == "CURR" then
        table.insert(cmd_table, string.format("SENS:%s:DC:NPLC 10", mode))
    else
        table.insert(cmd_table, string.format("SENS:%s:DC:NPLC 10", mode))
        table.insert(cmd_table, string.format("SENS:%s:DC:RANG %s", mode, range))
    end
    for _, cmd in ipairs(cmd_table) do
        local status, result = xpcall(DMM7510.query, debug.traceback, cmd)
        if not status then
            log.LogFlowDebug("DMM query cmd fail")
            error(result)
        end
    end
    return true
end

-- !@brief Schooner csv API
-- !param name string, the alias for instrument. 
-- !param range string (optional), set the range of the instrument.
    -- range:[0.1,1,10,100,750,AUTO], unit is V, default is AUTO.
-- !param band string (optional), set the band of the instrument.
    -- band:[3,20,200], unit is Hz, default is 20.
-- !@return AC Voltage if successful, false if failed
function DMM7510.measureVoltageByInstrDmm(params)    

    local cmd = "MEASure:VOLT:DC?"
    for i = 1, 4 do 
        local status, result = xpcall(DMM7510.query, debug.traceback, cmd)
        time.sleep(0.1)
        if not status then
            log.LogFlowDebug("DMM measure voltage fail")
            error(result)
        end
    end
    return tonumber(result)
end

function DMM7510.closeDmm(params)
    if dmmVisa then
        -- local status, result = xpcall(query, debug.traceback, "*RST")
        -- if not status then
        --     log.LogFlowDebug("DMM Reset fail")
        --     error(result)
        -- end
        dmmVisa.close()        
    end
    return true
end


-- !@brief Schooner csv API
-- !param name string, the alias for instrument. 
-- !param range string (optional), set the range of the instrument.
    -- range:[0.000001,0.00001,0.0001,0.001,0.01,0.1,1,3,AUTO], unit is A, default is AUTO.
-- !@return DC Current if successful, false if failed
function DMM7510.measureCurrentByInstrDmm(params)
    local cmd = "MEASure:CURRent:DC?"
    for i = 1, 3 do
        local status, result = xpcall(DMM7510.query, debug.traceback, cmd)
        time.sleep(0.1)
        if not status then
            log.LogFlowDebug("DMM measure current fail")
            error(result)
        end
    end
    return tonumber(result)
end

return DMM7510
