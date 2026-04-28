-------------------------------------------------------------------
----***************************************************************
---- Schooner Device Functions
----***************************************************************
-------------------------------------------------------------------

local DeviceFunctions = {}

local comFunc = require("Common/Utilities")
local Log = require("Common/logging")
local constants = require("VendorProxy").getConstants()

--! @brief setup device plugins
function DeviceFunctions.setup(deviceName, groupPlugins)
    Log.LogInfo("------>> DeviceFunctions setup <<------")

    local plugins = {}
    --!@ get fixture from VendorProxy
    local fixture = require("VendorProxy")

    --!@ base plugins
    local utility = Atlas.loadPlugin("SMTCommonPlugin")
    plugins["SMTCommonPlugin"] = utility
    plugins["TimeUtility"] = utility.createTimeUtility()
    plugins["FileOperation"] = utility.createFileManipulationUtility()
    plugins['Regex'] = Atlas.loadPlugin("Regex")
    plugins['SFC'] = Atlas.loadPlugin("SFC")
    plugins['Utilities'] = Atlas.loadPlugin("Utilities")
    plugins['StationInfo'] = Atlas.loadPlugin("StationInfo")
    plugins['RunShellCommand'] = Atlas.loadPlugin("RunShellCommand")
    plugins["PListSerializationPlugin"] = Atlas.loadPlugin("PListSerializationPlugin")
    plugins['JSONSerializationPlugin'] = Atlas.loadPlugin("JSONSerializationPlugin")
    local variableTab = Atlas.loadPlugin("VariableTable")
    variableTab.init()
    plugins["AttributeKeyTable"] = variableTab

    --!@ loading vendor plugins
    local vendorPluginTable = fixture.loadDevicePlugins(deviceName, groupPlugins)
    for pluginname, plugin in pairs(vendorPluginTable) do
        plugins[pluginname] = plugin
    end

    --!@ unmanage plugins table
    local unmanagePluginsTable = {}
    if constants.NEED_PARALLEL_TEST then
        for devicePluginName, _ in pairs(plugins) do
            table.insert(unmanagePluginsTable, devicePluginName)
        end
        for groupPluginName, _ in pairs(groupPlugins) do
            table.insert(unmanagePluginsTable, groupPluginName)
        end
    end

    if unmanagePluginsTable and type(unmanagePluginsTable) ~= "table" then
        error("wrong type of unmanagePluginsTable, please check !")
    end

    return plugins, unmanagePluginsTable
end

--! @brief teardown device plugins
function DeviceFunctions.teardown(deviceName, plugins)
    Log.LogInfo("------>> DeviceFunctions teardown <<------")

    -- shutdown vendor unique DUT level plugins
    local fixture = require("VendorProxy")
    if fixture.shutdownDevicePlugins then
        fixture.shutdownDevicePlugins(deviceName, plugins)
    end

end

return DeviceFunctions
