local schoonerStationInfo = {}
-- TODO: don't know how to test it but wrapping functions inside a module
--  might be better than keep them as "local" which has no way to import from outside.
-- Maybe move it to a separate file later.
local schoonerStationInfoInternal = {}
-- pipeline cannot have
--   1. loopsPerDetection
--   2. groupExitFunction
-- normal station cannot have
--   1. pipelineSlotMapping
--   2. pipelineStationHasUnload
function schoonerStationInfoInternal.verifyStationInfo(stationInfo)
    local bannedKeys = {
        pipeline = { "loopCountPerDetection", "shouldExitFunction" },
        nonPipeline = { "pipelineSlotMapping", "pipelineStationHasUnload" }
    }
    -- `nonPipeline` is more meaningful in this message than `normal`
    -- I cannot find a better name; stationType has other name, type is a Lua keyword
    -- so use t at the moment.
    local t = stationInfo.type == 'pipeline' and 'pipeline' or 'nonPipeline'
    for _, key in ipairs(bannedKeys[t]) do
        if stationInfo[key] then
            error(key .. ' configured for ' .. t ..
                  ' station, which is not supported.')
        end
    end
end

------------------- Internal APIs
local registeredStationInfo = {}
function schoonerStationInfo.getRegisteredStationInfo()
    local localCopy = registeredStationInfo
    registeredStationInfo = nil
    schoonerStationInfoInternal.verifyStationInfo(localCopy)
    return localCopy
end

local function assertSystemStillEditable()
    if not registeredStationInfo then
        local msg = "System has already started up. "
        msg = msg .. "Cannot register new station attributes."
        error(msg)
    end
end

------------------- Group APIs
-- TODO: convert this into something simliar in Compiler/Errors.lua
local dupGFT = 'Both GroupFunctions and PipelineGroupFunctions are ' ..
               'registered; Schooner is confused about which one to use. ' ..
               'Please register PipelineGroupFunctions for pipeline ' ..
               'station and register GroupFunctions for non-pipeline ' ..
               'station.'

function schoonerStationInfo.registerGroupFunctions(groupFunctionTable)
    assertSystemStillEditable()
    assert(registeredStationInfo["type"] == nil, dupGFT)
    registeredStationInfo["groupFT"] = groupFunctionTable
    registeredStationInfo.type = 'normal'
end

function schoonerStationInfo.registerPipelineGroupFunctions(groupFunctionTable)
    assertSystemStillEditable()
    assert(registeredStationInfo["type"] == nil, dupGFT)
    registeredStationInfo["groupFT"] = groupFunctionTable
    registeredStationInfo.type = 'pipeline'
end

function schoonerStationInfo.setPipelineStationSlotMapping(mapping)
    assertSystemStillEditable()
    registeredStationInfo["pipelineSlotMapping"] = mapping
end

-- bool. true: station has separated load & unload
--       false: the 1st location is combined load/unload
function schoonerStationInfo.pipelineStationHasUnload(hasUnload)
    assertSystemStillEditable()
    registeredStationInfo["pipelineStationHasUnload"] = hasUnload
end

function schoonerStationInfo.registerDeviceFunctions(deviceFunctionTable)
    assertSystemStillEditable()
    registeredStationInfo["deviceFT"] = deviceFunctionTable
end

-- allow user to control dag exit early for error/failure record
function schoonerStationInfo.endTestingOnFailureRecord()
    assertSystemStillEditable()
    registeredStationInfo["endTestingOnFailureRecord"] = true
end

function schoonerStationInfo.disableGroupScriptDebugPrint()
    assertSystemStillEditable()
    registeredStationInfo["disableGroupScriptDebugPrint"] = true
end

function schoonerStationInfo.setDetectionInterarrivalTimeout(interarrival)
    assertSystemStillEditable()
    schoonerStationInfo.setDetectionTimeout(interarrival, -1)
end

function schoonerStationInfo.setDetectionTimeout(interarrival, global)
    assertSystemStillEditable()
    if interarrival == nil or global == nil then
        error("Cannot set detection timeouts to nil")
    end
    registeredStationInfo["detectionTimeout"] = { interarrival, global }
end

--- Set number of times to loop for each unit detected
function schoonerStationInfo.setLoopCountPerDetection(loopsPerDetection)
    assertSystemStillEditable()
    registeredStationInfo["loopCountPerDetection"] = loopsPerDetection
end

--- Set a function to decide if the Group should exit
function schoonerStationInfo.setGroupShouldExitFunction(shouldExitFunction)
    assertSystemStillEditable()
    assert(type(shouldExitFunction) == 'function',
           'Group shouldExitFunction should be a function while got ' ..
           type(shouldExitFunction))
    registeredStationInfo["shouldExitFunction"] = shouldExitFunction
end

-- Set test scheduler thread pool limit.
function schoonerStationInfo.setThreadPoolLimit(limit)
    assertSystemStillEditable()
    if type(limit) ~= "number" or limit <= 0 then
        error("Pass a positive integer to set the thread limit.")
    end
    registeredStationInfo["schedulerThreads"] = limit
end

function schoonerStationInfo.readyForAutomatedHandling(
readyForAutomatedHandlingCallback)
    assertSystemStillEditable()
    registeredStationInfo["readyForAutomatedHandling"] =
    readyForAutomatedHandlingCallback
end

function schoonerStationInfo.automationFixtureControlCallbacks(
automationFixtureControlCallbacks)
    assertSystemStillEditable()
    registeredStationInfo["automationFixtureControlCallbacks"] =
    automationFixtureControlCallbacks
end

function schoonerStationInfo.saveDAG()
    assertSystemStillEditable()
    registeredStationInfo["saveDAG"] = true
end

-- This is an internal API only for testing.
-- Calling this API will fail the DUT test.
-- Do not use it on station.
function schoonerStationInfo.registerSamplingPlugin(plugin)
    assertSystemStillEditable()
    registeredStationInfo["samplingPluginFromUser"] = plugin
end

-- Set limit version string by callback
function schoonerStationInfo.overrideLimitVersion(setLimitVersionCallback)
    assertSystemStillEditable()
    assert(type(setLimitVersionCallback) == 'function',
           'Group setLimitVersionCallback should be a function while got ' ..
           type(setLimitVersionCallback))
    registeredStationInfo["limitVersionFunction"] = setLimitVersionCallback
end

return schoonerStationInfo
