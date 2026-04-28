local schooner = require "Schooner"
local Log = require("Common/logging")
local comFunc = require("Common/Utilities")
local constants = require("VendorProxy").getConstants()

-- use DEBUGGING_LOG_DISABLED flag to control if disableGroupScriptDebugPrint or not
if constants.DEBUGGING_LOG_DISABLED then
    schooner.disableGroupScriptDebugPrint()
end

-- Initialize with user overrides
schooner.registerGroupFunctions(require "GroupFunctions")
schooner.registerDeviceFunctions(require "DeviceFunctions")

-- override schooner default limit version
schooner.overrideLimitVersion(function(...)
    local overlayVer = constants.StationInfo.stationOverlay
    local retTab = comFunc.splitString(overlayVer, " ")
    local limitVer = retTab[#retTab]
    Log.LogInfo("limitVer Version is:", limitVer)
    return limitVer
end)

-- keep the existing group alive after each test cycle.
schooner.setGroupShouldExitFunction(function()
    return constants.NEED_GROUP_EXIT or false
end)

