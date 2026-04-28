local GSMConfiguration = {}

local common = require"GroupStateMachine/GSMCommon"
local helpers = require "GroupStateMachine/GSMHelpers"
local dump = helpers.dump

-- Key values start
local _stationType = "stationType"
local _groupFT = "groupFunctionTable"
local _deviceFT = "deviceFunctionTable"
local _detectionTimeout = "detectionTimeout"
local _readyForAutomatedHandlingCallback = "readyForAutomatedHandlingCallback"
local _automationFixtureControlCallbacks = "automationFixtureControlCallbacks"
local _disabledResources = "disabledResources"
local _saveDAG = "saveDAG"
local _pipelineSlotMapping = "pipelineSlotMapping"
local _pipelineLocationNames = "pipelineLocationNames"
local _pipelineLocationCount = "pipelineLocationCount"
-- Key values end

local STATION_TYPE_UNSET = common.STATION_TYPE_UNSET
local STATION_TYPE_NORMAL = common.STATION_TYPE_NORMAL
local STATION_TYPE_PIPELINE = common.STATION_TYPE_PIPELINE

-- Local var to track station type variable
local _stationTypeVal = STATION_TYPE_UNSET

------------------- Internal APIs
local registeredConfiguration = {}
function GSMConfiguration.__getConfiguration()
  local localCopy = registeredConfiguration
  registeredConfiguration = nil
  return localCopy
end

GSMConfiguration.__saveDAGKey                            = _saveDAG
GSMConfiguration.__stationTypeKey                        = _stationType
GSMConfiguration.__groupFunctionTableKey                 = _groupFT
GSMConfiguration.__deviceFunctionTableKey                = _deviceFT
GSMConfiguration.__detectionTimeoutKey                   = _detectionTimeout
GSMConfiguration.__readyForAutomatedHandlingCallbackKey  = _readyForAutomatedHandlingCallback
GSMConfiguration.__automationFixtureControlCallbacksKey  = _automationFixtureControlCallbacks
GSMConfiguration.__disabledResourcesKey                  = _disabledResources
GSMConfiguration.__pipelineSlotMapping                   = _pipelineSlotMapping
GSMConfiguration.__pipelineLocationNames                 = _pipelineLocationNames
GSMConfiguration.__pipelineLocationCount                 = _pipelineLocationCount

-- Station Type Consts Start
GSMConfiguration.__STATION_TYPE_UNSET                    = STATION_TYPE_UNSET
GSMConfiguration.__STATION_TYPE_NORMAL                   = STATION_TYPE_NORMAL
GSMConfiguration.__STATION_TYPE_PIPELINE                 = STATION_TYPE_PIPELINE
-- Station Type Consts End

local function assertSystemStillEditable()
  if not registeredConfiguration then
    error("GroupStateMachine already configured. Cannot re-configure while state machine is active!")
  end
end

local function assertStationTypeIsUnSet()
  if (_stationTypeVal ~= STATION_TYPE_UNSET) then
    local errMsg = "GroupStateMachine: Group functions have already been registered."
    errMsg = errMsg + " In combination, registerPipelineGroupFunctionTable"
    errMsg = errMsg + " and registerGroupFunctionTable can only be called once"
    error(errMsg)
  end
end

local function assertStationTypeIsPipeline()
  if (_stationTypeVal ~= STATION_TYPE_PIPELINE) then
    local errMsg = "GroupStateMachine: expecting pipeline station, " ..
                   "while GSM type is " .. _stationTypeVal
    error(errMsg)
  end
end


------------------- Group APIs
function GSMConfiguration.registerGroupFunctionTable(groupFunctionTable)
  assertSystemStillEditable()
  assertStationTypeIsUnSet()
  registeredConfiguration[_groupFT] = groupFunctionTable
  registeredConfiguration[_stationType] = STATION_TYPE_NORMAL
  _stationTypeVal = STATION_TYPE_NORMAL
end

function GSMConfiguration.registerPipelineGroupFunctionTable(groupFunctionTable)
  assertSystemStillEditable()
  assertStationTypeIsUnSet()
  registeredConfiguration[_groupFT] = groupFunctionTable
  registeredConfiguration[_stationType] = STATION_TYPE_PIPELINE
  _stationTypeVal = STATION_TYPE_PIPELINE
end

function GSMConfiguration.registerDeviceFunctionTable(deviceFunctionTable)
  assertSystemStillEditable()
  registeredConfiguration[_deviceFT] = deviceFunctionTable
end

function GSMConfiguration.setDetectionTimeout(interarrival)
  GSMConfiguration.setDetectionTimeout(interarrival, -1)
end

function GSMConfiguration.setDetectionTimeout(interarrival, global)
  assertSystemStillEditable()
  if interarrival == nil or global == nil then
    error("Cannot set timeouts to nil. You can pass -1 for infinite timeout")
  end
  registeredConfiguration[_detectionTimeout] = { interarrival, global }
end

function GSMConfiguration.registerAutomatedHandlingCallback(readyForAutomatedHandlingCallback)
  assertSystemStillEditable()
  registeredConfiguration[_readyForAutomatedHandlingCallback] = readyForAutomatedHandlingCallback
end

function GSMConfiguration.registerAutomationFixtureControlCallbacks(automationFixtureControlCallbacks)
  assertSystemStillEditable()
  registeredConfiguration[_automationFixtureControlCallbacks] = automationFixtureControlCallbacks
end

function GSMConfiguration.disableResources()
  assertSystemStillEditable()
  registeredConfiguration[_disabledResources] = true
end

function GSMConfiguration.saveDAG()
  assertSystemStillEditable()
  registeredConfiguration[_saveDAG] = true
end

--[[
mapping: {
    {slot0, slot1}, -- 1st location.
    {slot2, slot3}, -- 2nd location.
    ...
    {slot6, slot7}, -- the last location.
}
locationNames: optional, string list of each location, like
{'load', 'test1', 'test2', 'unload'}
--]]
function GSMConfiguration.setPipelineSlotsMapping(mapping, locationNames)
  assertSystemStillEditable()
  assertStationTypeIsPipeline()
  print('Pipeline slot mapping: '..dump(mapping))
  -- slotName : {location = int, inTest = bool}
  local slots = {}
  for locationIndex, _slots in ipairs(mapping) do
    for _, slot in ipairs(_slots) do
      slots[slot] = {
        location = locationIndex,
        inTest = false
      }
    end
  end
  registeredConfiguration[_pipelineSlotMapping] = slots

  -- for faster search: name[1] = 'load', name['load'] = 1
  if locationNames then
    for i, name in ipairs(locationNames) do
      locationNames[name] = i
    end
  end
  registeredConfiguration[_pipelineLocationNames] = locationNames
  registeredConfiguration[_pipelineLocationCount] = #mapping
end

-- true: has dedicated unload: position1 is load, position[-1] is unload
-- false/nil: position1 is both load and unload
function GSMConfiguration.pipelineStationHasUnload(hasUnload)
  assertSystemStillEditable()
  assertStationTypeIsPipeline()
  print('hasUnload: '..tostring(hasUnload))
  if hasUnload then
    registeredConfiguration['locationToFinish'] = -1
  else
    registeredConfiguration['locationToFinish'] = 1
  end
end


return GSMConfiguration
