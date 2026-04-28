local VISAInstrument = {}
local log = require("Common/logging")
local comFunc = require("Common/Utilities")
VISAInstrument.DEFAULT_TIMEOUT = 3

-- local VisaremoteProcess = Remote.launchRemoteProcess("VisaInstrument", Remote.arch.arm64)
-- local Visaurl = VisaremoteProcess.remoteProcessUrl()
-- print(Visaurl)
-- local visa = Remote.loadRemotePlugin(Visaurl)

-----------------------------------VISAInstrument Driver-------------------------------------

-- VISAInstrument Lua API
-- instrID format: USB: 'GPIB0::10::INSTR' -- GPIBn:: / USBn::
-- instrID format: TCP: 'tcp://169.254.1.2:5025'
-- serial number: MY59026800

-- name: DMMA/DMMB/DMMC/ELOADA/ELOADB/POWERA etc.
-- identifier: tcp://169.254.1.33:5025 etc.
function VISAInstrument.VISAConnect(name, identifier)
    local instrID = nil
    -- local DeviceVariable = Device.getPlugin("VariableTable")
    if name == nil then
        error("name is nil, check params please.")
    end

    if identifier == nil then
        -- instrID = DeviceVariable.getVar(name)
        if instrID == nil then
            error("identifier is nil, please check params.")
        end
    else
        -- DeviceVariable.setVar(name, identifier)
        instrID = identifier
    end

    -- local patternUSB = "^(GPIB%d+::.*::INSTR)$"
    -- local patternGPIB = "^(USB%d+::.*::INSTR)$"
    local patternTCP = "^tcp://%d+%.%d+%.%d+%.%d+:%d+$"
    local patternUart = "^uart:///dev/cu.%w+%-%w+"
    if string.match(instrID, patternTCP) or string.find(instrID, patternUart) then
        local CommBuilder = Atlas.loadPlugin("CommBuilder")
        CommBuilder.setDelimiter("\n")
        local instrumentPath = Device.userDirectory .. "/instrument/"
        if not comFunc.fileExists(instrumentPath) then
            local runShellCmd = Device and Device.getPlugin("RunShellCommand") or Atlas.loadPlugin('RunShellCommand')
            runShellCmd.run("mkdir -p " .. instrumentPath)
        end
        local logFilePath = Device.userDirectory .. "/instrument/" .. name .. ".log"
        local rawLogFilePath = Device.userDirectory .. "/instrument/raw_" .. name .. ".log"
        CommBuilder.setLogFilePath(logFilePath, rawLogFilePath)
        VISAInstrument[name] = {}
        VISAInstrument[name]['instrument'] = CommBuilder.createCommPlugin(instrID)
        VISAInstrument[name]['isVisa'] = false
        if VISAInstrument[name]['instrument'].isOpened() ~= 1 then
            VISAInstrument[name]['instrument'].open()
        end
    else
        -- local deviceIDs = visa.listConnectedDevices()
        local visa = Atlas.loadPlugin("VisaInstrument")
        local matchedDeviceID = instrID
        VISAInstrument[name] = {}
        print(11111111111)
        print(matchedDeviceID)
        VISAInstrument[name]['instrument'] = visa.open(matchedDeviceID, { timeoutMs = 5000, readBytes = 8192, readUntil = "\n" })
        VISAInstrument[name]['isVisa'] = true
    end
    return true
end

function VISAInstrument.VISAQuery(name, command, timeout)
    if name == nil or command == nil then
        error("Invalid parameters input, name: " .. name .. " command:" .. command)
    end
    local ret = nil

    if VISAInstrument[name] == nil then
        VISAInstrument.VISAConnect(name)
    end

    if VISAInstrument[name]['isVisa'] then
        ret = VISAInstrument[name]['instrument'].queryCommand(command)
    else
        VISAInstrument[name]['instrument'].write(command)
        ret = VISAInstrument[name]['instrument'].read(timeout or VISAInstrument.DEFAULT_TIMEOUT)
    end
    return ret
end

function VISAInstrument.VISAWrite(name, command)
    if name == nil or command == nil then
        error("Invalid parameters input, name: " .. name .. " command:" .. command)
    end
    if VISAInstrument[name] == nil then
        VISAInstrument.VISAConnect(name)
    end

    if VISAInstrument[name]['isVisa'] then
        VISAInstrument[name]['instrument'].sendCommand(command)
    else
        VISAInstrument[name]['instrument'].write(command)
    end
    return true
end

function VISAInstrument.VISAClose(name)
    if name == nil then
        error("name is nil, please check the input.")
    end
    if VISAInstrument[name] == nil then
        return true
    end

    if VISAInstrument[name]['isVisa'] then
        VISAInstrument[name]['instrument'].disconnect()
    else
        VISAInstrument[name]['instrument'].close()
    end
    VISAInstrument[name] = nil
    return true
end

return VISAInstrument
