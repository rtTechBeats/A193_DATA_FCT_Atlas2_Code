-------------------------------------------------------------------
----***************************************************************
---- Schooner Group Functions
----***************************************************************
-------------------------------------------------------------------

local GroupFunctions = {}

local Log = require("Common/logging")
local comFunc = require("Common/Utilities")
local util = Atlas.loadPlugin("SMTCommonPlugin")
local time = util.createTimeUtility()
local constants = require("VendorProxy").getConstants()

--!@ For automation
local factoryAutomationEnabled = false
local automationBridgePlugin = nil
local automationHelper = nil

--!@ Save Fixture object
GroupFunctions.fixture = require("VendorProxy")

--! @brief: parse limitTable csv of comapring the lowerlimit and upperlimit
--! @return: limitsTable
local function parseLimitCSVbyCoverage()
    local parseLimit = require('Schooner.Compiler.Limits')
    local limitsTable = {}
    local limitsPath = Atlas.assetsPath .. "/Coverage/LimitsTable.csv"
    local limitsTableCSV = parseLimit.parseLimitCSV(limitsPath)

    for _, v in pairs(limitsTableCSV) do
        if v.upperLimit ~= nil or v.units ~= nil then
            local keyName = string.format("%s_%s_%s", v.Technology, v.Coverage, v.SubSubTest)
            local tmpTable = {}
            tmpTable["lowerLimit"] = v.lowerLimit
            tmpTable["upperLimit"] = v.upperLimit
            tmpTable["unit"] = v.units
            limitsTable[keyName] = tmpTable
        end
    end

    return limitsTable
end

--! @brief: setup group plugins
function GroupFunctions.setup(resources)
    Log.LogInfo("------>> GroupFunctions setup <<------")
    local plugins = {}
    local InteractiveView

    --!@ loading common plugins
    local mdParser = Atlas.loadPlugin("MDParser")
    mdParser.init(Atlas.assetsPath .. "/parseDefinitions", "ANYTHING")
    local variableTab = Atlas.loadPlugin("VariableTable")
    variableTab.init()
    variableTab.setVar("testMode", GSM.groupArguments[#GSM.groupArguments])
    variableTab.setVar("limitsTable", parseLimitCSVbyCoverage())
    plugins['MDParser'] = mdParser
    plugins["VariableTable"] = variableTab
    plugins["MutexPlugin"] = Atlas.loadPlugin("MutexPlugin")

    --!@ comfirm the automation enabled or not from station.plist
    factoryAutomationEnabled = (GSM.groupArguments[1] == "Automation")
    Log.LogInfo("loadGroupPlugins FactoryAutomationEnabled:", factoryAutomationEnabled)
    if factoryAutomationEnabled then
        -- obtain automation helper module
        automationHelper = require("FactoryAutomationHelper")
        -- load AtlasAutomationBridge remote plugin
        automationBridgePlugin = Remote.loadRemotePlugin(resources["AtlasAutomationBridge"])
    else
        InteractiveView = Remote.loadRemotePlugin(resources["SMTInteractiveUI"])
        plugins["InteractiveView"] = InteractiveView
    end

    --!@ load vendor unique group level plugins
    local fixture = GroupFunctions.fixture
    if fixture and fixture.loadGroupPlugins then
        local vendorPluginTable = fixture.loadGroupPlugins(resources, InteractiveView)
        for name, plugin in pairs(vendorPluginTable) do
            plugins[name] = plugin
        end
    end

    return plugins
end

--! @brief: get slots from group
function GroupFunctions.getSlots(groupPlugins, interarrivalTimeout, globalTimeout)
    Log.LogInfo("------>> GroupFunctions getSlots <<------")

    local fixture = GroupFunctions.fixture
    local allSlots = Group.getSlots(interarrivalTimeout, globalTimeout)
    table.sort(allSlots)
    Log.LogInfo('Group.getSlots() -> ' .. comFunc.dump(allSlots))

    --!@ check fixture is looping
    if fixture and fixture.checkLooping then
        fixture.checkLooping()
    end

    local viewConfig
    local activeUnits = {}
    local InteractiveView = groupPlugins["InteractiveView"]
    local groupIndex = tonumber(Group.index) - 1
    local snLength = constants["Scanner"]["SnLength"]
    local columns = constants["Scanner"]["Columns"]
    local testMode = GSM.groupArguments[1]
    Log.LogInfo("TestMode: ".. tostring(testMode))
    if testMode == nil or testMode == "Manual" then
        viewConfig = {["input"] = allSlots, ["length"] = snLength, ["column"] = columns}
        local output = InteractiveView.showGroupView(groupIndex, viewConfig)
        for _, unit in ipairs(allSlots) do
            Log.LogInfo("slotID :", unit)
            Log.LogInfo("slotSN :", output[unit])
            if output[unit] then
                activeUnits[unit] = output[unit]
            end
        end
    elseif testMode == "VendorMode" then
        viewConfig = {["switch"] = allSlots, ["column"] = columns}
        activeUnits = fixture.getSlots(InteractiveView, groupIndex, viewConfig)
    elseif testMode == "Panel" then
        viewConfig = {["label"] = "PanelID", ["input"] = {"slot1"}, ["length"] = snLength}
        local output = InteractiveView.showGroupView(groupIndex, viewConfig)
        local panelSN =  output["slot1"]
        activeUnits = fixture.getSnBypanelSN(panelSN)
    elseif testMode == "NoNeedScan" then
        viewConfig = {["switch"] = allSlots, ["column"] = columns}
        local output = InteractiveView.showGroupView(groupIndex, viewConfig)
        for _, unit in ipairs(allSlots) do
            if output[unit] == 1 then
                activeUnits[unit] = ""
            end
        end
    end

    --!@ fixture start test
    if fixture and fixture.startTest then
        fixture.startTest(activeUnits)
    end

    Group.clearStoppedDevices()
    return activeUnits
end

--! @brief: start group test
function GroupFunctions.start(groupPlugins)
    Log.LogInfo("------>> GroupFunctions start <<------")
    --!@ fixture start test
    local fixture = GroupFunctions.fixture
    if fixture and fixture.groupStart then
        fixture.groupStart(groupPlugins)
    end
end

--! @NotImplemented, Schooner v4.0.12 Sequence can't override this function
-- function GroupFunctions.loopAgain(groupPlugins)
--     Log.LogInfo("------>> GroupFunctions loopAgain <<------")
-- end

--! @brief: stop group test
function GroupFunctions.stop(groupPlugins)
    Log.LogInfo("------>> GroupFunctions stop <<------")
    --!@ check vendor fixture groupStop
    local fixture = GroupFunctions.fixture
    if fixture and fixture.groupStop then
        fixture.groupStop(groupPlugins)
    end
end

--! @brief: teardown group plugins
function GroupFunctions.teardown(groupPlugins)
    Log.LogInfo("------>> GroupFunctions teardown <<------")
    -- reset mutexPlugin
    if groupPlugins["MutexPlugin"] then
        groupPlugins["MutexPlugin"].reset()
    end
    -- shutdown VariableTable
    if groupPlugins["VariableTable"] then
        groupPlugins["VariableTable"].shutdown()
    end
    -- shutdown Vendor groupPlugins
    local groupIndex = tonumber(Group.index)
    local fixture = GroupFunctions.fixture
    if fixture and fixture.shutdownGroupPlugins then
        fixture.shutdownGroupPlugins(groupPlugins)
    end
    Log.LogInfo("Group" .. tostring(groupIndex) .. " end test")
end

return GroupFunctions
