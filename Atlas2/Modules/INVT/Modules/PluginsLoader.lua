local PluginLoader = {}
local Log = require("Common/logging")
local CommonFunc = require "Common/Utilities"

local function pluginExists(pluginName)
    pluginName = tostring(pluginName)
    local BIBuildPath = '/usr/local/Atlas/Plugins/' .. pluginName .. '.l-dylib'
    local pluginsPath = string.gsub(Atlas.assetsPath, "Assets", "Plugins")
    local DRIPath = pluginsPath .. '/' .. pluginName .. '.l-dylib'
    if CommonFunc.fileExists(BIBuildPath) or CommonFunc.fileExists(DRIPath) then
        return true
    else
        Log.LogError("PluginLoader.pluginExists: plugin " .. pluginName ..
        " not exists in " .. BIBuildPath .. " or " .. DRIPath)
        error("PluginLoader.pluginExists: plugin " .. pluginName ..
        " not exists in " .. BIBuildPath .. " or " .. DRIPath)
    end
end

--! @brief get the plugin module if the file exist or have been created.
--! @param pluginName<string> the file name of dylib or the plugin name created by vendor.
--! @return pluginModule the plugin module if the file exist or have been created.
--! @usage PluginLoader.getPlugin("Regex")
function PluginLoader.getPlugin(pluginName)
    if pluginName == nil then
        Log.LogError("PluginLoader.getPlugin: pluginName is nil")
        error("PluginLoader.getPlugin: pluginName is nil")
    end
    local status, plugin
    if Device then
        status, plugin = xpcall(Device.getPlugin, debug.traceback, pluginName)
    end
    if not status and pluginExists(pluginName) then
        status, plugin = xpcall(Atlas.loadPlugin, debug.traceback, pluginName)
    end
    if status then
        return plugin
    else
        Log.LogError("PluginLoader.getPlugin: load plugin " .. pluginName .. " failed")
        error("PluginLoader.getPlugin: load plugin " .. pluginName .. " failed")
    end
end

--! @brief create the Utility plugin include Utilities TimeUtility USBUtility FileManipulationUtility MutexPlugin.
--! @param devicePluginsTable<table>: the devicePlugins table create in loadPlugins functions.
--! @return None.
--! @usage pluginsLoader.createUtilityPlugin(plugins)
function PluginLoader.createUtilityPlugin(devicePluginsTable)
    local helper = nil
    local status, ret = xpcall(require, debug.traceback, 'PluginHelper')
    if status then
        helper = ret
    end

    local Utilities = PluginLoader.getPlugin("Utilities")
    devicePluginsTable[(helper ~= nil and helper.getPluginIdentifier("Utilities")) or "Utilities"] = Utilities

    local SMTCommonPlugin = PluginLoader.getPlugin("SMTCommonPlugin")
    local time = SMTCommonPlugin.createTimeUtility()
    devicePluginsTable[(helper ~= nil and helper.getPluginIdentifier("TimeUtility")) or "TimeUtility"] = time

    local USBUtility = SMTCommonPlugin.createUSBUtility()
    devicePluginsTable[(helper ~= nil and helper.getPluginIdentifier("USBUtility")) or "USBUtility"] = USBUtility

    local FileManipulationUtility = SMTCommonPlugin.createFileManipulationUtility()
    devicePluginsTable[(helper ~= nil and helper.getPluginIdentifier("FileManipulationUtility")) or
        "FileManipulationUtility"] = FileManipulationUtility

    local MutexPlugin = PluginLoader.getPlugin("MutexPlugin")
    devicePluginsTable[(helper ~= nil and helper.getPluginIdentifier("MutexPlugin")) or "MutexPlugin"] = MutexPlugin

end

--! @brief create the RPC Client by using MIXRPCClientPlugin.
--! @param ip<string>: Format with 169.254.1.32, the ip address for mix server defined by mix config.json.
--! @param port<int>: Format with 7801, the port for mix server defined by mix config.json.
--! @return <lua plugin>: rpcClient to be created.
--! @usage pluginsLoader.createRPCClient("169.254.1.32", 7800 + tonumber(slot_num))
function PluginLoader.createRPCClient(ip, port)
    if string.match(tostring(ip), "^%d+%.%d*%.%d*%.%d+") == nil then
        ErrorFunction(ErrorCode.ParameterFormatErr)
    end
    if tonumber(port) == nil or #tostring(port) ~= 4 then
        ErrorFunction(ErrorCode.ParameterFormatErr)
    end
    local rpcClient
    pluginExists("MIXRPCClientPlugin")
    rpcClient = PluginLoader.getPlugin("MIXRPCClientPlugin")
    rpcClient.init(ip, port)
    if not rpcClient then
        Log.LogError("PluginLoader.createRPCClient: load plugin MIXRPCClientPlugin failed")
        error("PluginLoader.createRPCClient: load plugin MIXRPCClientPlugin failed")
    end
    return rpcClient
end

--! @brief create the EFS Client by using INVTMixEFS.
--! @param netInfo<string>: Format with /Modules/Tech/INVT/Modules/calibrationInfo.json, the netInfo for mix server defined by mix config.json.
--! @param ip<string>: Format with 169.254.1.32, the ip address for mix server defined by mix config.json.
--! @param port<int>: Format with 7801, the port for mix server defined by mix config.json.
--! @return <lua plugin>: efsClient to be created.
--! @usage pluginsLoader.createEFSClient(netInfo, "169.254.1.32", 7800 + tonumber(slot_num))
function PluginLoader.createEFSClient(netInfo, ip, port)
    if string.match(tostring(ip), "^%d+%.%d*%.%d*%.%d+") == nil then
        Log.LogError("PluginLoader.createEFSClient: ip " .. tostring(ip) .. " is invalid")
        error("PluginLoader.createEFSClient: ip " .. tostring(ip) .. " is invalid")
    end
    if tonumber(port) == nil or #tostring(port) ~= 4 then
        Log.LogError("PluginLoader.createEFSClient: port " .. tostring(port) .. " is invalid")
        error("PluginLoader.createEFSClient: port " .. tostring(port) .. " is invalid")
    end
    local efsClient
    pluginExists("INVTMixEFS")
    efsClient = PluginLoader.getPlugin("INVTMixEFS")
    efsClient.init(netInfo)
    efsClient.open(ip .. ":" .. tostring(port))
    if not efsClient then
        Log.LogError("PluginLoader.createEFSClient: load plugin INVTMixEFS failed")
        error("PluginLoader.createEFSClient: load plugin INVTMixEFS failed")
    end
    return efsClient
end

--! @brief create the EFS Client by using INVTMixEFS.
--! @param netInfo<string>: Format with /Modules/Tech/INVT/Modules/calibrationInfo.json, the netInfo for mix server defined by mix config.json.
--! @param rpcClient<lua plugin>: the rpcClient to be used.
--! @return <lua plugin>: efsClient to be created.
--! @usage pluginsLoader.createEFSClientByRPC(netInfo, plugins["rpcClient"])
function PluginLoader.createEFSClientByRPC(netInfo, rpcClient)
    local efsClient
    pluginExists("INVTMixEFS")
    efsClient = PluginLoader.getPlugin("INVTMixEFS")
    efsClient.init(netInfo)
    efsClient.setRpcPlugin(rpcClient)
    if not efsClient then
        Log.LogError("PluginLoader.createEFSClientByRPC: load plugin INVTMixEFS failed")
        error("PluginLoader.createEFSClientByRPC: load plugin INVTMixEFS failed")
    end
    return efsClient
end

--! @brief create the createEFIPlugin  by using CommBuilder.
--! @param url<string>: the EFIDUT url, like uart:///dev/cu.kis-14211000-ch-0.
--! @param logFilePath<string>: the log File save Path. e.g. logFilePath = workingDirectory .. "/kis.log"
--!                            also will create the raw log file with file prefix "raw_",
--!                            So path is: workingDirectory .. "/raw_kis.log"
--! @param isCreateDataChannel<bool>: if isCreateDataChannel == true then will Create a DataChannel by plugin ChannelBuilder
--! @param isCreateDataLogger<bool>: if isCreateDataLogger == true then will Create a CommLogger by plugin CommLoggerBuilder
--! @param isTrimNonAscii<bool>: if isTrimNonAscii == true then will trim all non-ascii characters
--! @param isActiveChannel<bool>: if isActiveChannel == true then will enable active mode
--! @return EFIDUT<lua plugin>:  plugin to be created.
--! @return channelPlugin<lua plugin>:  plugin to be created.
--! @return commLogger<lua plugin>:  plugin to be created.
--! @usage pluginsLoader.createDutCommunication(url, logFilePath, isCreateDataChannel, isCreateDataLogger, isTrimNonAscii, isActiveChannel)
function PluginLoader.createDutCommunication(url, logFilePath, isCreateDataChannel, isCreateDataLogger, isTrimNonAscii,
                                             isActiveChannel)
    pluginExists("CommBuilder")
    local CommBuilder = PluginLoader.getPlugin("CommBuilder")
    if isTrimNonAscii then
        local filterCharacters = {}
        table.insert(filterCharacters, string.format("%02x", 0))
        for i = 128, 255 do
            table.insert(filterCharacters, string.format("%02x", i))
        end
        CommBuilder.setReadFiltersHex(filterCharacters)
    end
    if isActiveChannel then
        CommBuilder.setActiveChannelOnOff(1)
    end
    local baseChannel = CommBuilder.createBaseChannel(url)
    if string.match(logFilePath, "(.*/)[^/]*") then
        local rawLogFilePath = string.match(logFilePath, "(.*/)[^/]*") .. "raw_" ..
                                   string.match(logFilePath, ".*/([^/]*)")
        CommBuilder.setLogFilePath(logFilePath, rawLogFilePath)
    end

    local commLogger = nil
    if isCreateDataLogger then
        commLogger = CommBuilder.createCommLoggerPlugin(url)
    end

    local channel = nil
    if isCreateDataChannel then
        pluginExists("SMTDataChannel")
        local channelBuilder = PluginLoader.getPlugin("SMTDataChannel")
        local channelPlugin = channelBuilder.createChannelPlugin()
        local channelLogFilePath = string.match(logFilePath, "(.*/)[^/]*") .. "base_" ..
                                       string.match(logFilePath, ".*/([^/]*)")
        channelPlugin.setLogFilePath(channelLogFilePath)
        channelPlugin.setLegacyLogMode(1)
        channel = channelPlugin.createDataChannel(baseChannel)
        local EFIdut = CommBuilder.createEFIPlugin(channel)
        return EFIdut, channelPlugin, commLogger
    end

    local EFIdut = CommBuilder.createEFIPlugin(baseChannel)
    return EFIdut, channel, commLogger
end

--! @brief create the createCommPlugin  by using CommBuilder.
--! @param url<string>: the Comm url, like uart:///dev/cu.usbserial-DUT0.
--! @param logFilePath<string>: the log File save Path. e.g. logFilePath = workingDirectory .. "/dut.log"
--!                             also will create the raw log file with file prefix "raw_",
--!                             So path is: workingDirectory .. "/raw_dut.log"
--! @param isCreateDataChannel<bool>: if isCreateDataChannel == true then will Create a DataChannel by plugin ChannelBuilder
--! @return Comm<lua plugin>:  plugin to be created.
--! @return channel<lua plugin>: if isCreateDataChannel == true, will return the DataChannel lua plugin.
--! @usage pluginsLoader.createComm(dutUartPath_AP, workingDirectory .. "/dut.log", true)
function PluginLoader.createComm(url, logFilePath, isCreateDataChannel)
    if string.match(url, "visa://") then
        return PluginLoader.createVisa(url, logFilePath)
    end
    pluginExists("CommBuilder")
    local CommBuilder = PluginLoader.getPlugin("CommBuilder")
    CommBuilder.setDelimiter("\n")
    local baseChannel = CommBuilder.createBaseChannel(url)
    if string.match(logFilePath, "(.*/)[^/]*") then
        local rawLogFilePath = string.match(logFilePath, "(.*/)[^/]*") .. "raw_" ..
                                   string.match(logFilePath, ".*/([^/]*)")
        CommBuilder.setLogFilePath(logFilePath, rawLogFilePath)
    end
    local channel = nil
    if isCreateDataChannel then
        pluginExists("SMTDataChannel")
        local channelBuilder = PluginLoader.getPlugin("SMTDataChannel")
        local channelPlugin = channelBuilder.createChannelPlugin()
        channel = channelPlugin.createDataChannel(baseChannel)
    end
    local Comm = CommBuilder.createCommPlugin(channel or baseChannel)
    return Comm, channel
end

--! @brief create the visaPlugin  by using Visa.l-dylib.
--! @param url<string>: the Visa url, like visa://GPIB::20::INSTR visa://USB0::0x0957::0x2607::MY52202565::INSTR
--! @param logFilePath<string>: the log File save Path. e.g. logFilePath = workingDirectory .. "/visa_gpib.log"
--! @return CommVisa<lua plugin>:  plugin to be created.
--! @usage pluginsLoader.createVisa('visa://GPIB::20::INSTR', workingDirectory .. "/visa_gpib.log")
function PluginLoader.createVisa(url, logFilePath)
    pluginExists("Visa")
    local CommVisa = PluginLoader.getPlugin("Visa")
    local strAdrr = string.match(url, "visa://(.*)")
    CommVisa.createVisa(strAdrr, logFilePath)
    return CommVisa
end

--! @brief create the CommLogger  by using CommBuilder.
--! @param url<string>: the Comm url, like tcp://169.254.1.10:7801.
--! @param logFilePath<string>: the log File save Path. e.g. logFilePath = workingDirectory .. "/dut.log"
--!                            also will create the raw log file with file prefix "raw_",
--!                            So path is: workingDirectory .. "/raw_dut.log"
--! @param isCreateDataChannel<bool>: if isCreateDataChannel == true then will Create a DataChannel by plugin ChannelBuilder
--! @return CommLogger<lua plugin>:  plugin to be created.
--! @return channel<lua plugin>: if isCreateDataChannel == true, will return the DataChannel lua plugin.
--! @usage pluginsLoader.createCommLogger(dutUartPath_AP, workingDirectory .. "/dut.log", false)
function PluginLoader.createCommLogger(url, logFilePath, isCreateDataChannel)
    pluginExists("CommBuilder")
    local CommBuilder = PluginLoader.getPlugin("CommBuilder")
    CommBuilder.setDelimiter("\n")
    if string.match(logFilePath, "(.*/)[^/]*") then
        local rawLogFilePath = string.match(logFilePath, "(.*/)[^/]*") .. "raw_" ..
                                   string.match(logFilePath, ".*/([^/]*)")
        CommBuilder.setLogFilePath(logFilePath, rawLogFilePath)
    end
    local channel = nil
    if isCreateDataChannel then
        pluginExists("SMTDataChannel")
        local channelBuilder = PluginLoader.getPlugin("SMTDataChannel")
        local channelPlugin = channelBuilder.createChannelPlugin()
        channel = channelPlugin.createDataChannel(url)
    end
    local CommLogger = CommBuilder.createCommLoggerPlugin(channel or url)
    return CommLogger, channel
end

--! @brief create the plugin MDParser.
--! @param parseDefinitionsPath<string>: the folder path of parseDefinitions. if don't have this args will use the
--!                                      path of Atlas.assetsPath .. "/parseDefinitions"
--! @return <lua plugin>: MDParser plugin to be created.
--! @usage pluginsLoader.createMDParser() -- using path Atlas.assetsPath .. "/parseDefinitions"
function PluginLoader.createMDParser(parseDefinitionsPath)
    pluginExists("MDParser")
    local MDParser = PluginLoader.getPlugin("MDParser")
    local parseDefinitions = parseDefinitionsPath or Atlas.assetsPath .. "/parseDefinitions"
    MDParser.init(parseDefinitions)
    return MDParser
end

--! @brief create the plugin by pluginName.
--! @param pluginName<string>: the plugin Name to be create.
--! @return <lua plugin>: the plugin to be created with pluginName.
--! @usage pluginsLoader.createPluginByName("fixture")
function PluginLoader.createPluginByName(pluginName)
    if not pluginName then
        Log.LogError("PluginLoader.createPluginByName: pluginName is empty")
        error("PluginLoader.createPluginByName: pluginName is empty")
    end
    pluginExists(pluginName)
    local plugin = PluginLoader.getPlugin(pluginName)
    return plugin
end

--! @brief create the plugin INVTPowerSequence.
--! @param rpcIP<string>: channel connect Xavier rpc ip.
--! @param rpcPort<number>: channel connect Xavier rpc port.
--! @param upStreamingIP<string>: local pc network ip connect to Xavier.
--! @param upStreamingPort<number>: no used port for receive data , set yourself.
--! @return <bool>: true.false.
--! @usage pluginsLoader.createPowerSequence("169.254.1.32", 7801)
function PluginLoader.createPowerSequence(rpcIP, rpcPort, upStreamingIP, upStreamingPort)
    local plugin = PluginLoader.getPlugin("INVTPowerSequence")
    if string.match(tostring(rpcIP), "^%d+%.%d*%.%d*%.%d+") == nil then
        Log.LogError("PluginLoader.createPowerSequence: load PowerSequence rpc with an error ip:" .. tostring(rpcIP))
        error("PluginLoader.createPowerSequence: load PowerSequence rpc with an error ip:" .. tostring(rpcIP))
    end
    if tonumber(rpcPort) == nil or #tostring(rpcPort) ~= 4 then
        Log.LogError("PluginLoader.createPowerSequence: load PowerSequence rpc with an error port:" .. tostring(rpcPort))
        error("PluginLoader.createPowerSequence: load PowerSequence rpc with an error port:" .. tostring(rpcPort))
    end
    local ret
    if upStreamingIP == nil or upStreamingPort == nil then
        ret = plugin.createDatalogger(rpcIP, rpcPort)
    else
        if string.match(tostring(upStreamingIP), "^%d+%.%d*%.%d*%.%d+") == nil then
            Log.LogError("PluginLoader.createPowerSequence: load PowerSequence streaming with an error ip:" ..
                          tostring(upStreamingIP))
            error("PluginLoader.createPowerSequence: load PowerSequence streaming with an error ip:" ..
                      tostring(upStreamingIP))
        end
        if tonumber(upStreamingPort) == nil then
            Log.LogError("PluginLoader.createPowerSequence: load PowerSequence streaming with an error port:" ..
                          tostring(upStreamingPort))
            error("PluginLoader.createPowerSequence: load PowerSequence streaming with an error port:" ..
                      tostring(upStreamingPort))
        end
        ret = plugin.createDatalogger(rpcIP, rpcPort, upStreamingIP, upStreamingPort)
    end
    if not ret then
        Log.LogError("PluginLoader.createPowerSequence: create PowerSequence fail")
        error("PluginLoader.createPowerSequence: create PowerSequence fail")
    end
    return plugin
end

--! @brief create the plugin VirtualPort.
--! @param deviceName<string>: device name.
--! @param apUartUrl<string>: the path of virtualPort. format such as string.format("uart:///tmp/dev/DUT1%s",
--!                             (tonumber(slot_num)))
--! @param vtMetaUrl<string>: the url of mix, format such as "xav://ip:port:uart",
--!                             "uart" is the class name of uart in profile.json in mix,
--!                             example:"xav://169.254.1.35:7801:spam_uart".
--! @return None.
--! @usage pluginsLoader.createVirtualPort(device,vp_url, virtualport)
function PluginLoader.createVirtualPort(deviceName, apUartUrl, vtMetaUrl)
    local virtualPort = PluginLoader.getPlugin("VirtualPort")
    local slotID = string.match(deviceName, "slot(%d)")
    local groupIndex = string.match(deviceName, "G=(%d):")
    local groupID = "group" .. tostring(groupIndex)
    local topology = {
        groups = {
            {
                identifier = groupID,
                units = {
                    {identifier = slotID, unit_transports = {{url = apUartUrl, metadata = {virtualport = vtMetaUrl}}}}
                }
            }
        }
    }
    virtualPort.setup({
        group_id = groupID,
        unit_id = slotID,
        topology = topology,
        loggingfolder = Group.getDeviceUserDirectory(deviceName)
    })
    return virtualPort
end

return PluginLoader
