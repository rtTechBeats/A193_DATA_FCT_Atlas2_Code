local pipeline = {}

local helpers = require "GroupStateMachine/GSMHelpers"
local dump = helpers.dump

pipeline.pipelineSlots = nil
pipeline.pipelineLocationNames = nil

pipeline.setPipelineSlots = function(pipelineSlots)
    pipeline.pipelineSlots = pipelineSlots
end

pipeline.getPipelineSlots = function()
    return pipeline.pipelineSlots
end

pipeline.setPipelineLocationNames = function(pipelineLocationNames)
    pipeline.pipelineLocationNames = pipelineLocationNames
end

pipeline.getPipelineLocationNames = function()
    return pipeline.pipelineLocationNames
end

-- Initialize pipeline devices that were just inserted into the load area
pipeline.initPipelineDevices = function(devicesStarted)
    -- update slot info
    for device, slot in pairs(devicesStarted) do
        print('updating info for started device: '..device..slot)
        pipeline.pipelineSlots[slot].deviceName = device
        pipeline.pipelineSlots[slot].inTest = true
        -- the 1st phase
        pipeline.pipelineSlots[slot].phase = '1'
    end
end

-- Schedule coverage for pipeline devices
pipeline.scheduleCoverage = function(devicesStarted, mergedPluginTable, pluginNamesToUnmanageTable, deviceFT, saveDAG)
    for device in pairs(devicesStarted) do
        print('scheduling coverage for device '..device)
        local plugins = mergedPluginTable[device]
        local dag = Group.scheduler(device, plugins)
        print('dag for device '..device..': '..tostring(dag))
        -- unamange plugin specified by user
        local pluginNamesToUnmanage = pluginNamesToUnmanageTable[device]
        if pluginNamesToUnmanage then
            for _, name in ipairs(pluginNamesToUnmanage) do
                dag.unmanage(name)
            end
        end

        print("GroupStateMachinePipeline : scheduleDAG for device = " .. device)
        -- Shark TODO: iter and prevDAGResult should be useless here;
        -- does it worth keeping the same interface so Schooner/other consumer could possible reuse code
        -- between pipeline and none pipeline station?
        -- Shark: shall we capture any error here and fail device if any?
        local isDAGScheduled = deviceFT.scheduleDAG(2, dag, device, plugins)

        print("GroupStateMachinePipeline : scheduleDAG for device = " .. device.. ", return = ".. tostring(isDAGScheduled))
        if saveDAG then print("GroupStateMachinePipeline : Saving DAG output to file.") Group.saveDAGToFile()
        end
    end
end

-- Return device name.  The naming pattern is consistent with how all devices are named within GSM.
pipeline.slotToDeviceName = function(slot)
    return "G=" .. Group.index .. ":S=" .. slot
end


pipeline.excludeErroredDevice = function(pipelineMeta)
    local runningDevices = {}
    -- convert to key-value table for check existence
    for _, device in ipairs(Group.runnable()) do
        runningDevices[device] = true
    end

    for _, slot in ipairs(pipelineMeta.slotArray) do
        local setting = pipeline.pipelineSlots[slot]
        if setting.inTest then
            local deviceName = pipeline.slotToDeviceName(slot)
            if not runningDevices[deviceName] then
                print('Device ' .. tostring(deviceName) .. ' is not runnable; maybe errored out in phase '.. setting.phase .. '; excluded from setting next phase.')
                setting.inTest = false
            end
        end
    end
end

-- Generate waiting list for given slots or all running slots
-- If argument slots is nil then the slotArray, which contains all slots, is used
pipeline.generateNextPhase = function(pipelineMeta, slots)
    if slots == nil then slots = pipelineMeta.slotArray end
    local checkpoints = {}
    for _, slot in ipairs(slots) do
        local setting = pipeline.pipelineSlots[slot]
        if setting.inTest then
            checkpoints[pipeline.slotToDeviceName(slot)] = setting.phase
        end
    end
    return checkpoints
end

pipeline.advancePhase = function(pipelineMeta, locationToFinish)
    for slot, setting in pairs(pipeline.pipelineSlots) do
        -- 1 based
        setting.location = setting.location % pipelineMeta.nLocation + 1
        local lastTestLocation = pipelineMeta.nLocation
        if locationToFinish ~= 1 then
            lastTestLocation = pipelineMeta.nLocation - 1
        end

        if setting.location == lastTestLocation then
            setting.phase = Group.phase.complete
        else
            setting.phase = tostring(setting.location)
        end
    end
end

pipeline.devicesAtLocation = function(pipelineMeta, location)
    assert(location, 'location cannot be nil; expecting positive number or string')
    assert(pipeline.pipelineSlots, 'pipeline station slots mapping not specified')
    -- convert to location index
    if type(location) == 'string' then
        location = pipeline.pipelineLocationNames[location]
    end

    -- 1 based
    if location < 0 then location = pipelineMeta.nLocation + 1 + location end

    local ret = {}
    for slot, setting in pairs(pipeline.pipelineSlots) do
        if setting.location == location and setting.deviceName then
            table.insert(ret, setting.deviceName)
        end
    end

    return ret
end

pipeline.cleanupDevices = function(devicesToFinish)
    for _, device in ipairs(devicesToFinish) do
        for slot, setting in pairs(pipeline.pipelineSlots) do
            if setting.deviceName == device then
                setting.inTest = false
                setting.deviceName = nil
                break
            end
        end
    end
end

pipeline.separateSlotNameAndSN = function(slots)
    local ret = {}
    local SN = {}
    for key, value in pairs(slots) do
        local slot = nil
        if type(key) == 'number' then
            slot = value
        else
            assert(type(key) == 'string',
                   'Invalid return from GroupFT.getSlots(); ' ..
                   'slot should be string, while get '..tostring(key))
            slot = key
            -- value is SN
            SN[slot] = value
        end
        table.insert(ret, slot)

    end
    return ret, SN
end

return pipeline
