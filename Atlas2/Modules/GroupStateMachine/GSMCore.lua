local function truncateFailureMsg(failureMsg)
    return string.sub(failureMsg, 1, 510)
end

local function table_override(source, target, keys)
    -- early exit if source is nil
    if source == nil then return end
    -- loop over all keys and override source to target
    for _, keyName in ipairs(keys) do
        if source[keyName] ~= nil then
            target[keyName] = source[keyName]
        end
    end
end

local GSMConfiguration = require "GroupStateMachine/GSMConfiguration"
local helpers       = require "GroupStateMachine/GSMHelpers"
local common        = require "GroupStateMachine/GSMCommon"

local try = helpers.try
local dump = helpers.dump

-- Main Module
local GSMCore = {}

-- GSM Pipeline Module
local gsmPipeline = require "GroupStateMachine/GSMPipeline"

-- Function Tables
local gsmFT = require "GroupStateMachine/GSMFunctionTable"
local groupFT = require "GroupStateMachine/GSMDefaultGroupFT"
local deviceFT = require "GroupStateMachine/GSMDefaultDeviceFT"

-- Plugin Tables
local groupPluginTable = {}
local devicePluginTable = {}

-- Internal GSM properties
local detectionTimeout = { -1, -1 }
local readyForAutomatedHandlingCallback = nil
local automationFixtureControlCallbacks = nil
local resourcesEnabled = true
local saveDAG = false
local registeredStationType = common.STATION_TYPE_UNSET

-- store slots location/phase/inTest or not for pipeline station
local pipelineMeta = {
    slotArray = {},
    nLocation = 0,
}
local locationToFinish

-- restrict that a table error out when getting non existing key
local function setStrict(t)
    setmetatable(t, {
        __index = function(_, k)
            error('Key ' .. tostring(k) ..
            ' does not exist; typo or undefined?')
        end
    })
end

-- function for pipeline to get slots on certain stage
GSMCore.slotsAtLocation = function(location)
    assert(location, 'location cannot be nil; expecting positive number or string')
    local pipelineSlots = gsmPipeline.getPipelineSlots()
    assert(pipelineSlots, 'pipeline station slots mapping not specified')
    -- convert to location index
    if type(location) == 'string' then
        local pipelineLocationNames = gsmPipeline.getPipelineLocationNames()
        location = pipelineLocationNames[location]
    end

    -- 1 based
    if location < 0 then location = pipelineMeta.nLocation + 1 + location end

    local ret = {}
    for slot, setting in pairs(pipelineSlots) do
        if setting.location == location then
            table.insert(ret, slot)
        end
    end

    return ret
end

for k, v in pairs(GSMConfiguration) do
    if not string.match(k, "^__") then GSMCore[k] = v end
end

-- Fail and stop device when an error occurs
local function groupStateMachineTestMainFailAndStopDevice(err)
    print("Software error was caught: " .. err)
    for _, device in ipairs(Group.allDevices()) do
        print(device .. ": Failing for software exception : " .. err)
        Group.failDevice(device, 'Software error was caught; check device.log for details.')
        Group.stopDevice(device)
    end
end

local function overridePipelineStationGroupFunctions(groupFT, deviceFT, registeredInfo)
    -- Shark: Do not support loopAgain for the moment since it is not clear how to do that
    -- Shark: Group.shouldExitFunction() really doesn't work because pipeline gsm runs in a while loop?
    -- Shark: Group.teardown() really doens't work because it will never get called
    table_override(registeredInfo[GSMConfiguration.__groupFunctionTableKey ], groupFT, {"setup", "getSlots", "advancePhase", "finishAdvancePhase"})
    -- Shark: there is no final DAG in pipeline for the moment.
    table_override(registeredInfo[GSMConfiguration.__deviceFunctionTableKey], deviceFT, {"setup", "scheduleDAG", "teardown"})
end

local function overrideNormalStationGroupFunctions(groupFT, deviceFT, registeredInfo)
    table_override(registeredInfo[GSMConfiguration.__groupFunctionTableKey ], groupFT, {"setup", "getSlots", "start", "stop", "loopAgain", "groupShouldExit", "teardown"})
    table_override(registeredInfo[GSMConfiguration.__deviceFunctionTableKey], deviceFT, {"setup", "scheduleDAG", "scheduleFinalDAG", "teardown"})
end

-- Sanity check on the registered station type
local function validateStationType(registeredStationType)
    if type(registeredStationType) ~= "number" then
        error("GroupStateMachine: Station Type is a non-numerical value and cannot be processed")
    end

    if registeredStationType == GSMConfiguration.__STATION_TYPE_NORMAL then
        print("GroupStateMachine: Station Type = Normal")
    elseif registeredStationType == GSMConfiguration.__STATION_TYPE_PIPELINE then
        print("GroupStateMachine: Station Type = Pipeline")
    else
        error ("GroupStateMachine: Station Type is Unknown = (int)" .. registeredStationType)
    end
end

-- Initialize Group State Machine after the user provided values have been captured
local function groupStateMachineInit(groupArgumentsTable)
    GSMCore.groupArguments = groupArgumentsTable
    local registeredInfo = GSMConfiguration.__getConfiguration()

    -- Check if pipelined or regular station here
    registeredStationType = registeredInfo[GSMConfiguration.__stationTypeKey]
    validateStationType(registeredStationType)

    if registeredStationType == GSMConfiguration.__STATION_TYPE_NORMAL then
        overrideNormalStationGroupFunctions(groupFT, deviceFT, registeredInfo)
    elseif registeredStationType == GSMConfiguration.__STATION_TYPE_PIPELINE then
        overridePipelineStationGroupFunctions(groupFT, deviceFT, registeredInfo)
    end

    if registeredInfo[GSMConfiguration.__detectionTimeoutKey] then
        detectionTimeout = registeredInfo[GSMConfiguration.__detectionTimeoutKey]
    end
    if registeredInfo[GSMConfiguration.__readyForAutomatedHandlingCallbackKey] then
        readyForAutomatedHandlingCallback = registeredInfo[GSMConfiguration.__readyForAutomatedHandlingCallbackKey]
    end
    if registeredInfo[GSMConfiguration.__automationFixtureControlCallbacksKey] then
       automationFixtureControlCallbacks  = registeredInfo[GSMConfiguration.__automationFixtureControlCallbacksKey]
    end
    if registeredInfo[GSMConfiguration.__disabledResourcesKey] then
        resourcesEnabled = false
    end
    if registeredInfo[GSMConfiguration.__saveDAGKey] then
        saveDAG = true
    end
    local pipelineSlots = registeredInfo[GSMConfiguration.__pipelineSlotMapping]
    if pipelineSlots then
        for slot in pairs(pipelineSlots) do
            table.insert(pipelineMeta.slotArray, slot)
        end
        local pipelineLocationNames = registeredInfo[GSMConfiguration.__pipelineLocationNames]
        locationToFinish = registeredInfo['locationToFinish']

        setStrict(pipelineSlots)
        gsmPipeline.setPipelineSlots(pipelineSlots)
        gsmPipeline.setPipelineLocationNames(pipelineLocationNames)

        local nLocation = registeredInfo[GSMConfiguration.__pipelineLocationCount]
        pipelineMeta.nLocation = nLocation
        if pipelineLocationNames then
            assert(nLocation == #pipelineLocationNames, 'location number in slot mapping('..nLocation..') and location names ('..pipelineLocationNames..')does not match.')
            setStrict(pipelineLocationNames)
        end
    end
end

local function groupStateMachineTestMainPerDetection(slots)
    print ("GroupStateMachine : DeviceSetup")
    local devicePluginTable, mergedPluginTable, pluginNamesToUnmanageTable = gsmFT.deviceSetup(deviceFT, groupPluginTable, slots)

    print ("GroupStateMachine : GroupStart")
    gsmFT.groupStart(groupFT, groupPluginTable)

    print ("GroupStateMachine : ExecuteTest")
    gsmFT.executeTest(deviceFT, mergedPluginTable, pluginNamesToUnmanageTable, saveDAG)

    print ("GroupStateMachine : GroupStop")
    gsmFT.groupStop(groupFT, groupPluginTable)

    print ("GroupStateMachine : DeviceTeardown")
    gsmFT.deviceTeardown(deviceFT, devicePluginTable, groupPluginTable)

    return true
end

local function groupStateMachineTestMain()
    print ("GroupStateMachine : GetSlots")
    local slots = nil

    try (function()
        slots = gsmFT.groupGetSlots(groupFT, groupPluginTable, detectionTimeout, readyForAutomatedHandlingCallback, automationFixtureControlCallbacks)
    end,
    groupStateMachineTestMainFailAndStopDevice)

    if slots then
        repeat
            try(groupStateMachineTestMainPerDetection,
                groupStateMachineTestMainFailAndStopDevice,
                slots)
        -- using default loopAgain function; station cannot set it.
        until not gsmFT.loopAgain(groupFT, groupPluginTable)
    end
end

local function groupStateMachinePipelineTestMain()
    print("GroupStateMachinePipeline : GetSlots")
    try (function()
        slots = gsmFT.groupGetSlots(groupFT, groupPluginTable, detectionTimeout, readyForAutomatedHandlingCallback, automationFixtureControlCallbacks)
    end,
    groupStateMachineTestMainFailAndStopDevice)
    print('Detected slots: '..dump(slots))

    local slotArray, SN = gsmPipeline.separateSlotNameAndSN(slots)
    local devicePluginTable, mergedPluginTable, pluginNamesToUnmanageTable, devicesStarted = gsmFT.deviceSetup(deviceFT, groupPluginTable, slots)

    gsmPipeline.initPipelineDevices(devicesStarted)

    gsmPipeline.scheduleCoverage(devicesStarted, mergedPluginTable, pluginNamesToUnmanageTable, deviceFT, saveDAG)

    -- Scheduling and running all newly detected devices 
    local nextPhase = gsmPipeline.generateNextPhase(pipelineMeta, slotArray)
    if next(nextPhase) then
        print("Begin execution of current phase for all newly detected slots: " .. dump(slotArray))
        Group.runUntil(nextPhase)
    end

    -- Waiting for existing devices to finish
    print('Waiting until all active slots finish coverage execution for their respective phases')
    nextPhase = gsmPipeline.generateNextPhase(pipelineMeta)
    if next(nextPhase) then
        Group.wait()
    end

    -- check if any device error out; if yes, exclude it from phase advancement.
    gsmPipeline.excludeErroredDevice(pipelineMeta)

    -- call user's move function
    gsmFT.advancePhase(groupFT, groupPluginTable)

    -- Call internal function to advance all slots forward by 1
    gsmPipeline.advancePhase(pipelineMeta, locationToFinish)

    -- Determine which devices are ready for teardown and remove them from pipelistSlots
    local devicesToFinish = gsmPipeline.devicesAtLocation(pipelineMeta, locationToFinish)
    gsmFT.deviceTeardown(deviceFT, devicePluginTable, groupPluginTable, devicesToFinish)
    gsmPipeline.cleanupDevices(devicesToFinish)

    -- Call user finish phase advance function
    gsmFT.finishAdvancePhase(groupFT, groupPluginTable)

    -- Begin running next phase for all active slots
    print('Begin execution of next phase for all slots')
    nextPhase = gsmPipeline.generateNextPhase(pipelineMeta)
    if next(nextPhase) then
        Group.runUntil(nextPhase)
    end
end

local function groupStateMachineMainPerSetup(...)
    print ("GroupStateMachine : Init")
    groupStateMachineInit({...})

    print ("GroupStateMachine : GroupSetup")
    groupPluginTable = gsmFT.groupSetup(groupFT, readyForAutomatedHandlingCallback, resourcesEnabled)

    print("GroupStateMachine : TestLoopStart")
    local mapping = {
        [GSMConfiguration.__STATION_TYPE_NORMAL] = groupStateMachineTestMain,
        [GSMConfiguration.__STATION_TYPE_PIPELINE] = groupStateMachinePipelineTestMain
    }
    setStrict(mapping)

    local mainFunction = mapping[registeredStationType]

    repeat
        try(mainFunction,
        function (err)
            print("GroupStateMachine : error was caught : " .. err)
            os.execute('sleep 3')
        end)
    until gsmFT.groupShouldExit(groupFT, groupPluginTable)

    print ("GroupStateMachine : GroupTeardown")
    gsmFT.groupTeardown(groupFT, groupPluginTable)
end

GSMCore.groupStateMachineMain = function (...)
    try(function (...)
        groupStateMachineMainPerSetup(...)
    end,
    function (err)
        error("Exiting Group State Machine : error = " .. err)
    end, ...)
end

local readonlyTable = { main = GSMCore.groupStateMachineMain, GSM = GSMCore, GSMInternal = gsmFT }

setmetatable(_G, {
    __index=readonlyTable,
    __newindex= function (tab, name, value)
        if rawget(readonlyTable, name) then
            error(name ..' is a read only variable', 2)
        end
        rawset(tab, name, value)
    end
})
