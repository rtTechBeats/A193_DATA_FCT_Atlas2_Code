local deviceFT = {}

-- Default implementation to error out since this is required
deviceFT.setup = function (deviceName, groupPluginTable)
    error("You must implement deviceFunctionTable.setup(deviceName, groupPluginTable)")
end

-- Default empty implementation if no device plugins
deviceFT.teardown = function (deviceName, devicePluginTable)
    if (devicePluginTable ~= nil and next(devicePluginTable) ~= nil) then
        error("Implement deviceFunctionTable.teardown(deviceName, devicePluginTable) to teardown plugins from deviceFunctionTable.setup(...)")
    end
end

-- Default implementation to error out since this is required
deviceFT.scheduleDAG = function(iter, dag, deviceName, plugins, prevDAGResults)
    error("You must implement deviceFunctionTable.scheduleDAG(iter, dag, deviceName, plugins, prevDAGResults)")
end

-- Default no-op with a logging
deviceFT.scheduleFinalDAG = function(dag, deviceName, plugins)
    print("no any final action is scheduled for finalDAG")
end

return deviceFT
