local groupFT = {}

-- Default empty implementation if no resourceURLs found
groupFT.setup = function (resourceURLs)
    if (resourceURLs ~= nil and next(resourceURLs) ~= nil) then
        error("You must implement groupFunctionTable.setup(resourceURLs)")
    end
    return {}
end

groupFT.getSlots = function (groupPluginTable, interarrivalTimeout, globalTimeout)
    return Group.getSlots(interarrivalTimeout, globalTimeout)
end

-- Default empty implementation
groupFT.start = function (groupPluginTable)
end

-- Default empty implementation
groupFT.stop = function (groupPluginTable)
end

-- Default implementation should return false so that it doesnt loop per detection
groupFT.loopAgain = function (groupPluginTable)
    return false
end

-- Default implementation should return false so that Atlas2 doesn't keep relaunching fresh group process
groupFT.groupShouldExit = function (groupPluginTable)
    return false
end

-- Default empty implementation if no group plugins
groupFT.teardown = function (groupPluginTable)
    if (groupPluginTable ~= nil and next(groupPluginTable) ~= nil) then
        error("Implement groupFunctionTable.teardown(groupPluginTable) to teardown plugins from groupFunctionTable.setup(...)")
    end
end

return groupFT
