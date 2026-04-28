local fixtureControl = {}
local Log = require("Common/logging")
local constants = require("INVT/constants")
local Utilities = Atlas.loadPlugin("Utilities")
local rtLib = require("INVT/Modules/RTCommonLib")
local PluginsLoader = require("INVT/Modules/PluginsLoader")

fixtureControl.groupID = nil
fixtureControl.pluginObj = nil
--!@ IDLE READY DOWN
fixtureControl.status = "IDLE"

Log.LogInfo(">>>>>>>>require fixtureControl<<<<<<<<")

function fixtureControl.connect(groupID)
    local fixtureLogPath = constants.Fixture["LogPath"]
    local url = constants.Fixture["URL"]
    Log.LogInfo("FixtureControl url: ", url)
    Log.LogInfo("Create FixtureControl log : ", fixtureLogPath)
    local pluginObj = PluginsLoader.createComm(url, fixtureLogPath)
    if not pluginObj then
        return false, "Create FixtureControl CommBuilder is Fail"
    end
    for i=1, 20 do
        pcall(pluginObj.open)
        if pluginObj.isOpened() == 1 then
            break
        end
        os.execute("sleep 0.1")
    end
    if pluginObj.isOpened() == 1 then
        pluginObj.setLineTerminator("\n")
        Log.LogInfo("Connect Fixture successful!")
    else
        return false, "Connect Fixture Fail"
    end

    fixtureControl["groupID"] = groupID
    fixtureControl["pluginObj"] = pluginObj
    fixtureControl.status = "READY"
    fixtureControl.clear(0.25)
    return true, "Connect Fixture Pass"
end

function fixtureControl.reset()
    local fixutreChannel = fixtureControl.pluginObj
    local groupIndex = fixtureControl.groupID
    if fixutreChannel == nil then
        error("Must be call FixtureControl connect first!")
    elseif fixutreChannel.isOpened() ~= 1 then
        fixutreChannel.open()
        fixutreChannel.setLineTerminator("\n")
    end
    fixtureControl.clear(0.25)
    fixutreChannel.write(constants.Fixture.RESET_CMD)
    fixtureControl.clear(0.5)
    Log.LogInfo("RESET!")
    -- local satrtTime = os.time()
    -- while os.time() - satrtTime <= 10 do
    --     fixutreChannel.setTimeoutIsException(0)
    --     local status, response = pcall(fixutreChannel.read, 1, constants.Fixture.RESET_DONE)
    --     fixutreChannel.setTimeoutIsException(1)
    --     Log.LogInfo("Response:", response)
    --     if string.find(response, constants.Fixture.RESET_DONE) then
    --         fixtureControl.status = "READY"
    --         break
    --     end
    --     os.execute("sleep 0.1")
    -- end
end

function fixtureControl.startTest(activeUnits)
    local fixutreChannel = fixtureControl.pluginObj
    local groupIndex = fixtureControl.groupID
    if fixutreChannel == nil then
        error("Must be call FixtureControl init first!")
    elseif fixutreChannel.isOpened() ~= 1 then
        fixutreChannel.open()
        fixutreChannel.setLineTerminator("\n")
    end
    if constants.Fixture.AUTO_START and fixtureControl.status == "READY" then
        fixtureControl.clear(0.25)
        fixutreChannel.write(constants.Fixture.START_CMD)
        Log.LogInfo("AUTO START!")
    end
    local bRet = fixtureControl.detectFixtureEngagement()
    local msg = bRet and "Start Test Pass" or "Start Test Fail"
    if bRet then
        for i=1, 4, 1 do
            fixtureControl.unitLED(i, "OFF")
        end
        for unit, _ in pairs(activeUnits) do
            fixtureControl.unitLED(tonumber(string.match(unit, "([0-9]+)$")), "BLUE")
        end
    end
    fixtureControl.statusLED(bRet and "BLUE" or "RED")
    return bRet, msg
end

function fixtureControl.endTest()
    fixtureControl.reset()
    local fixutreChannel = fixtureControl.pluginObj
    if fixutreChannel.isOpened() == 1 then
        fixutreChannel.close()
    end
    return true
end

function fixtureControl.clear(timeout)
    local fixutreChannel = fixtureControl.pluginObj
    if fixutreChannel.isOpened() ~= 1 then
        fixutreChannel.open()
        fixutreChannel.setLineTerminator("\n")
    end
    fixutreChannel.setDelimiter("")
    fixutreChannel.setTimeoutIsException(0)
    local status, response = pcall(fixutreChannel.readData, timeout)
    fixutreChannel.setTimeoutIsException(1)
    return true
end

function fixtureControl.statusLED(state)
    local fixutreChannel = fixtureControl.pluginObj
    if fixutreChannel.isOpened() ~= 1 then
        fixutreChannel.open()
        fixutreChannel.setLineTerminator("\n")
    end
    local stateTable = { GREEN="g", RED="r", BLUE="b" }
    fixutreChannel.write(("led_state_value 0 %s\n"):format(stateTable[state]))
    fixtureControl.clear(0.05)
end

function fixtureControl.unitLED(slot, state)
    local fixutreChannel = fixtureControl.pluginObj
    if fixutreChannel.isOpened() ~= 1 then
        fixutreChannel.open()
        fixutreChannel.setLineTerminator("\n")
    end
    local stateTable = { GREEN="g", RED="r", BLUE="b", OFF="off" }
    fixutreChannel.write(("led_state_value %s %s\n"):format(slot, stateTable[state]))
    fixtureControl.clear(0.05)
end

function fixtureControl.detectFixtureEngagement(detectStr)
    local fixutreChannel = fixtureControl.pluginObj
    local groupIndex = fixtureControl.groupID
    local satrtTime = os.time()
    local bRet = false
    local detectStr = detectStr or constants.Fixture.START_DONE
    if fixtureControl.status == "DOWN" then
        return true
    end
    if fixutreChannel == nil then
        error("Must be call FixtureControl connect first!")
    elseif fixutreChannel.isOpened() ~= 1 then
        fixutreChannel.open()
        fixutreChannel.setLineTerminator("\n")
    end
    local response = ""
    while os.time() - satrtTime <= 20 do
        fixutreChannel.setTimeoutIsException(0)
        local _, retVal = pcall(fixutreChannel.readData, 1)
        fixutreChannel.setTimeoutIsException(1)
        local retBuf = Utilities.dataToHexString(retVal)
        local retStr = rtLib.hex2ascii(retBuf)
        Log.LogInfo("FixtureControl:", retStr)
        response = response .. retStr
        if string.find(response, detectStr) then
            fixtureControl.status = "DOWN"
            bRet = true
            break
        end
        os.execute("sleep 0.1")
    end
    return bRet
end

return fixtureControl
