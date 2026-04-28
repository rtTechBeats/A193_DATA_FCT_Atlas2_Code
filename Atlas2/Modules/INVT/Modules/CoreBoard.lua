local Mutex = require("mutex")
local Json = require("Common/json")
local Helper = require("INVT/Modules/SMTLoggingHelper")
local ComFunc = require("Common/Utilities")
local PluginsLoader = require("INVT/Modules/PluginsLoader")

local M = {}
M.rpcClient = PluginsLoader.getPlugin("CoreBoard")


-- @Description: create requests string
-- @param cmd: string
-- @param rpcArgs: table
-- return: string
function M.createRequest(cmd, rpcArgs, rpcKwargs)
    local cmdTab = {}
    cmdTab["jsonrpc"] = "2.0"
    cmdTab["id"] = Mutex.uuid()
    cmdTab["method"] = cmd
    if rpcArgs ~= nil and #rpcArgs > 0 then
        cmdTab["args"] = rpcArgs
    end
    if rpcKwargs ~= nil and #rpcKwargs > 0 then
        cmdTab["kwags"] = rpcKwargs
    end
    return Json.encode(cmdTab).."\r\n"
end

-- @Description: call or execute CoreBoard function and get return value
-- @param cmd: string
-- @param rpcArgs: table
-- @param rpcKwargs: default nil
-- @param timeout: number type, get it from csv
-- return: string
function M.callRPCFunc(cmd, rpcArgs, rpcKwargs, timeout)
    local rpcClient = M.rpcClient
    assert(rpcClient ~= nil, "RPC Client not init")
    local rpcArgs = rpcArgs
    local rpcKwargs = rpcKwargs
    local timeout = timeout and timeout / 1000 or 3 -- unit second
    local cmdString = M.createRequest(cmd, rpcArgs, rpcKwargs)
    if rpcClient.isOpened() ~= 1 then
        rpcClient.open()
    end
    Helper.LogFixtureControlStart(cmd, ComFunc.dump(rpcArgs), timeout)
    local status, response = pcall(rpcClient.send, cmdString, timeout)
    Helper.LogFixtureControlFinish(ComFunc.dump(response))
    if rpcClient.isOpened() == 1 then
        rpcClient.close()
    end
    if not status then
        error("send command fail!")
    end
    local retTab = Json.decode(response)
    local result = retTab["result"]

    if result == nil and retTab["error"] ~= nil then
        error(retTab["error"]["message"])
    end

    return result
end

return M