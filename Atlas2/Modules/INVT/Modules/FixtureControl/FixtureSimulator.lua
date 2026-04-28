local fixtureControl = {}
local Log = require("Common/logging")
local comFunc = require("Common/Utilities")
local commonUtil = Atlas.loadPlugin("SMTCommonPlugin")
local time = commonUtil.createTimeUtility()

fixtureControl.groupID = nil
fixtureControl.pluginObj = nil
fixtureControl.LogPath = "/vault/AtlasFixture.log"

Log.LogInfo(">>>>>>>>require fixtureControl<<<<<<<<")

function fixtureControl.connect(groupID)
    fixtureControl["groupID"] = groupID
    os.remove(fixtureControl.LogPath)
    local fd = io.open(fixtureControl.LogPath, "a+")
    fd:write("Create Simulator FixtureControl\r\n")
    fd:close()
    return true, "Connect Fixture Pass"
end

function fixtureControl.reset()
    local fd = io.open(fixtureControl.LogPath, "a+")
    fd:write("FixtureControl: RESET!\n")
    fd:close()
    Log.LogInfo("RESET!")
end

function fixtureControl.statusLED(state)
    local fd = io.open(fixtureControl.LogPath, "a+")
    fd:write(string.format("StatusLED: %s !\n", state))
    fd:close()
    return true
end

function fixtureControl.unitLED(slot, state)
    local fd = io.open(fixtureControl.LogPath, "a+")
    fd:write(string.format("UnitLED: %s set %s !\n", slot, state))
    fd:close()
    return true
end

function fixtureControl.startTest(activeUnits)
    Log.LogInfo("Fixture Start Test!")
    local fd = io.open(fixtureControl.LogPath, "a+")
    fd:write("FixtureControl: Fixture START!\n")
    -- fd.write(tostring(comFunc.dump(activeUnits)).."\n")
    fd:close()
    return true, "Start Test Pass"
end

function fixtureControl.endTest()
    Log.LogInfo("Fixture Finished Test!")
    local fd = io.open(fixtureControl.LogPath, "a+")
    fd:write("FixtureControl: Fixture FINISHED!\n")
    fd:close()
    fixtureControl.reset()
    return true
end

function fixtureControl.detectFixtureEngagement()
    Log.LogInfo("detectFixtureEngagement!")
    local fd = io.open(fixtureControl.LogPath, "a+")
    fd:write("FixtureControl: Detect Fixture Engagement!\n")
    fd:close()
    return true
end

return fixtureControl
