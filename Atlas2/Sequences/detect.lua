-- static detection with fake device URL and dummy resource.

function main()
    --!@ vendor fixture initialize
    local fixture = require("VendorProxy")
    if fixture and type(fixture.launcher) == "function" then
        fixture.launcher()
    end

    --!@ generate dummy device url for every slots defined in station configuration plist.
    --!@ generate dummy resource url named "dummy" for every group defined in station configuration plist.
    local deviceURLPrefix = 'uart://fake-path-'
    local resourceURLPrefix = 'uart://resource-group-'

    for _, group in ipairs(Detection.groups()) do
        for _, device in ipairs(Detection.slots()) do
            Detection.addDevice(deviceURLPrefix .. group .. '-' .. device)
        end
        Detection.addResource(resourceURLPrefix .. group)
    end

    local routingCallback = function(url)
        local pattern = '([0-9]+)%-(.+)$'
        local group_index, slot = string.match(url, pattern)
        group_index = tonumber(group_index)
        return slot, group_index
    end

    local resourceRoutingCallback = function(url)
        local pattern = '([0-9]+)$'
        local group_index = string.match(url, pattern)
        group_index = tonumber(group_index)
        return 'dummy', group_index
    end

    Detection.setExpectedResources({'dummy'})
    Detection.setDeviceRoutingCallback(routingCallback)
    Detection.setResourceRoutingCallback(resourceRoutingCallback)
end
