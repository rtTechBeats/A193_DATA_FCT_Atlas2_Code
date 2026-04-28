local log = require("Common/logging")
local UnitTool = require("Common/UnitTool")
local comFunc = require("Common/Utilities")
local time = require("INVT/Modules/Time")
local Log = require("INVT/Modules/SMTLoggingHelper")
local DG822 = {}
local dgVisa = nil
local name = "dg822"
local port = "USB0::0x1AB1::0x0646::DG8Q272401258::INSTR"
-- inherit base functions from VISAInstrument before adding new functions


function DG822.connectDgInstr(name, port)
    local visa = Atlas.loadPlugin("VisaInstrument")
    -- local rsrc = "USB0::0x067B::0x23C3::DGCQb103Y23::RAW"
    dgVisa = visa.open(port, {timeoutMs = 1000, readBytes = 9600, readUntil = "\n"})
    Log.LogInfo(string.format("Open Instrument %s successfully", name))
    -- local idn = dgVisa.sendCommand("*IDN?")
    -- Log.LogInfo("Query *IDN: " .. tostring(idn.output))
    return dgVisa
end

-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias.
-- !param command string, command data sent to the instrument.
-- !@return result if successful, false if failed
function DG822.write(cmd)
    if not dgVisa then
        DG822.connectDgInstr(name, port)
    end
    -- local cmd = cmd.."\n"
    Log.LogFlowDebug("Send cmd to DG822: "..cmd)
    local status, resp = pcall(dgVisa.sendCommand, cmd)
    if not status then
        log.LogError(resp)
        error(resp)
    end
    Log.LogFlowDebug("Response from DG822: "..comFunc.dump(resp))
    return resp
end

-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias.
-- !param command string, command data sent to the instrument.
-- !@return true if successful, false if failed
function DG822.query(cmd)
    local resp = DG822.write(cmd)
    if not resp then
        error(resp)
    end
    if type(resp) == "table" and resp.output ~= nil and resp.code == "0" then
        return comFunc.trim(resp.output)
    else
        error(comFunc.trim(resp.error))
    end
end

-- !@brief Schooner csv API
-- !param name string, the alias for instrument.
-- !@return true if successful, false if failed
function DG822.reset(params)
    local cmd = "*RST"
    local status, result = xpcall(DG822.query, debug.traceback, cmd)
    if status and result then
        log.LogFlowDebug("DG822 Reset Pass")
        return true
    end
    log.LogFlowDebug("DG822 Failed with : ", result)
    return false
end



-- !@brief Schooner csv API
-- !param name string, the alias for instrument. 
-- !param range string (optional), set the range of the instrument.
    -- range:[0.1,1,10,100,1000,AUTO], unit is V, default is AUTO.
-- !@return DC Voltage if successful, false if failed
function DG822.enableSine(channel, freq, volt, unit, offsetVolt, phase)
    local channel = channel or "1"
    local freq = freq or "1000"
    local volt = volt or "1"
    local unit = unit or "VRMS"
    local offsetVolt = offsetVolt or "0"
    local phase = phase or "0"

    local cmd_table = {}
    cmd_table[1] = string.format(":SOUR%s:FUNC SIN", channel)
    cmd_table[2] = string.format(":SOUR%s:VOLT:UNIT %s;:SOUR%s:APPL:SIN %s,%s,%s,%s", channel, unit, channel, freq, volt, offsetVolt, phase)
    cmd_table[3]  = string.format("OUTP%s ON", channel)
    log.LogFlowDebug("DG822 cmd: ".. comFunc.dump(cmd_table))
    for _, cmd in pairs(cmd_table) do
        local status, result = xpcall(DG822.query, debug.traceback, cmd)
        time.sleep(0.1)
        if not status then
            log.LogFlowDebug("DG822 query cmd fail")
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
function DG822.enableSquare(channel, freq, volt, unit, duty_cycle, offsetVolt)    

    local channel = channel or "1"
    local freq = freq or "1000"
    local volt = volt or "1"
    local unit = unit or "VPP"
    local offsetVolt = offsetVolt or "0"
    local duty_cycle = duty_cycle or "50"

    local cmd_table = {}
    cmd_table[1] = string.format(":SOUR%s:FUNC SQU", channel)
    cmd_table[2] = string.format(":SOUR%s:VOLT:UNIT %s;:SOUR%s:APPL:SQU %s,%s,%s;:SOUR%s:FUNC:SQU:DCYC %s", channel, unit, channel, freq, volt, offsetVolt, channel, duty_cycle)
    cmd_table[3]  = string.format("OUTP%s ON", channel)
    
    for _, cmd in ipairs(cmd_table) do
        local status, result = xpcall(DG822.query, debug.traceback, cmd)
        time.sleep(0.1)
        if not status then
            log.LogFlowDebug("DG822 query cmd fail")
            error(result)
        end
    end
    return true
end

function DG822.disableDg(channel)    

    local channel = channel or "1"

    local cmd_table = {}
    cmd_table[1]  = string.format("OUTP%s OFF", channel)

    for _, cmd in ipairs(cmd_table) do
        local status, result = xpcall(DG822.query, debug.traceback, cmd)
        if not status then
            log.LogFlowDebug("DG822 query cmd fail")
            error(result)
        end
    end
    return true
end

function DG822.close(params)
    if dgVisa then
        -- local status, result = xpcall(query, debug.traceback, "*RST")
        -- if not status then
        --     log.LogFlowDebug("DMM Reset fail")
        --     error(result)
        -- end
        dgVisa.close()        
    end
    return true
end

return DG822
