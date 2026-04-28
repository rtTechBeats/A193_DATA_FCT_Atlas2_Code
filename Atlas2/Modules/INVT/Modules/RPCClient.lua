local RPCClient = {}
local LogHelper = require("Common/logging")
local CommonFunc = require("Common/Utilities")
local PluginsLoader = require("INVT/Modules/PluginsLoader")
RPCClient.rpcClient = PluginsLoader.getPlugin("MixRPC")

--[[
Description:
    Send Rpc Command.

Params:
    mixFunction<string>: the rpc command.
    args<table>: the rpc command args.
    kwargs<dictionary>: the rpc command kwargs.
    timeout<int><option>: the rpc send command timeout with unit ms, default is 3000 ms.
    rpcClientObj<obj><option>: the rpcClient plugin object,
    ally DRI need named the plugin object as rpcClient, So you can skip set the parameter.

Returns:
    <string>: rpc response.

Usage:
	local RpcClient = require('Tech/INVT/Modules/RpcClient')
    local response = RpcClient.callRPCFunc('server.mode',{},{},3000)

--]]
function RPCClient.callRPCFunc(mixFunction, rpcArgs, timeout)
    local rpcClient = RPCClient.rpcClient
    local args = rpcArgs or {}
    local kwargs = {}
    kwargs['timeout_ms'] = tonumber(timeout) and tonumber(timeout) * 1000 or 3000

    LogHelper.LogFixtureControlStart(mixFunction, CommonFunc.dump(args), CommonFunc.dump(kwargs))

    local response = rpcClient.rpc(mixFunction, args, kwargs)

    LogHelper.LogFixtureControlFinish(CommonFunc.dump(response))

    return response
end

--[[
Description:
    get the mix_rpc_client_framework version in local path of /AppleInternal/Library/Frameworks/.
Params:
    None.

Returns:
    <String>: FrameworkVersion will return 7.0 or 8.0.

Usage:
	local RpcClient = require('Tech/INVT/Modules/RpcClient')
    local mixVersion = RpcClient.getMIXFrameworkVersion()

--]]
function RPCClient.getMIXFrameworkVersion()
    local frameworkModulesPath =
        '/AppleInternal/Library/Frameworks/mix_rpc_client_framework.framework/Modules/module.modulemap'
    if CommonFunc.fileExists(frameworkModulesPath) then
        return '7.0'
    else
        return '8.0'
    end
end

return RPCClient
