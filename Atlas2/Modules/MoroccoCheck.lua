local MoroccoCheck = {}
local Log = require("Common/logging")

-- ! @brief MIX integrity init
-- ! @param param: table type
-- ! @return true or false
-- ! e.g. integrityCheckInit(param) => "true"
function MoroccoCheck.integrityCheckInit(param)
    Log.LogInfo("MoroccoCheck, integrityCheckInit-------")
    local mixrpc = Device.getPlugin("MIXRPCRelay")
    local slotIP = param.ip
    local serverEndpoint = "tcp://" .. slotIP .. ":50000"
    local mixFilePath = "/Users/gdlocal/Library/Atlas2/MIX" -- FW package, which is a .mixbundle type file
    local mixbundlePath = nil
    local handle = io.popen("ls " .. mixFilePath)
    local result = handle:read("*a")
    handle:close()

    for fileName in string.gmatch(result, "[^\n]+") do
        Log.LogInfo("fileName : ", fileName)
        mixbundlePath = mixFilePath .. "/" .. fileName
    end

    Log.LogInfo("MoroccoCheck, integrityCheckInit----  serverEndpoint :", serverEndpoint, "mixbundlePath : ",
                mixbundlePath)

    if not (serverEndpoint or mixbundlePath) then
        return false
    end

    local __inner = function()
        local ret = mixrpc.integrityCheckInit(serverEndpoint, mixbundlePath)
        return ret
    end
    local status, result = pcall(__inner)
    Log.LogInfo("MoroccoCheck, integrityCheckInit----  status=", status, "result=", result)
    if status then
        return true, result
    else
        return false, result
    end
end

-- ! @brief MIX integrity check
-- ! @param param: table type
-- ! @return true or false
-- ! e.g. configCheck({}) => "true"
function MoroccoCheck.integrityCheck(param)
    Log.LogInfo("MoroccoCheck, integrityCheck-------")
    local mixrpc = Device.getPlugin("MIXRPCRelay")

    local __inner = function()
        local ret = mixrpc.integrityCheck()
        return ret
    end
    local status, result = pcall(__inner)
    Log.LogInfo("MoroccoCheck, integrityCheck----  status=", status, "result=", result)

    if status then
        return true, result
    else
        return false, result
    end
end

-- ! @brief MIX HW config check
-- ! @param param: table type
-- ! @return true or false
-- ! e.g. configCheck({}) => "true"
function MoroccoCheck.configCheck(param)
    Log.LogInfo("MoroccoCheck, configCheck-------")
    local mixrpc = Device.getPlugin("MIXRPCRelay")
    local slotIP = param.ip
    local serverEndpoint = "tcp://" .. slotIP .. ":50000"

    Log.LogInfo("MoroccoCheck, configCheck----  serverEndpoint :", serverEndpoint)

    if not serverEndpoint then
        return false
    end

    local __inner = function()
        local ret = mixrpc.configCheck(serverEndpoint)
        return ret
    end
    local status, result = pcall(__inner)
    Log.LogInfo("MoroccoCheck, configCheck----  status=", status, "result=", result)
    if status then
        return true, result
    else
        return false, result
    end
end

-- ! @brief MIX HW configBless
-- ! @param param: table type
-- ! @return true or false
-- ! e.g. configCheck({}) => "true"
function MoroccoCheck.configBless(param)
    Log.LogInfo("MoroccoCheck, configBless-------")
    local mixrpc = Device.getPlugin("MIXRPCRelay")
    local slotIP = param.ip
    local serverEndpoint = "tcp://" .. slotIP .. ":50000"

    Log.LogInfo("MoroccoCheck, configBless----  serverEndpoint :", serverEndpoint)

    if not serverEndpoint then
        return false
    end

    local __inner = function()
        local ret = mixrpc.configBless(serverEndpoint)
        return ret
    end
    local status, result = pcall(__inner)
    Log.LogInfo("MoroccoCheck, configBless----  status=", status, "result=", result)

    if status then
        return true, result
    else
        return false, result
    end
end

-- function alias
-- !@brief Matchbox CSV API
local ActionHelper = require("SMTActionHelper")

local CSVInterfaceTable = {delegate = MoroccoCheck}

setmetatable(CSVInterfaceTable, ActionHelper.MetaTableFlowLogging)

return CSVInterfaceTable
