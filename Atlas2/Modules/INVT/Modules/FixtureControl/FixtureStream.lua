local fixtureControl = {}
local Log = require("Common/logging")
fixtureControl.groupID = nil
fixtureControl.pluginObj = nil

Log.LogInfo(">>>>>>>>>>>>require fixtureControl<<<<<<<<<<<<<")

function fixtureControl.connect(groupID)
    local constants = require("INVT/constants")
    local topologyPath = constants.Fixture["TopologyPath"]
    local Fixture = Atlas.loadPlugin("StreamFixturePluginAtlas2")
    fixtureControl.pluginObj = Fixture
    local fixtureConnectStatusFlg = false
    -- @ Confirm the Fixture is connected
    for i = 1, 3 do
        local pcallPass, actResult = xpcall(Fixture.connectFixture, debug.traceback, groupID, topologyPath)
        Log.LogInfo("connectFixture result:", actResult, pcallPass, i)
        if actResult == "YES" then
            fixtureConnectStatusFlg = true
            break
        else
            os.execute("sleep 5")
        end
    end
    return fixtureConnectStatusFlg
end

function fixtureControl.reset()
    Log.LogInfo("initlization fixture")
    fixtureControl.fixtureLock(0)
    fixtureControl.trayUp()
    os.execute('sleep 1')
    fixtureControl.trayOut()
    fixtureControl.stateLED("blue")
end

function fixtureControl.startTest(activeUnits)
    local sensor_slot = {'2', '1', '4', '3', '6', '5', '8', '7'}
    local actualSlot = fixtureControl.hexToBin(fixtureControl.checkDutPosition())
    local dut_state = table.concat(actualSlot, "", 8, 8)
    local dut_sensor = {}
    for k, v in pairs(actualSlot) do
        if k > 6 then
            break
        end
        table.insert(dut_sensor, tostring(v))
    end
    if dut_state ~= '0' then
        fixtureControl.fixtureLock(0)
        return false, "DUT not READY!..."
    end
    for k, v in pairs(dut_sensor) do
        Log.LogInfo(">>>>>>>>>check dut sensor: ", 'slot' .. sensor_slot[k], ':',
                    output['slot' .. sensor_slot[k]])
        if v ~= '0' then
            if activeUnits['slot' .. sensor_slot[k]] ~= nil then
                FixtureControl.fixtureLock(0)
                local msg = string.format("slot%s not READY!...", sensor_slot[k])
                return false, msg
            end
        end
    end
    local fixState, fixRet = fixtureControl.controlFixtureEngagement(sensor_slot,activeUnits)
    if fixState == false then
        fixtureControl.reset()
        return false, "Fixture Control Error: " .. fixRet
    end
    return true, "Start Test Pass"
end

function fixtureControl.endTest()
    fixtureControl.reset()
    return true
end

function fixtureControl.delay(time)
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.delay======")
    eowyn.delay(time)
end

function fixtureControl.checkTrayPosition()
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.checkTrayPosition======")
    local ret = eowyn.checkTrayPosition()
    Log.LogInfo("#######fixtureControl.checkTrayPosition " .. tostring(ret))
    return ret
end

function fixtureControl.fixtureLock(state)
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.fixtureLock======")
    eowyn.fixtureLock(state)
end

function fixtureControl.stateLED(state)
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.stateLED======")
    eowyn.stateLED(state)
end

function fixtureControl.unitLED(slot, state)
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.unitLED======")
    eowyn.unitLED(slot, state)
end

function fixtureControl.checkDUTSensor()
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.checkDUTSensor======")
    local ret = eowyn.checkDUTSensor()
    Log.LogInfo("#######fixtureControl.checkDUTSensor " .. tostring(ret))
    return ret
end

function fixtureControl.checkDutPosition()
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.checkDutPosition======")
    eowyn.writeI2C("07ff", 0x44, 2)
    eowyn.writeI2C("06f0", 0x44, 2)
    local MSB = eowyn.writeReadI2C(0x44, "00", 1, 2)
    local LSB = eowyn.writeReadI2C(0x44, "01", 1, 2)
    Log.LogInfo("======fixtureControl.checkDutPosition" .. ":" .. MSB .. LSB)
    return MSB .. LSB
end

function fixtureControl.trayUp()
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.trayUp======")
    eowyn.trayUp()
end

function fixtureControl.trayDown()
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.trayDown======")
    eowyn.trayDown()
end

function fixtureControl.trayIn()
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.trayIn======")
    eowyn.trayIn()
end

function fixtureControl.trayOut()
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.trayOut======")
    eowyn.trayOut()
end

function fixtureControl.hexToBin(hexString)
    local binTable = {}
    local hexNumber = tonumber(hexString, 16)
    for i = (#hexString * 4 - 1), 0, -1 do
        binTable[#binTable + 1] = math.floor(hexNumber / 2 ^ i)
        hexNumber = hexNumber % 2 ^ i
    end
    local binString = table.concat(binTable)
    Log.LogInfo(string.format('=====transform %s to %s=====', hexString, binString))
    return binTable
end

function fixtureControl.controlFixtureEngagement(sensor_slot,output)
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.controlFixtureEngagement======")
    --local startTime = os.time()
    while true do
        local ret = fixtureControl.checkTrayPosition(eowyn)
        if ret == "TrayPositionIDLE" or ret == "TrayPositionOUT" then
            fixtureControl.trayIn(eowyn)
            os.execute('sleep 3')
            ret = fixtureControl.checkTrayPosition(eowyn)
            if ret == "TrayPositionIN" then
                local actualSlot = fixtureControl.hexToBin(fixtureControl.checkDutPosition(eowyn))
                local dut_state = table.concat(actualSlot, "", 8, 8)
                local dut_sensor = {}
                for k, v in pairs(actualSlot) do
                    if k > 6 then
                        break
                    end
                    table.insert(dut_sensor, tostring(v))
                end

                if dut_state ~= '0' then
                    return false, "DUT Not READY!"
                end

                for k, v in pairs(dut_sensor) do
                    Log.LogInfo(">>>>>>>>>fixtureControl check dut sensor: ", 'slot' .. sensor_slot[k], ':',
                                output['slot' .. sensor_slot[k]])
                    if v ~= '0' then
                        if output['slot' .. sensor_slot[k]] ~= nil then
                            return false, string.format("slot%s not READY!...", sensor_slot[k])
                        end
                    end
                end
                fixtureControl.trayDown(eowyn)
                os.execute('sleep 1')
                ret = fixtureControl.checkTrayPosition(eowyn)
                if ret == "TrayPositionDOWN" then
                    return true, "Fixture Down OK"
                else
                    return false, "Fixture Down Error!"
                end
            else
                return false, "Fixture IN Error!"
            end
        else
            return false, "Fixture Invalid State"..ret
        end
    end
end

function fixtureControl.detectFixtureEngagement()
    local eowyn = fixtureControl.pluginObj
    Log.LogInfo("======fixtureControl.detectEngagement======")
    local checkFlag = false
    local startTime = os.time()
    while true do
        Log.LogInfo("######detectEngagementing######")
        local ret = fixtureControl.checkTrayPosition(eowyn) -- try to read "START" signal every 5s
        if ret then
            if (ret == "TrayPositionIDLE") then
                checkFlag = true
            end
            if (checkFlag and ret == "TrayPositionIN") then
                fixtureControl.fixtureLock(eowyn, 1)
                fixtureControl.stateLED(eowyn, "blue")
                return true
            elseif (ret == "TrayPositionDOWN" or ret == "TrayPositionDUMMY") then
                fixtureControl.trayUp(eowyn)
                fixtureControl.fixtureLock(eowyn, 0)
                checkFlag = false
            end
        else
            Log.LogDebug("fixtureControl uart detectEngagement return nil")
        end
        os.execute("sleep 0.2")
        if os.time() - startTime >= 60 then
            Log.LogInfo("######fixture detectEngagement timeout######")
            fixtureControl.trayUp(eowyn)
            os.execute("sleep 0.2")
            fixtureControl.fixtureLock(eowyn, 0)
            return false
        end
    end
end

return fixtureControl
