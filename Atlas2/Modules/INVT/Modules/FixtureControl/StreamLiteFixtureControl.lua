local StreamLiteFixtureControl = {}
local Log = require("Common/logging")
local delay = require("Time").sleep
local ErrorCode = require("INVT/Modules/ErrorCode")
local ErrorFunction = ErrorCode.init("StreamLiteFixtureControl", 109)

Log.LogInfo(">>>>>>>>>>>>require StreamLiteFixtureControl<<<<<<<<<<<<<")

local RPCClient = require "INVT/Modules/RPCClient"
local fixtureRPCClientObj = nil
--[[
Description:
    Init StreamLiteFixtureControl,will initialize fixture.
Params:
    clientInstance<instance>: a instance of xavier rpc client.


Returns:
    None..

Usage:
    local PluginsLoader = require("INVT/Modules/PluginsLoader")
    groupPlugins['streamLiteRpcClient'] = PluginsLoader.createRPCClient("169.254.1.20",7805)
    local streamLiteRpcClient = groupPlugins.streamLiteRpcClient
    local streamLiteFixtureControl = require("INVT/Modules/StreamLiteFixtureControl")
    streamLiteFixtureControl.init(streamLiteRpcClient)

--]]
function StreamLiteFixtureControl.init(clientInstance)
    if clientInstance == nil then
        ErrorFunction(ErrorCode.ParameterEmptyErr)
    end
    Log.LogInfo("======StreamLiteFixtureControl.init======")
    fixtureRPCClientObj = clientInstance
end

--[[
Description:
    Initialize fixture state,set fan speed to full speed,set all LED to blue.
Params:
    None.

Returns:
    <boolean>: initializeFixture result.

Usage:
    local ret = streamLiteFixtureControl.initializeFixture()
    if not ret then
        Log.LogInfo("StreamLiteFixtureControl.init: Fixture initialize fail.")
    end

--]]
function StreamLiteFixtureControl.initializeFixture()
    Log.LogInfo("======StreamLiteFixtureControl.initializeFixture======")
    local ret = RPCClient.callRPCFunc("lucifer.fixture_init", {}, {}, 3000, fixtureRPCClientObj)
    if string.match(ret, "done") == nil then
        Log.LogInfo("StreamLiteFixtureControl.initializeFixture: Fixture initialize fail.")
        return false
    end
    Log.LogInfo("StreamLiteFixtureControl.initializeFixture: Fixture initialize successful.")
    return true
end

--[[
Description:
    Initial all LED,set all LED color state to blue.
Params:
    None.
Returns:
    None.

Usage:
    streamLiteFixtureControl.resetLED()

--]]
function StreamLiteFixtureControl.resetLED()
    Log.LogInfo("======StreamLiteFixtureControl.resetLED======")
    StreamLiteFixtureControl.setStateLED("blue")
    StreamLiteFixtureControl.setUUTLED("UUT1", "blue")
    StreamLiteFixtureControl.setUUTLED("UUT2", "blue")
    StreamLiteFixtureControl.setUUTLED("UUT3", "blue")
    StreamLiteFixtureControl.setUUTLED("UUT4", "blue")
end

--[[
Description:
    Set state LED to color.
Params:
    color<string>: state LED color to set(BLUE, GREEN, RED).
Returns:
    None.

Usage:
    streamLiteFixtureControl.setStateLED("BLUE")

--]]
function StreamLiteFixtureControl.setStateLED(color)
    Log.LogInfo("======StreamLiteFixtureControl.resetLED======")
    local ret = RPCClient.callRPCFunc("lucifer.led_control", {"STATUS", color}, {}, 3000, fixtureRPCClientObj)
    if string.match(ret, "done") == nil then
        Log.LogInfo("StreamLiteFixtureControl.setStateLED: Set status led color to " .. color .. " fail.")
        return false
    end
    Log.LogInfo("StreamLiteFixtureControl.setStateLED: Set status led color to " .. color .. " successful.")
    return true
end

--[[
Description:
    Set uut LED to color.
Params:
    color<string>: uut LED color to set(BLUE, YELLOW, RED, GREEN).
Returns:
    None.

Usage:
    StreamLiteFixtureControl.setUUTLED("UUT1", "green")

--]]
function StreamLiteFixtureControl.setUUTLED(slotID, color)
    Log.LogInfo("======StreamLiteFixtureControl.setUUTLED======")
    local ret = RPCClient.callRPCFunc("lucifer.led_control", {slotID, color}, {}, 3000, fixtureRPCClientObj)
    if string.match(ret, "done") == nil then
        Log.LogInfo("StreamLiteFixtureControl.setStateLED: Set " .. slotID .. " led color to " .. color .. " fail.")
        return false
    end
    Log.LogInfo("StreamLiteFixtureControl.setStateLED: Set " .. slotID .. " led color to " .. color .. " successful.")
    return true
end

--[[
Description:
    lock or unlock fixture tray.
Params:
    state<string>: ON: lock fixture tray.
                   OFF: unlock fixture tray.
Returns:
    <boolean>: lock or unlock result.

Usage:
    local ret = StreamLiteFixtureControl.lockTray("ON")
    if not ret then
        ErrorFunction(ErrorCode.MotionErr,"eowynFixtureClient lockTray fail.")
        return
    else
        Log.LogInfo("eowynFixtureClient lockTray successful")
    end

--]]
function StreamLiteFixtureControl.lockTray(state)
    Log.LogInfo("======StreamLiteFixtureControl.lockTray======")
    local ret = RPCClient.callRPCFunc("lucifer.magnet_control", {string.lower(state)}, {}, 3000, fixtureRPCClientObj)
    if string.match(ret, "done") == nil then
        Log.LogInfo("StreamLiteFixtureControl.lockTray: Enable fixture lock fail.")
        return false
    end
    Log.LogInfo("StreamLiteFixtureControl.setStateLED: disable fixture lock successful.")
    return true
end

--[[
Description:
    Check fixture tray position.
Params:
    None.
Returns:
    <string>: fixture tray position.

Usage:
    local res = StreamLiteFixtureControl.checkTrayPosition()
    if (res == "TrayPositionDOWN") then
        Log.LogInfo("******Down OK,go to next step******")
        StreamLiteFixtureControl.setStateLED("GREEN")
        break
    else
        StreamLiteFixtureControl.trayUp(eowyn)
        StreamLiteFixtureControl.fixtureLock(eowyn, 0)
        StreamLiteFixtureControl.setStateLED("BLUE")
    end

--]]
function StreamLiteFixtureControl.checkTrayPosition()
    Log.LogInfo("======StreamLiteFixtureControl.checkTrayPosition======")
    local upSensorState = RPCClient.callRPCFunc("lucifer.up_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
    if upSensorState == 1 then
        Log.LogInfo("upSensorState: OK")
    elseif upSensorState == 0 then
        Log.LogInfo("upSensorState: NO")
    else
        Log.LogInfo("read upSensorState fail.")
    end
    local downSensorState = RPCClient.callRPCFunc("lucifer.down_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
    if downSensorState == 1 then
        Log.LogInfo("downSensorState: OK")
    elseif downSensorState == 0 then
        Log.LogInfo("downSensorState: NO")
    else
        Log.LogInfo("read downSensorState fail.")
    end
    local inSensorState = RPCClient.callRPCFunc("lucifer.in_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
    if inSensorState == 1 then
        Log.LogInfo("inSensorState: OK")
    elseif inSensorState == 0 then
        Log.LogInfo("inSensorState: NO")
    else
        Log.LogInfo("read inSensorState fail.")
    end
    local outSensorState = RPCClient.callRPCFunc("lucifer.out_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
    if outSensorState == 1 then
        Log.LogInfo("outSensorState: OK")
    elseif outSensorState == 0 then
        Log.LogInfo("outSensorState: NO")
    else
        Log.LogInfo("read outSensorState fail.")
    end
    local trayPosition
    if upSensorState == 1 and downSensorState == 0 and inSensorState == 1 and outSensorState == 0 then
        trayPosition = "TrayPositionIN"
    elseif upSensorState == 1 and downSensorState == 0 and inSensorState == 0 and outSensorState == 1 then
        trayPosition = "TrayPositionOUT"
    elseif upSensorState == 1 and downSensorState == 0 and inSensorState == 0 and outSensorState == 0 then
        trayPosition = "TrayPositionIDLE"
    elseif upSensorState == 0 and downSensorState == 1 and inSensorState == 1 and outSensorState == 0 then
        trayPosition = "TrayPositionDOWN"
    elseif upSensorState == 0 and downSensorState == 0 and inSensorState == 1 and outSensorState == 0 then
        trayPosition = "TrayPositionDUMMY"
    else
        trayPosition = "TrayPositionUnknown"
    end

    Log.LogInfo("StreamLiteFixtureControl.checkTrayPosition: " .. tostring(trayPosition))
    return trayPosition
end

--[[
Description:
    Check DUT sensor state.
Params:
    None.
Returns:
    <number>: DUT sensor state,1(have DUT) or -1(no DUT).
    <string>: DUT sensor state list.

Usage:
    local ret = StreamLiteFixtureControl.checkDUTSensor()
    if (ret == 1) then
        Log.LogInfo("******checkDUTSensor OK,will Down******")
    else
        Log.LogInfo("******checkDUTSensor Not OK,will UNLOCK******")
    end

--]]
function StreamLiteFixtureControl.checkDUTSensor(uutCheckList)
    Log.LogInfo("======StreamLiteFixtureControl.checkDUTSensor======")
    local state = -1
    local ret
    if uutCheckList then
        ret = RPCClient.callRPCFunc("lucifer.dut_sensor_read", {uutCheckList}, {}, 3000, fixtureRPCClientObj)
    else
        ret = RPCClient.callRPCFunc("lucifer.dut_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
    end
    if string.match(ret, "on") == nil then
        Log.LogInfo("StreamLiteFixtureControl.checkDUTSensor: DUT sensor state is not right.")
        return state, ret
    end
    Log.LogInfo("StreamLiteFixtureControl.checkDUTSensor: DUT sensor state is ok.")
    return 1, ret
end

--[[
Description:
    Fixture tray up.
Params:
    None.
Returns:
    <boolean>: fixture tray up result.

Usage:
    local ret = StreamLiteFixtureControl.trayUp()
    if not ret then
        ErrorFunction(ErrorCode.MotionErr,"trayUp fail.")
        return
    else
        Log.LogInfo("trayUp successful")
    end

--]]
function StreamLiteFixtureControl.trayUp()
    Log.LogInfo("======StreamLiteFixtureControl.trayUp======")
    local upSensorState = RPCClient.callRPCFunc("lucifer.up_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
    if upSensorState == 1 then
        StreamLiteFixtureControl.lockTray("on")
        return true
    elseif upSensorState == 0 then
        local inSensorState = RPCClient.callRPCFunc("lucifer.in_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
        if inSensorState ~= 1 then
            ErrorFunction(ErrorCode.MotionErr, "The fixture state need be IN State first!")
            return false
        end
        StreamLiteFixtureControl.lockTray("on")
        RPCClient.callRPCFunc("lucifer.fixture_up", {}, {}, 10000, fixtureRPCClientObj)
        -- detect sensor state duling 10s
        for _ = 1, 10 do
            delay(500) -- detect sensor state each 0.5s
            upSensorState = RPCClient.callRPCFunc("lucifer.up_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
            if upSensorState == 1 then
                Log.LogInfo("StreamLiteFixtureControl.trayUp: tary up OK.")
                return true
            end
        end
        ErrorFunction(ErrorCode.MotionErr, "Moving up timeout, please check fixture state!")
        return false
    else
        ErrorFunction(ErrorCode.MotionErr,
                      "Read up sensor gpio state fail when try to move up,comfirm whether disconnected fixture!")
        return false
    end
end

--[[
Description:
    Fixture tray down.
Params:
    None.
Returns:
    <boolean>: fixture tray down result.

Usage:
    local ret = StreamLiteFixtureControl.trayDown()
    if not ret then
        ErrorFunction(ErrorCode.MotionErr,"trayDown fail.")
        return
    else
        Log.LogInfo("trayDown successful")
    end

--]]
function StreamLiteFixtureControl.trayDown()
    Log.LogInfo("======StreamLiteFixtureControl.trayDown======")
    local downSensorState = RPCClient.callRPCFunc("lucifer.down_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
    if downSensorState == 1 then
        Log.LogInfo("StreamLiteFixtureControl.trayUp: Fixture is down state now.")
        return true
    elseif downSensorState == 0 then
        local inSensorState = RPCClient.callRPCFunc("lucifer.in_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
        if inSensorState ~= 1 then
            ErrorFunction(ErrorCode.MotionErr, "The fixture state need be IN State first!")
            return false
        end
        StreamLiteFixtureControl.lockTray("on")
        RPCClient.callRPCFunc("lucifer.fixture_down", {}, {}, 10000, fixtureRPCClientObj)
        -- detect sensor state duling 10s
        for _ = 1, 10 do
            delay(500) -- detect sensor state each 0.5s
            downSensorState = RPCClient.callRPCFunc("lucifer.down_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
            if downSensorState == 1 then
                Log.LogInfo("StreamLiteFixtureControl.trayDown: tary down OK.")
                return true
            end
        end
        ErrorFunction(ErrorCode.MotionErr, "Moving down timeout, please check fixture state!")
        return false
    else
        ErrorFunction(ErrorCode.MotionErr,
                      "Read down sensor state fail when try to move down,comfirm whether disconnected fixture!")
        return false
    end
end

--[[
Description:
    Fixture tray in.
Params:
    None.
Returns:
    <boolean>: fixture tray in result.

Usage:
    local ret = StreamLiteFixtureControl.trayIn()
    if not ret then
        ErrorFunction(ErrorCode.MotionErr,"trayIn fail.")
        return
    else
        Log.LogInfo("trayIn successful")
    end

--]]
function StreamLiteFixtureControl.trayIn()
    Log.LogInfo("======StreamLiteFixtureControl.trayIn======")
    local inSensorState = RPCClient.callRPCFunc("lucifer.in_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
    if inSensorState == 1 then
        Log.LogInfo("StreamLiteFixtureControl.trayIn: Fixture is in state now.")
        return true
    elseif inSensorState == 0 then
        local upSensorState = RPCClient.callRPCFunc("lucifer.up_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
        if upSensorState ~= 1 then
            ErrorFunction(ErrorCode.MotionErr, "The fixture have not be move up,please move up first!")
            return false
        end
        RPCClient.callRPCFunc("lucifer.fixture_in", {}, {}, 10000, fixtureRPCClientObj)
        -- detect sensor state duling 10s
        for _ = 1, 10 do
            delay(500) -- detect sensor state each 0.5s
            inSensorState = RPCClient.callRPCFunc("lucifer.in_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
            if inSensorState == 1 then
                Log.LogInfo("StreamLiteFixtureControl.trayIn: tary in OK.")
                return true
            end
        end
        ErrorFunction(ErrorCode.MotionErr, "Moving in timeout,please check fixture state!")
        return false
    else
        ErrorFunction(ErrorCode.MotionErr,
                      "Read in sensor gpio state fail when try to move down,comfirm whether disconnected fixture!")
        return false
    end
end

--[[
Description:
    Fixture tray out.
Params:
    None.
Returns:
    <boolean>: fixture tray out result.

Usage:
    local ret = StreamLiteFixtureControl.trayOut()
    if not ret then
        ErrorFunction(ErrorCode.MotionErr,"trayOut fail.")
        return
    else
        Log.LogInfo("trayOut successful")
    end

--]]
function StreamLiteFixtureControl.trayOut()
    Log.LogInfo("======StreamLiteFixtureControl.trayOut======")
    local outSensorState = RPCClient.callRPCFunc("lucifer.out_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
    if outSensorState == 1 then
        Log.LogInfo("StreamLiteFixtureControl.trayOut: Fixture is out state now.")
        return true
    elseif outSensorState == 0 then
        local upSensorState = RPCClient.callRPCFunc("lucifer.up_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
        if upSensorState ~= 1 then
            ErrorFunction(ErrorCode.MotionErr, "The fixture have not be move up,please move up first!")
            return false
        end
        RPCClient.callRPCFunc("lucifer.fixture_out", {}, {}, 10000, fixtureRPCClientObj)
        -- detect sensor state duling 10s
        for _ = 1, 10 do
            delay(500) -- detect sensor state each 0.5s
            outSensorState = RPCClient.callRPCFunc("lucifer.out_sensor_read", {}, {}, 3000, fixtureRPCClientObj)
            if outSensorState == 1 then
                Log.LogInfo("StreamLiteFixtureControl.trayOut: tary out OK.")
                return true
            end
        end
        ErrorFunction(ErrorCode.MotionErr, "Moving out timeout,please check fixture state!")
        return false
    else
        ErrorFunction(ErrorCode.MotionErr,
                      "Read out sensor gpio state fail when try to move down,comfirm whether disconnected fixture!")
        return false
    end
end

--[[
Description:
    Set fan speed.
Params:
    fanID<Number>:Fan index.
    speed<Number>:Fan speed to set.
Returns:
    <boolean>: fan speed set result.

Usage:
    local ret = StreamLiteFixtureControl.setFanSpeed(1, 10000)
    if not ret then
        ErrorFunction(ErrorCode.MotionErr,"Set fan speed fail.")
        return
    else
        Log.LogInfo("Set fan speed successful")
    end

--]]
function StreamLiteFixtureControl.setFanSpeed(fanID, speed)
    Log.LogInfo("======StreamLiteFixtureControl.setFanSpeed======")
    local ret = RPCClient.callRPCFunc("lucifer.set_fan_speed", {fanID, speed}, {}, 3000, fixtureRPCClientObj)
    if string.match(ret, "done") == nil then
        Log.LogInfo("StreamLiteFixtureControl.setFanSpeed: Set fan " .. tostring(fanID) .. " to " .. tostring(speed) ..
                        " fail.")
        return false
    end
    Log.LogInfo("StreamLiteFixtureControl.setFanSpeed: Set fan " .. tostring(fanID) .. " to " .. tostring(speed) ..
                    " successful.")
    return true
end

--[[
Description:
    Get fan speed.
Params:
    fanID<Number>:Fan index.
Returns:
    <boolean>: fan speed get result.

Usage:
    local ret = StreamLiteFixtureControl.getFanSpeed(1)
    if ret < 0 then
        ErrorFunction(ErrorCode.MotionErr,"Get fan speed fail.")
        return ret
    else
        Log.LogInfo("Get fan speed successful")
    end
    return ret

--]]
function StreamLiteFixtureControl.getFanSpeed(fanID)
    Log.LogInfo("======StreamLiteFixtureControl.get_fan_speed======")
    local ret = RPCClient.callRPCFunc("lucifer.get_fan_speed", {fanID}, {}, 3000, fixtureRPCClientObj)
    if ret < 0 then
        Log.LogInfo("StreamLiteFixtureControl.get_fan_speed: Get fan " .. tostring(fanID) .. " fail.")
    end
    Log.LogInfo(
        "StreamLiteFixtureControl.get_fan_speed: Get fan " .. tostring(fanID) .. " speed is " .. tostring(ret) ..
            " successful.")
    return ret
end

--[[
Description:
    detect fixture engagement.
Params:
    None.
Returns:
    None.

Usage:
    StreamLiteFixtureControl.detectFixtureEngagement()

--]]
function StreamLiteFixtureControl.detectFixtureEngagement(trayInCallback)
    Log.LogInfo("======StreamLiteFixtureControl.detectEngagement======")

    local checkFlag = false
    while true do
        Log.LogInfo("******detect engagement thread running******")
        local ret = StreamLiteFixtureControl.checkTrayPosition()
        if ret then
            if (ret == "TrayPositionIDLE") then
                checkFlag = true
            end
            if (checkFlag and ret == "TrayPositionIN") then
                StreamLiteFixtureControl.lockTray("on")
                StreamLiteFixtureControl.setStateLED("GREEN")
                local amICanDown
                local errorStr = nil
                if trayInCallback then
                    local status, result, errStr = xpcall(trayInCallback, debug.traceback, StreamLiteFixtureControl)
                    if status and result then
                        amICanDown = true
                    else
                        errorStr = errStr
                        amICanDown = false
                    end
                else
                    ret = StreamLiteFixtureControl.checkDUTSensor()
                    if (ret == 1) then
                        amICanDown = true
                    else
                        amICanDown = false
                    end
                end
                if amICanDown then
                    Log.LogInfo("******checkDUTSensor OK,will Down******")
                    StreamLiteFixtureControl.trayDown()
                    ret = StreamLiteFixtureControl.checkTrayPosition()
                    if (ret == "TrayPositionDOWN") then
                        Log.LogInfo("******Down OK,go to next step******")
                        StreamLiteFixtureControl.setStateLED("GREEN")
                        return true
                    else
                        StreamLiteFixtureControl.trayUp()
                        StreamLiteFixtureControl.lockTray("off")
                        StreamLiteFixtureControl.setStateLED("BLUE")
                    end
                else
                    Log.LogInfo("******checkDUTSensor Not OK, will UNLOCK******")
                    StreamLiteFixtureControl.lockTray("OFF")
                    StreamLiteFixtureControl.setStateLED("BLUE")
                end

                if errorStr == "ExitLoop" then
                    return false
                end
            elseif (ret == "TrayPositionDOWN" or ret == "TrayPositionDUMMY") then
                StreamLiteFixtureControl.trayUp()
                StreamLiteFixtureControl.lockTray("off")
                StreamLiteFixtureControl.setStateLED("BLUE")
            end
        else
            Log.LogInfo("StreamLiteFixtureControl checkTrayPosition return nil")
        end
        delay(2000)
    end
end

return StreamLiteFixtureControl
