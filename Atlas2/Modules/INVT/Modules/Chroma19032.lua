local VISAInstrument = require("Internal/Instrument/VISAInstrument")
local log = require("Common/logging")
local commonFunc = require("Common/Utilities")
local Chroma19032 = VISAInstrument or {}

-- inherit base functions from VISAInstrument before adding new functions
-- Chroma19032Cmd = VISAInstrument

-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias.
-- !param identifier string, define the ip or visa of the instrument.
-- !@return true if successful, false if failed
function Chroma19032.ChromaConnect(params)
    local status, result = xpcall(VISAInstrument.VISAConnect, debug.traceback, params.name, params.identifier)
    if status and result then
        log.LogInfo("Chroma19032 Connect Pass")
        return true
    end
    log.LogError("Chroma19032 Connect Failed with : ", result)
    return false
end

-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias.
-- !param command string, command data sent to the instrument.
-- !@return result if successful, false if failed
function Chroma19032.ChromaQuery(params)
    local status, result = xpcall(VISAInstrument.VISAQuery, debug.traceback, params.name, params.command)
    if status and result then
        log.LogInfo("Chroma19032 Query Pass")
        return commonFunc.trim(result)
    end
    log.LogError("Chroma19032 Query Failed with : ", result)
    return false
end

-- !@brief Schooner csv API
-- !param name string, give the instrument a simple alias.
-- !param command string, command data sent to the instrument.
-- !@return true if successful, false if failed
function Chroma19032.ChromaWrite(params)
    local status, result = xpcall(VISAInstrument.VISAWrite, debug.traceback, params.name, params.command)
    if status and result then
        log.LogInfo("Chroma19032 Write Pass")
        return true
    end
    log.LogError("Chroma19032 Write Failed with : ", result)
    return false
end

-- !@brief Schooner csv API
-- !param name string, the alias for instrument.
-- !@return true if successful, false if failed.
function Chroma19032.ChromaClose(params)
    local status, result = xpcall(VISAInstrument.VISAClose, debug.traceback, params.name)
    if status and result then
        log.LogInfo("Chroma19032 Close Pass")
        return true
    end
    log.LogError("Chroma19032 Close Failed with : ", result)
    return false
end

-- !@brief Schooner csv API
-- !param name string, the alias for instrument.
-- !param command string, command data sent to the instrument.
-- !@return measure result if successful, false if failed
function Chroma19032.ChromaMeasure(params)
    local status, result = xpcall(VISAInstrument.VISAQuery, debug.traceback, params.name, params.command)
    if status and result then
        log.LogInfo("Chroma19032 Measure Pass")
        return commonFunc.convertToNumber(result)
    end
    log.LogError("Chroma19032 Measure Failed with : ", result)
    return false
end

-- !@brief Schooner csv API
-- !param name string, the alias for instrument.
-- !param command string, get step number command.
-- !param formatStr string, remove command format.
-- !@return true if successful, false if failed.
function Chroma19032.ChromaRemoveAllSetup(params)
    if params.formatStr == nil then
        log.LogError("formatStr is nil, please check input.")
        return false
    end

    local status, result = xpcall(VISAInstrument.VISAQuery, debug.traceback, params.name, params.command)
    if status then
        local stepNum = tonumber(result)
        -- Read all step configurations and remove one by one.
        if stepNum >= 1 then
            for i = 1, stepNum do
                local removeCommand = string.format(params.formatStr, i)
                status, result = xpcall(VISAInstrument.VISAWrite, debug.traceback, params.name, removeCommand)
                if not status then
                    break
                end
            end
        end
    end
    if status and result then
        log.LogInfo("Chroma19032 RemoveAllSetup Pass")
        return true
    end
    log.LogError("Chroma19032 RemoveAllSetup Failed with : ", result)
    return false
end

-- !@brief Schooner csv API
-- !param name string, the alias for instrument.
-- !param command string, get status command.
-- !param detect string, waitting string.
-- !param timeout number, the unit is seconds.
-- !@return true if successful, false if failed.
function Chroma19032.ChromaWait(params)
    local name = params.name
    local command = params.command
    local timeout = params.timeout
    local detectString = params.detectString
    if name == nil or command == nil or timeout == nil or detectString == nil then
        log.LogError("Invalid params input: name:" .. name .. " command:" .. command .. " timeout:" .. timeout ..
                         " detectString:" .. detectString)
        return false
    end

    local status, result
    local tag = Device.identifier .. "-" .. command .. "-" .. tostring(math.random(os.time()))
    Timer.tick(tag)
    while true do
        status, result = xpcall(VISAInstrument.VISAQuery, debug.traceback, name, command)
        if (Timer.tock(tag) >= timeout) then
            status = false
        end
        if not status or commonFunc.trim(result) == detectString then
            break
        end
    end
    if status and result then
        log.LogInfo("Chroma19032 Wait Pass")
        return true
    end
    log.LogError("Chroma19032 Wait Failed with : ", result)
    return false
end

local ActionHelper = require("SMTActionHelper")

local CSVInterfaceTable = {delegate = Chroma19032}

setmetatable(CSVInterfaceTable, ActionHelper.MetaTableFlowLogging)

return CSVInterfaceTable
