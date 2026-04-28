-- release date: 2023-10-09 17:00:00
local MIXRPCRelayMatchboxWrapper = {}
local comFunc = require("Matchbox/CommonFunc")
local Log = require("Matchbox/logging")
local Record = require 'Matchbox/record'

-- Sleep Convenience Function (seconds)
function MIXRPCRelayMatchboxWrapper.fDelayForPeriod(paraTab)
    paraTab["functionName"] = "fDelayForPeriod"
    local sInput = tonumber(paraTab.Input)

    Log.LogInfo("sleep " .. tostring(sInput) .. "s")
    comFunc.sleep(sInput)

    -- return true
end

function MIXRPCRelayMatchboxWrapper.initializeDUTLevelPlugin(workingDirectory, deviceName)
    local rpc = Atlas.loadPlugin("MIXRPCRelay")
    rpc.setLogFileSettings(workingDirectory, deviceName)
    return rpc
end

-- NOTE: There should only be one instance of a group level MIXRPCRelay Plugin!
function MIXRPCRelayMatchboxWrapper.loadGroupLevelPlugin()
    local GroupRPC = Atlas.loadPlugin("MIXRPCRelay")
    return GroupRPC
end

-- Requires that users call the group level plugin GroupRPC and assumes there is only one instance!!!
-- If users require more than one instance, this block must be recreated within the plugin loader
function MIXRPCRelayMatchboxWrapper.initializeGroupLevelPlugin(groupPlugins, workingDirectory, deviceName)
    for i in pairs(groupPlugins) do
        Log.LogInfo("group plugin: " .. i)

        if i == "GroupRPC" then
            Log.LogInfo("trying to set groupRPC log path at: " .. workingDirectory .. deviceName)
            -- set the deviceName so that the shared group plugin logging only goes to that one DUT
            groupPlugins.GroupRPC.setLogFileSettings(workingDirectory, deviceName)
        end
    end
end

local function UUID()
    local template = 'yxxxyxxxy'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- Morocco Style RPC Call with CLI Compatible Plain-Text Syntax
function MIXRPCRelayMatchboxWrapper.rpc(paraTab)
    local plugin = Device.getPlugin("rpc")
    local returnVal = plugin.commands(tostring(paraTab.Commands), tonumber(paraTab.Timeout))
    -- UUID is required due to Insight record naming conflicts if called more than once
    local uuid = UUID()

    -- using Testname: "FIXTURE" Subtestname: "MIX <UUID>" Subsubtestname: server.service.command(truncated to 32 characters for Insight)
    -- simple way to get the Plugin's actions to show up as a pass/fail test record, this may be unwanted for duplicate fixture commands
    if (returnVal ~= nil) then
        if string.len(tostring(paraTab.Commands)) > 32 then
            Record.createBinaryRecord(1, "Fixture", "MIX <" .. uuid .. ">",
                                      string.sub(tostring(paraTab.Commands), 0, 32))
        else
            Record.createBinaryRecord(1, "Fixture", "MIX <" .. uuid .. ">", tostring(paraTab.Commands))
        end

        return true
    else
        Record.createBinaryRecord(0, "Fixture", "MIX <" .. uuid .. ">", tostring(paraTab.Commands),
                                  "ERROR! Malformed return from MIXRPCRelay plugin!")
        return false
    end
end

-- Morocco Style RPC Call with CLI Compatible Plain-Text Syntax
function MIXRPCRelayMatchboxWrapper.groupRpc(paraTab)
    local groupPlugin = Device.getPlugin("GroupRPC")
    local returnVal = groupPlugin.commands(tostring(paraTab.Commands), tonumber(paraTab.Timeout))
    -- UUID is required due to Insight record naming conflicts if called more than once
    local uuid = UUID()

    -- using Testname: "FIXTURE" Subtestname: "MIX <UUID>" Subsubtestname: server.service.command(truncated to 32 characters for Insight)
    -- simple way to get the Plugin's actions to show up as a pass/fail test record, this may be unwanted for duplicate fixture commands
    if (returnVal ~= nil) then
        if string.len(tostring(paraTab.Commands)) > 32 then
            Record.createBinaryRecord(1, "Fixture", "MIX <" .. uuid .. ">",
                                      string.sub(tostring(paraTab.Commands), 0, 32), " ")
        else
            Record.createBinaryRecord(1, "Fixture", "MIX <" .. uuid .. ">", tostring(paraTab.Commands))
        end

        return true
    else
        Record.createBinaryRecord(0, "Fixture", "MIX <" .. uuid .. ">", tostring(paraTab.Commands),
                                  "ERROR! Malformed return from Group Level MIXRPCRelay plugin!")
        return false
    end
end

-- MoroccoB Function Wrappers
function MIXRPCRelayMatchboxWrapper.integrityCheckInit(paraTab)
    local plugin = Device.getPlugin("rpc")
    local additionalParams = paraTab.AdditionalParameters
    -- UUID is required due to Insight record naming conflicts if called more than once
    local uuid = UUID()

    if tostring(additionalParams["serverEndpoint"]) == "" then
        Record.createBinaryRecord(0, "Fixture", "MIX <" .. uuid .. ">", "Integrity Check Init",
                                  "ERROR! \"serverEndpoint\" parameter is missing!")
        return false
    end

    if tostring(additionalParams["mixbundlePath"]) == "" then
        Record.createBinaryRecord(0, "Fixture", "MIX <" .. uuid .. ">", "Integrity Check Init",
                                  "ERROR! \"mixbundlePath\" parameter is missing!")
        return false
    end

    local returnVal = plugin.integrityCheckInit(additionalParams["serverEndpoint"], additionalParams["mixbundlePath"])

    -- using Testname: "FIXTURE" Subtestname: "MIX" Subsubtestname: "Integrity Check Init"
    if (returnVal ~= nil) then
        Record.createBinaryRecord(1, "Fixture", "MIX <" .. uuid .. ">", "Integrity Check Init")

        return true
    else
        Record.createBinaryRecord(0, "Fixture", "MIX <" .. uuid .. ">", "Integrity Check Init",
                                  "ERROR! Malformed return from MIXRPCRelay plugin!")
        return false
    end
end

function MIXRPCRelayMatchboxWrapper.integrityCheck()
    local plugin = Device.getPlugin("rpc")
    -- UUID is required due to Insight record naming conflicts if called more than once
    local uuid = UUID()

    local returnVal = plugin.integrityCheck()

    -- using Testname: "FIXTURE" Subtestname: "MIX" Subsubtestname: "Integrity Check"
    if (returnVal ~= nil) then
        Record.createBinaryRecord(1, "Fixture", "MIX <" .. uuid .. ">", "Integrity Check")

        return true
    else
        Record.createBinaryRecord(0, "Fixture", "MIX <" .. uuid .. ">", "Integrity Check",
                                  "ERROR! Malformed return from MIXRPCRelay plugin!")
        return false
    end
end

function MIXRPCRelayMatchboxWrapper.configBless(paraTab)
    local plugin = Device.getPlugin("rpc")
    local additionalParams = paraTab.AdditionalParameters
    -- Calls to Bless do not have a UUID since Bless should only ever be called once in-sequence

    if tostring(additionalParams["serverEndpoint"]) == "" then
        Record.createBinaryRecord(0, "Fixture", "MIX", "Config Bless", "ERROR! \"serverEndpoint\" parameter is missing!")
        return false
    end

    local returnVal = plugin.configBless(additionalParams["serverEndpoint"])

    -- using Testname: "FIXTURE" Subtestname: "MIX" Subsubtestname: "Config Bless"
    if (returnVal ~= nil) then
        Record.createBinaryRecord(1, "Fixture", "MIX", "Config Bless")

        return true
    else
        Record.createBinaryRecord(0, "Fixture", "MIX", "Config Bless",
                                  "ERROR! Malformed return from MIXRPCRelay plugin!")
        return false
    end
end

function MIXRPCRelayMatchboxWrapper.configCheck(paraTab)
    local plugin = Device.getPlugin("rpc")
    local additionalParams = paraTab.AdditionalParameters
    -- UUID is required due to Insight record naming conflicts if called more than once
    local uuid = UUID()

    if tostring(additionalParams["serverEndpoint"]) == "" then
        Record.createBinaryRecord(0, "Fixture", "MIX", "Config Check", "ERROR! \"serverEndpoint\" parameter is missing!")
        return false
    end

    local returnVal = plugin.configCheck(additionalParams["serverEndpoint"])

    -- using Testname: "FIXTURE" Subtestname: "MIX" Subsubtestname: "Config Check"
    if (returnVal ~= nil) then
        Record.createBinaryRecord(1, "Fixture", "MIX <" .. uuid .. ">", "Config Check")

        return true
    else
        Record.createBinaryRecord(0, "Fixture", "MIX <" .. uuid .. ">", "Config Check",
                                  "ERROR! Malformed return from MIXRPCRelay plugin!")
        return false
    end
end

-- MadagascarA Convenience Wrappers for Station Transition
function MIXRPCRelayMatchboxWrapper.legacyRpcInit(paraTab)
    local plugin = Device.getPlugin("rpc")
    local additionalParams = paraTab.AdditionalParameters
    -- Legacy style init: the equivalent of plugin.commands.("LEGACYUNNAMEDSERVERCONNECTION","tcp://192.168.99.11:7801")
    plugin.init(tostring(additionalParams["initializeWithIP"]), tonumber(additionalParams["withPort"]))
end

function MIXRPCRelayMatchboxWrapper.legacyRpcCall(paraTab)
    local plugin = Device.getPlugin("rpc")
    local returnVal = plugin.rpc(tostring(paraTab.Commands), paraTab.AdditionalParameters)

    -- simple conversion of the AdditionalParams dictionary into a string for a unique binary record
    -- this method will not work if multiple lines of the same arguments are executed
    local tableString = '{'

    for k, v in pairs(paraTab.AdditionalParameters) do
        tableString = tableString .. "\"" .. k .. "\"" .. ":" .. tostring(v)
    end

    tableString = tableString .. '}'

    -- using Testname: "FIXTURE" Subtestname: "MIX <UUID>" Subsubtestname: Legacy: service.command(truncated to 32 characters for Insight)
    local recordString = "Legacy: " .. tostring(paraTab.Commands) .. tableString
    -- UUID is required due to Insight record naming conflicts if called more than once
    local uuid = UUID()

    -- simple way to get the Plugin's actions to show up as a pass/fail test record, this may be unwanted for duplicate fixture commands
    if (returnVal ~= nil) then
        if string.len(recordString) > 32 then
            Record.createBinaryRecord(1, "Fixture", "MIX <" .. uuid .. ">", string.sub(recordString, 0, 32))
        else
            Record.createBinaryRecord(1, "Fixture", "MIX <" .. uuid .. ">", recordString)
        end
        return true
    else
        Record.createBinaryRecord(0, "Fixture", "MIX <" .. uuid .. ">", recordString,
                                  "ERROR! Malformed return from MIXRPCRelay plugin!")
        return false
    end
end

return MIXRPCRelayMatchboxWrapper
