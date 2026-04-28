-------------------------------------------------------------------
----***************************************************************
---- INVT Schooner CSV API
----***************************************************************
-------------------------------------------------------------------

--!@brief require Common module
local Json = require("Common/json")
local comFunc = require("Common/Utilities")
local FileOperation = require("Common/FileOperation")
local unitTool = require ("Common/UnitTool")
--!@brief require INVT module
local Log = require("INVT/Modules/SMTLoggingHelper")
local constant = require("INVT/constants")
-- local rpcClient = require("INVT/Modules/RPCClient")
-- local rpcClient = require("INVT/Modules/CoreBoard")
local rtLib = require("INVT/Modules/RTCommonLib")
-- local cbLib = require("INVT/Modules/ControlBit")
local feasaLib = require("INVT/Modules/Feasa")
local time = require("INVT/Modules/Time")
local pluginsLoader = require("INVT/Modules/PluginsLoader")
local runShellCmd = pluginsLoader.getPlugin("RunShellCommand")
local variableTab = pluginsLoader.getPlugin("VariableTable")
-- local SFCPlugin = pluginsLoader.getPlugin("SFC")
local fileUtil = require("ALE/FileUtils")
local StatsUtils = require("ALE/StatsUtils")
local StringUtils = require("ALE/StringUtils")
local dgResource = "USB0::0x1AB1::0x0646::DG8Q272401258::INSTR"
local vendorProxy = require("VendorProxy")
local rpcClient = vendorProxy.require("RPCClient")
local audioAna = Atlas.loadPlugin("RTAudioPlugin")
local DutCmdCore = require("INVT/Modules/DutCmdCore")
local DutCmdCoreUsb = require("INVT/Modules/DutCmdCoreUsbUart")



--------------------------------------------------------------------
-- !@ API table for CSV level table
local API = {}

-- !@brief skip func
function API.skip(input, additionalParameters)
    return true
end

function API.enableSine(params)
    Log.LogFlowDebug("enableSine params: "..comFunc.dump(params))
    local channel = params.channel
    local freq = params.freq
    local volt = params.volt
    local unit = params.unit
    local offsetVolt = params.offsetVolt
    local phase = params.phase
    local duty = 0
    local scriptPath = fileUtil.getAtlasHomeDir().. "/Modules/INVT/DG822.py"
    Log.LogFlowDebug("Script path is:".. scriptPath)
    cmd = string.format("python3 %s SINE %s %s %s %s %s %s %s -r %s", scriptPath, channel, freq, volt, unit, offsetVolt, phase, duty, dgResource)

    Log.LogFlowDebug("[Dg command] "..cmd)
    local retVal = runShellCmd.run(cmd, 3000).output
    Log.LogFlowDebug("[Dg Receive] "..retVal)
    time.sleep(0.5)

    return true
end

function API.enableSquare(params)
    Log.LogFlowDebug("enableSquare params: "..comFunc.dump(params))
    local channel = params.channel
    local freq = params.freq
    local volt = params.volt
    local unit = params.unit
    local phase = 0
    local offsetVolt = params.offsetVolt
    local duty = params.duty
    
    local scriptPath = fileUtil.getAtlasHomeDir().. "/Modules/INVT/DG822.py"
    Log.LogFlowDebug("Script path is:".. scriptPath)
    cmd = string.format("python3 %s SQUARE %s %s %s %s %s %s %s -r %s", scriptPath, channel, freq, volt, unit, offsetVolt, phase, duty, dgResource)

    Log.LogFlowDebug("[Dg command] "..cmd)
    local retVal = runShellCmd.run(cmd, 3000).output
    Log.LogFlowDebug("[Dg Receive] "..retVal)
    time.sleep(0.5)

    return true
end

function API.disableDg(params)
    Log.LogFlowDebug("disableDg params: "..comFunc.dump(params))
    local channel = params.channel

    local scriptPath = fileUtil.getAtlasHomeDir().. "/Modules/INVT/DG822.py"
    Log.LogFlowDebug("Script path is:".. scriptPath)
    cmd = string.format("python3 %s SINE %s %s %s %s %s %s %s -r %s -d 1", scriptPath, channel, 1000, 2, "VPP", 0, 0, 50, dgResource)

    Log.LogFlowDebug("[Dg command] "..cmd)
    local retVal = runShellCmd.run(cmd, 3000).output
    Log.LogFlowDebug("[Dg Receive] "..retVal)
    time.sleep(0.5)

    return true
end

function API.pulseWidthMeasure(params)
    Log.LogFlowDebug("pulseWidthMeasure params: "..comFunc.dump(params))
    local channel = params.channel or 0
    local startSignal = params.startSignal or 1
    local stopSignal = params.stopSignal or 1
    local timeout = params.timeout or 3
    local convertUnit = (params or {}).csvUnit
    local limitTable = (params or {}).limitTable
    local unit = (limitTable or {}).unit
    local duration = params.duration or 0.2

    local status, result = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.trboardStartMeasure", {channel, startSignal, stopSignal}, timeout)
    if not status then
        Log.LogError("Error executing RPC command: " .. tostring(result))
        error("Error executing RPC command: " .. tostring(result))
    end

    status, result = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.trboardStopMeasure", {channel, duration})

    if not status then
        Log.LogError("Error executing RPC command: " .. tostring(result))
        error("Error executing RPC command: " .. tostring(result))
    end

    result = result[1]

    if convertUnit and convertUnit ~= "" and unit and unit ~= "" then
        local convertStatus, convertedValue = xpcall(unitTool.convertUnit, debug.traceback, result, convertUnit, unit)
        if not convertStatus then
            Log.LogFlowDebug("Failed to convert unit from " .. convertUnit .. " to " .. unit)
            error("Failed to convert unit from " .. convertUnit .. " to " .. unit)
        end
        result = convertedValue
    end

    return result
end

function API.measureCurrentByPSU(params)
    Log.LogFlowDebug("measureCurrentByPSU params: "..comFunc.dump(params))
    local module = params.module
    local sample_rate = params.sample_rate or 5
    local count = params.count or 1
    local max_range = params.max_range or 5000
    local disUart = params.disUart
    local disLvs = params.disLvs
    local timeout = params.timeout or 3
    local convertUnit = (params or {}).csvUnit
    local limitTable = (params or {}).limitTable
    local unit = (limitTable or {}).unit
    local lowerLimit = limitTable.lowerLimit
    local upperLimit = limitTable.upperLimit


    if disUart then 
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"DUT_USBUART_EN", "DISCONNECT"}, timeout)
        time.sleep(0.5)
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"I2C_LV_SHIFT_DISABLE"}, timeout)
        time.sleep(1)
    end

    if disLvs then
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"I2C_LV_SHIFT_DISABLE"}, timeout)
        time.sleep(1)
    end

    local status, result = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.measure_current_with_psu", {module, sample_rate, count, max_range}, timeout)
    if not status then
        Log.LogError("Error executing RPC command: " .. tostring(result))
        error("Error executing RPC command: " .. tostring(result))
    end

    if result >= upperLimit * 0.8 then
        for i = 1, 2 do 
            xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"DUT_USBUART_EN"}, timeout)
            time.sleep(1)
            xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"I2C_LV_SHIFT_DISABLE", "DISCONNECT"}, timeout)
            time.sleep(1)
            xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"DUT_USBUART_EN", "DISCONNECT"}, timeout)
            time.sleep(1)
            xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"I2C_LV_SHIFT_DISABLE"}, timeout)
            time.sleep(1)
            status, result = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.measure_current_with_psu", {module, sample_rate, count, max_range}, timeout)
            if result <= upperLimit * 0.8 and result >= lowerLimit then
                break
            end
        end
    end

    -- if max_range ~= "5000mA" then
    --     status, resp = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.measure_current_with_psu", {module, 1000, 1, "5000mA"}, timeout)
    --     time.sleep(1)
    -- end

    if disUart then 
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"DUT_USBUART_EN"}, timeout)
        time.sleep(0.25)
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"I2C_LV_SHIFT_DISABLE", "DISCONNECT"}, timeout)
        time.sleep(0.25)
    end

    if disLvs then
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"I2C_LV_SHIFT_DISABLE", "DISCONNECT"}, timeout)
        time.sleep(0.5)
    end

    if convertUnit and convertUnit ~= "" and unit and unit ~= "" then
        local convertStatus, convertedValue = xpcall(unitTool.convertUnit, debug.traceback, result, convertUnit, unit)
        if not convertStatus then
            Log.LogFlowDebug("Failed to convert unit from " .. convertUnit .. " to " .. unit)
            error("Failed to convert unit from " .. convertUnit .. " to " .. unit)
        end
        result = convertedValue
    end

    return result
end

function API.measureVoltageByDMM(params)
    Log.LogFlowDebug("measureVoltageByDMM params: "..comFunc.dump(params))
    local rpcFunc = params.command
    local args = Json.decode((params or {}).args or "[]")
    local disUart = params.disUart
    local timeout = params.timeout or 3
    local convertUnit = (params or {}).csvUnit
    local limitTable = (params or {}).limitTable
    local unit = (limitTable or {}).unit


    if disUart then 
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"DUT_USBUART_EN", "DISCONNECT"}, timeout)
        time.sleep(1)
    end

    local status, result = xpcall(rpcClient.callRPCFunc, debug.traceback, rpcFunc, args, timeout)
    if not status then
        Log.LogError("Error executing RPC command: " .. tostring(result))
        error("Error executing RPC command: " .. tostring(result))
    end

    if disUart then 
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"DUT_USBUART_EN"}, timeout)
        time.sleep(0.5)
    end

    if convertUnit and convertUnit ~= "" and unit and unit ~= "" then
        local convertStatus, convertedValue = xpcall(unitTool.convertUnit, debug.traceback, result, convertUnit, unit)
        if not convertStatus then
            Log.LogFlowDebug("Failed to convert unit from " .. convertUnit .. " to " .. unit)
            error("Failed to convert unit from " .. convertUnit .. " to " .. unit)
        end
        result = convertedValue
    end

    return result
end

function API.dmmDatalogger(params)
    Log.LogFlowDebug("dmmDatalogger params: "..comFunc.dump(params))
    local channel = params.channel or "ch1"
    local scope = params.scope or "7000mv"
    local sampleRate = params.sampleRate or 50000
    local duration = params.duration or 500
    local fileName = params.fileName or "SINE.csv"
    local timeout = params.timeout or 20
    local convertUnit = (params or {}).csvUnit
    local limitTable = (params or {}).limitTable
    local unit = (limitTable or {}).unit

    local status, retVal = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.dataloggerWithDMM", {channel, scope, sampleRate, duration}, timeout)
    if not status then
        Log.LogError("Error executing RPC command: " .. tostring(retVal))
        error("Error executing RPC command: " .. tostring(retVal))
    end
    retVal = retVal[1]
    Log.LogFlowDebug(string.format("Data Length: "..tostring(#retVal)))

    local slotID = Device.systemIndex + 1
    local deviceName = "slot" .. slotID
    deviceName = mlbSn or deviceName
    local workingDirectory = Device.userDirectory .. "/"
    local fileName = deviceName .. "_" .. fileName
    local filePath = workingDirectory .. fileName
    local failureMsg = ""

    local csvFile = io.open(filePath, "a+")
    if csvFile then
        for i = 1, #retVal do
            csvFile:write(retVal[i] .. "\n")
        end
        csvFile:close()
    else
        helper.LogError("Open " .. fileName .. " fail.")
        return false
    end

    return filePath
end

local function _read_csv_to_float_table(file_path, filter)
    local data_table = {}
    local file, err = io.open(file_path, "r")
    if not file then
        error("无法打开文件 '" .. file_path .. "': " .. (err or "未知错误"))
    end
    local i = 0
    -- 按行读取文件
    for line in file:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and line ~= nil then -- 跳过空行
            num = tonumber(line)
            if num then
                i = i + 1
                table.insert(data_table, num)
                if filter and i == 16384 then
                    break
                end
            end
        end
    end

    file:close()
    return data_table
end

local function findSineWavePeaksAndValleys(data, epsilon)
    local eps = epsilon or 1e-10
    local peaks = {}
    local valleys = {}
    local n = #data
    
    if n < 3 then
        return peaks, valleys
    end
    
    local diffs = {}
    for i = 1, n-1 do
        diffs[i] = data[i+1] - data[i]
    end
    
    for i = 2, n-1 do
        local left_diff = diffs[i-1]
        local right_diff = diffs[i]
        
        if math.abs(left_diff) > eps and math.abs(right_diff) > eps then
            if left_diff > eps and right_diff < -eps then
                table.insert(peaks, data[i])
            elseif left_diff < -eps and right_diff > eps then
                table.insert(valleys, data[i])
            end
        end
    end
    return {StatsUtils.mean(peaks), StatsUtils.mean(valleys)}
end

local function findPeaksAndValleys(data, epsilon)
    local min, max = StatsUtils.minmax(data)
    local epsilon = epsilon or 0.005
    local total = max - min
    local max_table = {}
    local min_table = {}
    for k, v in pairs(data) do
        if v > max - (total * epsilon) then
            table.insert(max_table, v)
        end
        if v < min + (total * epsilon) then
            table.insert(min_table, v)
        end
    end

    return {StatsUtils.mean(max_table), StatsUtils.mean(min_table)}
end

function API.dmmMeasureRipple(params)
    Log.LogFlowDebug("dmmMeasureRipple params: "..comFunc.dump(params))
    local channel = params.channel or "ch0"
    local scope = params.scope or "7000mv"
    local sampleRate = params.sampleRate or 1000
    local duration = params.duration or 3000
    local fileName = params.fileName
    local net = params.net
    local resolution = params.resolution or 0.005
    local timeout = params.timeout or 20
    local convertUnit = (params or {}).csvUnit
    local limitTable = (params or {}).limitTable
    local unit = (limitTable or {}).unit
    local status = nil
    local retVal = nil

    xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {net}, timeout)
    if net:match("TO_RIPPLE_BOARD") then
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"RIPPLE_VOUT_TO_DMMCH0"}, timeout)
    end
    time.sleep(1)

    if not fileName then 
        status, retVal = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.measureVoltageWithDMM", {channel, scope, net, sampleRate, 1, 1}, timeout)
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {net, "DISCONNECT"}, timeout)
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"RIPPLE_VOUT_TO_DMMCH0", "DISCONNECT"}, timeout)
    else
        status, retVal = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.dataloggerWithDMM", {channel, scope, sampleRate, duration}, timeout)
        if not status then
            Log.LogError("Error executing RPC command: " .. tostring(retVal))
            error("Error executing RPC command: " .. tostring(retVal))
        end
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {net, "DISCONNECT"}, timeout)
        if net:match("TO_RIPPLE_BOARD") then
            xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"RIPPLE_VOUT_TO_DMMCH0", "DISCONNECT"}, timeout)
        end
        retVal = retVal[1]
        Log.LogFlowDebug(string.format("Data Length: "..tostring(#retVal)))

        local slotID = Device.systemIndex + 1
        local deviceName = "slot" .. slotID
        deviceName = mlbSn or deviceName
        local workingDirectory = Device.userDirectory .. "/"
        fileName = deviceName .. "_" .. fileName
        local filePath = workingDirectory .. fileName
        local failureMsg = ""

        local csvFile = io.open(filePath, "a+")
        if csvFile then
            for i = 1, #retVal do
                csvFile:write(retVal[i] .. "\n")
            end
            csvFile:close()
        else
            helper.LogError("Open " .. fileName .. " fail.")
            return false
        end
        time.sleep(0.1)
        local peakValley = findPeaksAndValleys(retVal, resolution)
        Log.LogFlowDebug("Peak value:", peakValley[1])
        Log.LogFlowDebug("Valley value:", peakValley[2])
        retVal = peakValley[1] - peakValley[2]
    end
    if net:match("TO_RIPPLE_BOARD") then
        retVal = retVal / 50.653
    end
    return retVal
end

function API.dmmStopDatalogger(params)
    Log.LogFlowDebug("dmmStartDatalogger params: "..comFunc.dump(params))
    local module = params.module or "dmm"
    local channel = params.channel or "ch0"
    local timeout = params.timeout or 20
    local fileName = params.fileName or "dmm_sampling"
    local limitTable = (params or {}).limitTable
    local unit = (limitTable or {}).unit

    local status, retVal = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.getSamplingData", {module, channel}, timeout)
    if not status then
        Log.LogError("Error executing RPC command: " .. tostring(retVal))
        error("Error executing RPC command: " .. tostring(retVal))
    end
    retData = retVal[1]
    Log.LogFlowDebug(string.format("Data Length: "..tostring(#retData)))

    -- status, retVal = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.stopDatalogger", {module}, timeout)
    -- if not status then
    --     Log.LogError("Error executing RPC command: " .. tostring(retVal))
    --     error("Error executing RPC command: " .. tostring(retVal))
    -- end

    local slotID = Device.systemIndex + 1
    local deviceName = "slot" .. slotID
    deviceName = mlbSn or deviceName
    local workingDirectory = Device.userDirectory .. "/"
    local fileName = deviceName .. "_" .. fileName .. ".csv"
    local filePath = workingDirectory .. fileName
    local failureMsg = ""

    local csvFile = io.open(filePath, "a+")
    if csvFile then
        for i = 1, #retData do
            csvFile:write(retData[i] .. "\n")
        end
        csvFile:close()
    else
        helper.LogError("Open " .. fileName .. " fail.")
        return false
    end

    return filePath
end

function API.getSBuild(param)
    local sn = param[1]
    if type(sn) == "table" then
        sn = sn[1]
    end
    Log.LogInfo("GetSBuild sn: ",sn)
    -- local sn = "DLCH54000B60000NFE"
    local ghJson = Json.decode(comFunc.fileRead("/vault/data_collection/test_station_config/gh_station_info.json"))
    local stationId = ghJson.ghinfo.STATION_ID
    local BobCatUrl = ghJson.ghinfo.SFC_URL
    local query_data = "c=QUERY_RECORD&sn="..sn.."&p=CONFIG"
    local cmd = "curl -d \""..query_data.."\" "..BobCatUrl
    Log.LogInfo("cmd: ",cmd)
    local RunShellCommand = Atlas.loadPlugin("RunShellCommand")
    local config = RunShellCommand.run(cmd)
    Log.LogInfo("return:",config)    
    config = config.output
    Log.LogInfo("output:",config) 
    local SBuild = string.match(config,".*CONFIG=(.+)")
    Log.LogInfo("SBuild from SFC:",SBuild)
    local innerFunc = function(attrKey, attrValue)
        local testResult = DataReporting.createAttribute(attrKey, attrValue)
        DataReporting.submit(testResult)
    end
    if SBuild then 
        SBuild = string.gsub(SBuild, "%s+", "")
        local build_evt = string.match(SBuild, "(.+)_.+")
        local build_config = string.match(SBuild, ".+_(.+)")
        
        Log.LogInfo("Parsed BUILD_EVENT:", build_evt)
        Log.LogInfo("Parsed BUILD_MATRIX_CONFIG:", build_config)

        local status, response = xpcall(innerFunc, debug.traceback, 'S_Build', tostring(SBuild))
        if not status then
            Log.LogError("create attribute fail!!! ", response)
            return false
        end

        status, response = xpcall(innerFunc, debug.traceback, 'BUILD_EVENT', tostring(build_evt))
        if not status then
            Log.LogError("create attribute fail!!! ", response)
            return false
        end

        status, response = xpcall(innerFunc, debug.traceback, 'BUILD_MATRIX_CONFIG', tostring(build_config))
        if not status then
            Log.LogError("create attribute fail!!! ", response)
            return false
        end
    else
        return false
    end
end

function API.readMLBSN(params)
    Log.LogFlowDebug("readMLBSN params: "..comFunc.dump(params))

    local commandStr = params.command
    local expect = params.expect
    local needParse = params.needParse
    local autoRecord = params.autoRecord
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local delimiter = params.delimiter
    local ifUseUsb = params.ifUseUsb
    local timeout = (params or {}).timeout and params.timeout or 5
    local status = nil
    local response = nil

    if ifUseUsb then 
        status, response = xpcall(DutCmdCoreUsb.sendAndParseCommandCore, debug.traceback, commandStr, expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
    else
        status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, commandStr, expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
    end

    if not status then
        Log.LogError("sendAndParseCommand failed,", response)
        return false
    end

    -- creat attribute MLBSN
    local attrKey = "MLBSN"
    local testResult = DataReporting.createAttribute(attrKey, response)
    DataReporting.submit(testResult)
    DataReporting.primaryIdentity(response)

    local status, ret = xpcall(API.getSBuild, debug.traceback, {response})
    if not status then
        Log.LogError("getSBuild failed,", ret)
        return false
    end

    return response
end

local function round(num)
    return num % 1 >= 0.5 and math.ceil(num) or math.floor(num)
end

function API.scanI2C(params)
    local testName = Device.test .. '_' .. Device.subtest
    local command = params.command
    local subsubtest = params.subsubtest
    local delimiter = params.delimiter
    local expect = params.expect
    local autoRecord = params.autoRecord
    local writeData = params.writeData or "11"
    local timeout = (params or {}).timeout and params.timeout or 5
    local status = nil 
    local response = nil 
    local ifUseUsb = params.ifUseUsb
    local DutCmdIns = nil
    local deviceTable = {}

    if ifUseUsb then
        DutCmdIns = DutCmdCoreUsb
    else
        DutCmdIns = DutCmdCore
    end

    status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, command, expect, "TRUE",
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
    if not status then
        Log.LogError("sendAndParseCommandCore failed: ", response)
        return false
    end

    if type(response) == "table" then
        for k, v in pairs(response) do
            deviceTable[k] = "0x"..v
        end
        return deviceTable
    end

    return "0x"..response
end

local function powerCycle(targetString, timeout, testName, subsubtest)
    xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.reset", {}, timeout)
    time.sleep(1)
    xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"DUT_PP_VSYS_TO_PSU_BATTERY_POS1"}, timeout)
    xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {"DUT_USBUART_EN"}, timeout)
    xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.enable_battery_output", {8000, 5000}, timeout)
    time.sleep(5)
    xpcall(DutCmdCore.detectCore, debug.traceback, targetString, timeout, testName, subsubtest)
    return true
end

function API.scanUlpod(params)
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local delimiter = params.delimiter
    local expect = params.expect
    local autoRecord = params.autoRecord
    local net = params.net
    local writeData = params.writeData or "11"
    local timeout = (params or {}).timeout and params.timeout or 5
    local status = nil 
    local response = nil 
    local ifUseUsb = params.ifUseUsb
    local DutCmdIns = nil
    local deviceTable = {}

    if ifUseUsb then
        DutCmdIns = DutCmdCoreUsb
    else
        DutCmdIns = DutCmdCore
    end

    xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {net}, timeout)
    time.sleep(1)

    status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "i2c scan i2c@ee000", expect, "TRUE",
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)

    if not status and response:match("Timed out waiting for response for command") then
        powerCycle("32muart", timeout, testName, subsubtest)
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {net}, timeout)
        time.sleep(1)
        status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "i2c scan i2c@ee000", expect, "TRUE",
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
        if not status then
            Log.LogError("sendAndParseCommandCore failed: ", response)
            return false
        end
    end
    deviceTable["Device1"] = "0x"..response["Device1"]

    xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {net, "DISCONNECT"}, timeout)
    time.sleep(1)

    status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "i2c scan i2c@ee000", expect, "TRUE",
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)

    if not status and response:match("Timed out waiting for response for command") then
        powerCycle("32muart", timeout, testName, subsubtest)
        status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "i2c scan i2c@ee000", expect, "TRUE",
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
        if not status then
            Log.LogError("sendAndParseCommandCore failed: ", response)
            return false
        end
    end

    deviceTable["Device2"] = "0x"..response["Device2"]

    return deviceTable
end

function API.flashTest(params)
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local delimiter = params.delimiter
    local expect = params.expect
    local autoRecord = params.autoRecord
    local writeData = params.writeData or "11"
    local timeout = (params or {}).timeout and params.timeout or 5
    local status = nil 
    local response = nil 
    local ifUseUsb = params.ifUseUsb
    local DutCmdIns = nil

    if ifUseUsb then
        DutCmdIns = DutCmdCoreUsb
    else
        DutCmdIns = DutCmdCore
    end

    status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "flash read gd25le32e@0 0x00", expect, "TRUE",
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
    if not status or response ~= "ff" then
        Log.LogError("flash read 0x00 failed,", response)
        return false
    end

    status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "flash write gd25le32e@0 0x00 "..writeData, expect, nil,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
    if not status then
        Log.LogError("flash write 0x00 failed,", response)
        return false
    end

    status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "flash read gd25le32e@0 0x00", expect, "TRUE",
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
    if not status or response ~= writeData then
        Log.LogError("flash read 0x00 failed,", response)
        return false
    end

    status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "flash erase gd25le32e@0 0x00", expect, nil,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
    if not status then
        Log.LogError("flash erase 0x00 failed,", response)
        return false
    end

    status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "flash read gd25le32e@0 0x00", expect, "TRUE",
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
    if not status or response ~= "ff" then
        Log.LogError("flash read 0x00 failed,", response)
        return false
    end

    return 1
end

function API.checkGPIOOutput(params)
    Log.LogFlowDebug("checkGPIOOutput params: "..comFunc.dump(params))

    local commandStr = params.command
    local expect = params.expect
    local needParse = params.needParse
    local autoRecord = params.autoRecord
    local config = params.config
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local delimiter = params.delimiter
    local net = params.net
    local timeout = (params or {}).timeout and params.timeout or 5
    local defaultDelay = 0.5
    local ifUseUsb = params.ifUseUsb
    local status = nil 
    local response = nil 
    local DutCmdIns = nil

    if ifUseUsb then
        DutCmdIns = DutCmdCoreUsb
    else
        DutCmdIns = DutCmdCore
    end

    if config then 
        status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "gpio conf "..commandStr:match("gpio%d %d*").." o", expect, needParse,
                                        autoRecord, timeout, testName, subsubtest, false, delimiter)
    end
    
    status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "gpio set "..commandStr, expect, needParse,
                                        autoRecord, timeout, testName, subsubtest, false, delimiter)
    if not status then
        Log.LogError("sendAndParseCommand failed,", response)
        return false
    end
    time.sleep(0.1)

    status, response = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.measureVoltageWithDMM", {"ch0", "7000mv", net, 5, 1, 1}, timeout)

    return response
end

function API.readDUTSensor(params)
    Log.LogFlowDebug("readDUTSensor params: "..comFunc.dump(params))

    local commandStr = params.command
    local expect = params.expect
    local needParse = params.needParse
    local autoRecord = params.autoRecord
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local delimiter = params.delimiter
    local net = params.net
    local config = params.config
    local timeout = (params or {}).timeout and params.timeout or 5
    local defaultDelay = 0.5
    local ifUseUsb = params.ifUseUsb
    local status = nil 
    local response = nil 

    local DutCmdIns = nil

    if ifUseUsb then
        DutCmdIns = DutCmdCoreUsb
    else
        DutCmdIns = DutCmdCore
    end

    if net then
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {net}, timeout)
        if net == "DUT_ULPOD_INT_NRF_L_1KPULLDOWN" then
            defaultDelay = 5
        end
        time.sleep(defaultDelay)
    end

    if config then 
        status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "gpio conf "..commandStr:match("gpio%d %d*").." i", nil, nil,
                                        autoRecord, timeout, testName, subsubtest, false, commandStr:match("gpio%d %d*"))
    end


    status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, commandStr, expect, needParse,
                                autoRecord, timeout, testName, subsubtest, false, delimiter)

    
    if not status then
        Log.LogError("sendAndParseCommand failed,", response)
        return false
    end

    xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {net, "DISCONNECT"}, timeout)

    if StringUtils.startsWith(commandStr, "sensor get") then
        response = round(tonumber(response))
    end

    return response

end

function API.driveGPIOByCCS(params)
    Log.LogFlowDebug("driveGPIOByCCS params: "..comFunc.dump(params))

    local commandStr = params.command
    local expect = params.expect
    local needParse = params.needParse
    local autoRecord = params.autoRecord
    local volt = params.volt or 1200
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local delimiter = params.delimiter
    local net = params.net
    local timeout = (params or {}).timeout and params.timeout or 5
    local defaultDelay = 2
    local ifUseUsb = params.ifUseUsb
    local status = nil 
    local response = nil 

    local DutCmdIns = nil

    if ifUseUsb then
        DutCmdIns = DutCmdCoreUsb
    else
        DutCmdIns = DutCmdCore
    end

    if net then
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {net}, timeout)
        time.sleep(0.5)
        xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.setup_source", {volt, 10}, timeout)
        time.sleep(defaultDelay)
    end

    -- if config then 
    --     status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, "gpio conf "..commandStr:match("gpio%d %d*").." i", nil, nil,
    --                                     autoRecord, timeout, testName, subsubtest, false, commandStr:match("gpio%d %d*"))
    -- end


    status, response = xpcall(DutCmdIns.sendAndParseCommandCore, debug.traceback, commandStr, expect, needParse,
                                autoRecord, timeout, testName, subsubtest, false, delimiter)

    
    if not status then
        Log.LogError("sendAndParseCommand failed,", response)
        return false
    end

    xpcall(rpcClient.callRPCFunc, debug.traceback, "openshort.reset", {}, timeout)
    xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.relay", {net, "DISCONNECT"}, timeout)

    return response

end

function API.readRSTWarn(params)
    Log.LogFlowDebug("readRSTWarn params: "..comFunc.dump(params))

    local commandStr = params.command
    local expect = params.expect
    local needParse = params.needParse
    local autoRecord = params.autoRecord
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local delimiter = params.delimiter
    local timeout = (params or {}).timeout and params.timeout or 2
    local startTime = time.time()
    local status = nil
    local response = nil

    while time.time() - startTime <= timeout do
        status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, commandStr, expect, needParse,
                                        autoRecord, timeout, testName, subsubtest, false, delimiter)
        if not status then
            Log.LogFlowDebug("sendAndParseCommand failed,", response)
            break
        else
            if response == "1" then
                break
            end
        end
    end

    return response
end

-- --- 将 14-bit 无符号值转换为有符号整数
-- local function signed_14bit(value)
--     value = bit.band(value, 0x3FFF)

--     if bit.band(value, 0x2000) ~= 0 then
--         return -bit.band(bit.bnot(value), 0x3FFF) - 1
--     end
--     return value
-- end

--- 将低字节和高字节组合并转换为 14-bit 有符号整数
-- local function parse_axis(low_byte, high_byte)
--     value = ("0x"..high_byte..low_byte)
--     Log.LogFlowDebug("value is: ", value)
--     value = tonumber(value)
--     local signed_value = nil
--     if value >= 0x8000 then
--         signed_value = value - 0x10000
--     else
--         signed_value = value
--     end
--     return signed_value
-- end


local function parse_axis(low_byte, high_byte)
    local value = tonumber("0x"..high_byte..low_byte)
    
    -- 向右移两位 (相当于除以4向下取整，这种方式兼容所有版本的Lua)
    local shifted_value = math.floor(value / 4)
    
    -- 此时 shifted_value 为14位无符号整数 (0 ~ 16383)
    -- 14位带符号整数的最高位(符号位)是 0x2000 (十进制8192)
    local signed_value = nil
    if shifted_value >= 0x2000 then
        signed_value = shifted_value - 0x4000
    else
        signed_value = shifted_value
    end
    return signed_value
end


local function to_binary_string(num, bits)
    local bin_str = ""
    for i = bits - 1, 0, -1 do
        local bit_val = math.floor(num / (2 ^ i)) % 2
        bin_str = bin_str .. tostring(bit_val)
    end
    return bin_str
end

local function parse_axis_shift2(low_byte, high_byte)
    local value = tonumber("0x"..high_byte..low_byte)
    local original_bin = to_binary_string(value, 16)
    
    local shifted_value = math.floor(value / 4)
    local shifted_bin = to_binary_string(shifted_value, 16)
    Log.LogFlowDebug("Bin\n" .. original_bin)
    Log.LogFlowDebug("Bin >> 2\n" .. shifted_bin)
    
    local signed_value = nil
    if shifted_value >= 0x2000 then
        signed_value = shifted_value - 0x4000
    else
        signed_value = shifted_value
    end
    Log.LogFlowDebug("Dec\n" .. tostring(signed_value))
    return signed_value
end


--- 解析加速度数据 (6 字节)
-- local function parse_accel_data(data)
--     if #data < 6 then
--         error("数据长度不足，需要 6 字节")
--     end

--     local x = parse_axis(data[1], data[2])
--     local y = parse_axis(data[3], data[4])
--     local z = parse_axis(data[5], data[6])

--     return {x, y, z}
-- end

local function parse_accel_data_2byte(data)
    local x = parse_axis_shift2(data[1], data[2])
    return x
end

--- 解析十六进制字符串
local function parse_hex_string(hex_str)
    local bytes = {}
    for byte_str in hex_str:gmatch("%x%x") do
        table.insert(bytes, byte_str)
    end
    return bytes
end

--- 解析十六进制字符串并转换为加速度数据
local function parse_i2c_data(hex_str)
    local bytes = parse_hex_string(hex_str)
    -- Log.LogFlowDebug("bytes is: ", bytes)
    -- return parse_accel_data(bytes)
    return parse_accel_data_2byte(bytes)
end


function API.accelSelfTest(params)
    Log.LogFlowDebug("diags params: "..comFunc.dump(params))

    local commandStr = params.command or nil
    local expect = params.expect or nil
    local needParse = params.needParse or nil
    local autoRecord = params.autoRecord or nil
    local delimiter = params.delimiter or nil
    local testName = Device.test .. '_' .. Device.subtest
    local subsubtest = params.subsubtest
    local timeout = params.timeout or 5
    local defaultDelay = 0.5
    local normalAccel = nil
    local selfTestAccel = nil
    local result = {}

    local decodeAccelData = function(inputStr)
        local retTable = nil
        local hex_str = inputStr:match(":%s*(([%x%s]+))")
        if hex_str then
            hex_str = hex_str:match("^%s*(.-)%s*$"):gsub("%s+", " ")
        end
        Log.LogFlowDebug("hex_str is: ", hex_str)
        retTable = parse_i2c_data(hex_str)
        return retTable
    end 

    local status = nil
    local response = nil
    local checkDRDY = nil
    -- accel self reset
    -- local status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "i2c write i2c@c6000 0x18 0x21 0x40", expect, needParse,
    --                                 autoRecord, timeout, testName, subsubtest, false, delimiter)
    -- if not status then
    --     Log.LogError("sendAndParseCommand failed,", response)
    --     return false
    -- end

    status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "i2c write i2c@c6000 0x18 0x21 0x0C", expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)

    status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "i2c write i2c@c6000 0x18 0x22 0x00", expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)

    status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "i2c write i2c@c6000 0x18 0x23 0x00", expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)

    status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "i2c write i2c@c6000 0x18 0x24 0x00", expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)

    status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "i2c write i2c@c6000 0x18 0x25 0x10", expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)

    status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "i2c write i2c@c6000 0x18 0x20 0x44", expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)

    time.sleep(0.1)


    local function waitForDRDY(command)
        local drdyTimeout = tonumber(params.drdyTimeout) or tonumber(timeout) or 5
        local pollInterval = tonumber(params.drdyPollInterval) or 0.05
        if drdyTimeout <= 0 then
            drdyTimeout = 0.1
        end
        if pollInterval <= 0 then
            pollInterval = 0.01
        end

        local attemptTimeout = drdyTimeout
        if attemptTimeout > 1 then
            attemptTimeout = 1
        end

        local function now()
            return tonumber(time.time()) or os.time()
        end

        local startTime = now()
        local lastResp = nil
        while (now() - startTime) < drdyTimeout do
            local ok, resp = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, command, expect, needParse,
                autoRecord, attemptTimeout, testName, subsubtest, false, delimiter)
            lastResp = resp
            if ok and resp and resp ~= false then
                local hexByte = tostring(resp):match(":%s*([%x][%x])")
                local byteVal = hexByte and tonumber(hexByte, 16) or nil
                if byteVal and (byteVal % 2) == 1 then
                    return ok, resp
                end
            end
            time.sleep(pollInterval)
        end
        return false, resp
        -- error("DRDY timeout, lastResp=" .. tostring(lastResp))
    end

    status, checkDRDY = waitForDRDY("i2c read i2c@c6000 0x18 0x27 1")

    if not status then
        Log.LogError("waitForDRDY failed,", checkDRDY)
        return false
    end                    

    status, normalAccel = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "i2c read i2c@c6000 0x18 0x28 6", expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)

    Log.LogFlowDebug(string.format("Accel string: "..comFunc.dump(normalAccel)))
    -- normalAccel = decodeAccelData(normalAccel)
    -- Log.LogFlowDebug(string.format("Accel data: "..comFunc.dump(normalAccel)))

    local addrTable = {x="0x28", y="0x2a", z="0x2c"}
    local normalAccel = {x={}, y={}, z={}}

    for k, v in pairs(addrTable) do
        for i =1, 8 do
            status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, string.format("i2c read i2c@c6000 0x18 %s 2", v), expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
            local data = decodeAccelData(response)
            if data then
                table.insert(normalAccel[k], data)
            end
            if #(normalAccel[k]) >= 5 then
                break
            end
        end
    end

    Log.LogFlowDebug(string.format("Accel data: "..comFunc.dump(normalAccel)))

    local normalAccelAvg = {x=StatsUtils.mean(normalAccel.x), y=StatsUtils.mean(normalAccel.y), z=StatsUtils.mean(normalAccel.z)}

    Log.LogFlowDebug(string.format("Accel Avg: "..comFunc.dump(normalAccelAvg)))

    status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "i2c write i2c@c6000 0x18 0x22 0x40", expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)



    status, checkDRDY = waitForDRDY("i2c read i2c@c6000 0x18 0x27 1")

    if not status then
        Log.LogError("waitForDRDY failed,", checkDRDY)
        return false
    end

    -- time.sleep(2)

    status, selfTestAccel = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "i2c read i2c@c6000 0x18 0x28 6", expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)


    Log.LogFlowDebug(string.format("Accel string: "..comFunc.dump(selfTestAccel)))

    -- selfTestAccel = decodeAccelData(selfTestAccel)

    -- Log.LogFlowDebug(string.format("Accel data: "..comFunc.dump(selfTestAccel)))

    local selfAccel = {x={}, y={}, z={}}

    for k, v in pairs(addrTable) do
        for i =1, 8 do
            status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, string.format("i2c read i2c@c6000 0x18 %s 2", v), expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)
            local data = decodeAccelData(response)
            if data then
                table.insert(selfAccel[k], data)
            end
            if #(selfAccel[k]) >= 5 then
                break
            end
        end
    end

    Log.LogFlowDebug(string.format("Accel data: "..comFunc.dump(selfAccel)))

    local selfAccelAvg = {x=StatsUtils.mean(selfAccel.x), y=StatsUtils.mean(selfAccel.y), z=StatsUtils.mean(selfAccel.z)}

    Log.LogFlowDebug(string.format("Accel Avg: "..comFunc.dump(selfAccelAvg)))


    status, response = xpcall(DutCmdCore.sendAndParseCommandCore, debug.traceback, "i2c write i2c@c6000 0x18 0x21 0x40", expect, needParse,
                                    autoRecord, timeout, testName, subsubtest, false, delimiter)

    local xValue = math.abs(normalAccelAvg.x - selfAccelAvg.x) * 0.488
    local yValue = math.abs(normalAccelAvg.y - selfAccelAvg.y) * 0.488
    local zValue = (math.abs(normalAccelAvg.z) - math.abs(selfAccelAvg.z)) * 0.488

    result = {x=xValue, y=yValue, z=zValue}
    Log.LogFlowDebug(string.format("Accel result: "..comFunc.dump(result)))

    return result
end

local function find_stable_level(waveform)
    local window_size = math.min(10, math.floor(#waveform / 4))
    if window_size < 2 then
        window_size = 2
    end
    
    local sum = 0
    for i = 1, window_size do
        sum = sum + waveform[i]
    end
    local avg = sum / window_size
    
    local sum_sq_diff = 0
    for i = 1, window_size do
        sum_sq_diff = sum_sq_diff + (waveform[i] - avg)^2
    end
    local std_dev = math.sqrt(sum_sq_diff / window_size)
    
    local tolerance = math.max(std_dev * 2, 0.01)
    
    local stable_start_idx = 1
    for i = 1, window_size do
        if math.abs(waveform[i] - avg) > tolerance then
            break
        end
        stable_start_idx = i
    end
    
    sum = 0
    for i = 1, stable_start_idx do
        sum = sum + waveform[i]
    end
    local actual_avg = sum / stable_start_idx
    
    return actual_avg, stable_start_idx
end

local function find_fall_start(waveform, stable_level, stable_start_idx)
    local search_start = stable_start_idx + 1
    
    local fall_threshold = stable_level - math.abs(stable_level * 0.01)
    
    for i = search_start, #waveform - 3 do
        local consecutive_fall = 0
        local total_checked = 0
        
        for j = i, math.min(i + 5, #waveform - 1) do
            total_checked = total_checked + 1
            if j + 1 <= #waveform and waveform[j] > waveform[j + 1] then
                consecutive_fall = consecutive_fall + 1
            end
        end
        
        if total_checked > 0 and consecutive_fall / total_checked >= 0.6 then
            local max_fall_in_window = 0
            for j = i, math.min(i + 5, #waveform) do
                local fall_amount = stable_level - waveform[j]
                if fall_amount > max_fall_in_window then
                    max_fall_in_window = fall_amount
                end
            end
            
            if max_fall_in_window > math.abs(stable_level * 0.01) then  -- 下降至少1%
                return i
            end
        end
    end
    
    for i = search_start, #waveform - 2 do
        if i > 1 and i < #waveform and 
           waveform[i] >= waveform[i-1] and waveform[i] >= waveform[i+1] and 
           waveform[i] > stable_level * 0.95 then  
            local continues_falling = true
            local next_points = math.min(5, #waveform - i)
            for j = 1, next_points do
                if i + j <= #waveform and waveform[i + j] > waveform[i + j - 1] then
                    continues_falling = false
                    break
                end
            end
            
            if continues_falling then
                return i
            end
        end
    end
    
    return -1 
end

local function find_fall_start_alternative(waveform)
    for i = 2, #waveform - 2 do
        if waveform[i] >= waveform[i-1] and waveform[i] >= waveform[i+1] then
            local next_val = waveform[i + 1]
            local prev_val = waveform[i - 1]
            
            if next_val < waveform[i] then
                local falling_count = 0
                local total_count = 0
                
                for j = i + 1, math.min(i + 3, #waveform - 1) do
                    total_count = total_count + 1
                    if waveform[j] > waveform[j + 1] then
                        falling_count = falling_count + 1
                    end
                end
                
                if total_count > 0 and falling_count / total_count >= 0.6 then
                    return i
                end
            end
        end
    end
    
    return -1
end

local function interpolate_crossing_point(waveform, idx_before, idx_after, target_value)
    local x1 = idx_before - 1
    local y1 = waveform[idx_before]
    local x2 = idx_after - 1
    local y2 = waveform[idx_after]
    
    -- 线性插值公式: x = x1 + (target_value - y1) * (x2 - x1) / (y2 - y1)
    local exact_idx = x1 + (target_value - y1) * (x2 - x1) / (y2 - y1)
    return exact_idx
end

local function calculate_fall_time(waveform, sample_rate, threshold)
    if #waveform < 4 then
        return nil, "波形数据太少", nil
    end
    
    if sample_rate <= 0 then
        return nil, "采样率必须大于0", nil
    end
    
    local stable_level, stable_start_idx = find_stable_level(waveform)
    
    local start_idx = find_fall_start(waveform, stable_level, stable_start_idx)
    
    if start_idx == -1 then
        start_idx = find_fall_start_alternative(waveform)
    end

    if start_idx == -1 then
        error("Can not find fall start point...")
    end
    
    local end_idx = start_idx
    local exact_end_idx = start_idx - 1
    
    for i = start_idx, #waveform - 1 do
        if waveform[i] >= threshold and waveform[i + 1] <= threshold then
            exact_end_idx = interpolate_crossing_point(waveform, i, i + 1, threshold)
            end_idx = i + 1
            break
        elseif waveform[i] <= threshold then
            exact_end_idx = i - 1
            end_idx = i
            break
        end
    end
    
    if exact_end_idx == start_idx - 1 then
        exact_end_idx = #waveform - 1
        end_idx = #waveform
    end
    
    local start_time = (start_idx - 1) / sample_rate
    local end_time = exact_end_idx / sample_rate
    local fall_time = end_time - start_time
    Log.LogFlowDebug("Start fall time: "..tostring(start_time))
    Log.LogFlowDebug("Fall end time: "..tostring(end_time))
    Log.LogFlowDebug("Fall_time: "..tostring(fall_time))

    
    return tonumber(string.format("%.3f", fall_time*1000))
end


function API.calculateDropTime(params)
    Log.LogFlowDebug("calculateDropTime params: "..comFunc.dump(params))
    local filePath = params.filePath or nil
    local sampleRate = params.sampleRate or 1000
    local threshold = params.threshold or 1000

    if not filePath then
        error("No File Path....")
    end

    local data = _read_csv_to_float_table(filePath, true)
    Log.LogFlowDebug("Data Length: "..tostring(#data))

    local status, retVal = xpcall(calculate_fall_time, debug.traceback, data, sampleRate, threshold)
    if not status then
        Log.LogError("Error: " .. tostring(retVal))
        error("Error: " .. tostring(retVal))
    end

    return retVal
end

local function calculate_pulse_time(waveform, sampleRate, highLevel, raiseFlg)
    local sum = 0
    for i = 1, 20 do
        sum = sum + waveform[i]
    end
    local avg = sum / 20
    local count = 0
    local sum = 0
    local result = 0
    local pulseFindFlg = false

    if raiseFlg then
        if avg > 100 then
            error("Waveform do not match Lowlevel...")
        end

        for i = 1, #waveform do
            if waveform[i] >= highLevel * 0.9 then
                count = count + 1
                sum = sum + waveform[i]
                pulseFindFlg = true
            elseif pulseFindFlg and waveform[i] < highLevel * 0.9 then
                break
            end
        end
    else
        if highLevel * 0.95 > avg or avg > highLevel * 1.05 then
            error("Waveform do not match Highlevel...")
        end

        for i = 1, #waveform do
            if waveform[i] <= highLevel * 0.8 then
                count = count + 1
                pulseFindFlg = true
            elseif pulseFindFlg and waveform[i] > highLevel * 0.8 then
                break
            end
        end
    end
    if not raiseFlg then
        result = count * (1000.0 / sampleRate)
    else
        result = sum / count
    end
    return result
end



function API.calculatePulseTime(params)
    Log.LogFlowDebug("calculatePulseTime params: "..comFunc.dump(params))
    local filePath = params.filePath or nil
    local sampleRate = params.sampleRate or 5000
    local highLevel = params.highLevel or 3300
    local raiseFlg = params.raiseFlg

    if not filePath then
        error("No File Path....")
    end

    local data = _read_csv_to_float_table(filePath, false)
    Log.LogFlowDebug("Data Length: "..tostring(#data))

    local status, retVal = xpcall(calculate_pulse_time, debug.traceback, data, sampleRate, highLevel, raiseFlg)
    if not status then
        Log.LogError("Error: " .. tostring(retVal))
        error("Error: " .. tostring(retVal))
    end

    return retVal
end

function API.analyzeAudioData(params)
    Log.LogFlowDebug("analyzeAudioData params: "..comFunc.dump(params))
    local filePath = params.filePath or nil
    local sampleRate = params.sampleRate or 50000
    if not filePath then
        error("No File Path....")
    end

    local data = _read_csv_to_float_table(filePath, 1)
    Log.LogFlowDebug(string.format("Data Length: "..tostring(#data)))

    local status, retVal = xpcall(audioAna.analyze, debug.traceback, data, sampleRate)
    if not status then
        Log.LogError("Error: " .. tostring(retVal))
        error("Error: " .. tostring(retVal))
    end

    local status, calData = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.read_calibration_cell", {50}, timeout)


    retVal.vpp = tonumber(retVal.vpp) * 11
    retVal.rms = tonumber(retVal.rms) * 11

    if status and calData.offset ~= 0 then
        retVal.vpp = retVal.vpp + calData.offset
    end

    return retVal
end

function API.calculateTemp(additionalParameters)

    local vTotal = additionalParameters.vTotal
    local vNTC = additionalParameters.vNTC
    local resPullUp = additionalParameters.resPullUp
    local B = additionalParameters.B
    local res25 = additionalParameters.res25

    if not vNTC or not vTotal or not B or not res25 or not resPullUp then
        Log.LogFlowDebug(("[ERROR]: Miss Parameters with: Vntc=%s, V1p8=%s, B=%s, R25=%s"):format(Vntc, V1p8, B, R25))
        return false
    end

    local Rx = (vNTC*resPullUp)/(vTotal-vNTC)
    local T25 = 25 + 273.15
    local temp = 1/(1/T25+math.log(Rx/res25)/B) - 273.15
    temp = round(temp)
    return temp
end

local function float_to_hex(num)
    -- 将浮点数转换为二进制字符串
    local bytes = string.pack("f", num)
    print(#bytes)
    -- 将二进制数据转换为16进制字符串
    local hex = ""
    for i = 1, #bytes do
        hex = string.format("%02X", bytes:byte(i)) .. hex
    end
    return hex
end

local function dec_to_bin(n, bits)
    local bin = ""
    n = math.floor(n)
    for i = bits - 1, 0, -1 do
        local bit = math.floor(n / (2^i))
        bin = bin .. tostring(bit)
        n = n - bit * (2^i)
    end
    return bin
end


local function hex_to_float(hex_str)
    hex_str = string.format("%X", hex_str)
    local binary_str = ""
    for i = 1, #hex_str do
        local hex_digit = string.upper(string.sub(hex_str, i, i))
        local bin_digit = dec_to_bin(tonumber(hex_digit, 16), 4)
        binary_str = binary_str .. bin_digit
    end
    
    if #binary_str ~= 32 then
        error("Invalid hex string length for single precision float")
    end
    
    local sign_bit = tonumber(string.sub(binary_str, 1, 1))
    local sign = (sign_bit == 1) and -1 or 1
    
    local exp_bits = string.sub(binary_str, 2, 9)
    local exp = tonumber(exp_bits, 2) - 127
    
    local mantissa_bits = string.sub(binary_str, 10, 32)
    local mantissa = 1.0  -- 隐含的1
    
    for i = 1, #mantissa_bits do
        local bit = tonumber(string.sub(mantissa_bits, i, i))
        if bit == 1 then
            mantissa = mantissa + 1 / (2^i)
        end
    end
    
    if exp == 128 and mantissa == 1.0 then  -- 全1指数
        if tonumber(mantissa_bits, 2) == 0 then  -- 尾数全0
            return sign == 1 and math.huge or -math.huge
        else
            return 0/0  -- NaN
        end
    end
    
    if exp == -127 and mantissa ~= 1.0 then
        exp = -126
        mantissa = tonumber("0." .. mantissa_bits, 2)
    end
    
    local result = sign * mantissa * (2^exp)
    return result
end


function API.floatToHex(params)
    Log.LogFlowDebug("floatToHex params: "..comFunc.dump(params))
    local inputs = params.inputs
    local number = tostring(inputs)
    local attributeKey = params.attributeKey

    if not number then
        Log.LogError("No inputs number Found..")
        return false
    end

    local status, retVal = xpcall(float_to_hex, debug.traceback, number)
    if not status or not retVal then
        Log.LogError("Transfer float to hex fail: ", retVal)
        return false
    end
    retVal = "0x" .. retVal
    if attributeKey then
        local attributeKeyTable = Device.getPlugin("AttributeKeyTable")
        attributeKeyTable.setVar(attributeKey, retVal)
        local testResult = DataReporting.createAttribute(attributeKey, retVal)
        DataReporting.submit(testResult)
    end

    return retVal
end

function API.hexToFloat(params)
    Log.LogFlowDebug("hexToFloat params: "..comFunc.dump(params))
    local inputs = params.inputs
    local number = tostring(inputs)

    if not number then
        Log.LogError("No inputs number Found..")
        return false
    end

    local status, retVal = xpcall(hex_to_float, debug.traceback, number)
    if not status or not retVal then
        Log.LogError("Transfer hex to float fail: ", retVal)
        return false
    end
    retVal = string.format("%.6f", retVal)

    return retVal
end

function API.getValueByKey(params)
    Log.LogFlowDebug("analyzeAudioData params: "..comFunc.dump(params))
    local inputTable = params.inputTable or nil
    local key = params.key or nil
    if not inputTable or not key then
        error("No Params....")
    end

    local result = inputTable[key]

    if not result then
        error("No key in table....")
    end


    -- num = tonumber(result)
    -- if num then
    --     result = num
    -- end
    return result
end

function API.checkUartID(params)
    Log.LogFlowDebug("checkUartID params: "..comFunc.dump(params))
    local cmd = "system_profiler SPUSBDataType"
    local device_name = "FT232R USB UART"
    local pid = nil
    local vid = nil
    local result = nil

    Log.LogFlowDebug("[USB command] "..cmd)
    local retVal = runShellCmd.run(cmd, 3000).output
    Log.LogFlowDebug("[USB Receive] "..retVal)

    local device_pattern = device_name .. ":%s*\n([%s%S]*)\n%s*[%a%s]*:"
    local device_block = retVal:match(device_pattern)
    Log.LogFlowDebug("[device_block] :"..device_block)

    if device_block then
        -- 在设备块中查找PID
        local pid_pattern = "Product%s+ID:%s*0[xX](%x+)"
        local pid_match = device_block:match(pid_pattern)
        Log.LogFlowDebug("[pid_match] :"..pid_match)
        if pid_match then
            pid = "0x" .. pid_match:upper()
        end
        
        -- 在设备块中查找VID
        local vid_pattern = "Vendor%s+ID:%s*0[xX](%x+)"
        local vid_match = device_block:match(vid_pattern)
        Log.LogFlowDebug("[vid_match] :"..vid_match)
        if vid_match then
            vid = "0x" .. vid_match:upper()
        end
        result = pid.."&"..vid
    end
    return result
end


function API.colseDg822(params)
    Log.LogFlowDebug("colseDg822 params: "..comFunc.dump(params))
    local bRet, retVal = xpcall(dgVisa.close, debug.traceback)
    time.sleep(0.5)
    if not bRet then
        Log.LogFlowDebug("colseDg822 failed with "..tostring(retVal))
        return false
    end
    return true
end


--! @brief generate pivot.csv and flow.log
function API.generateLogs(param)
    local sn = param.Input or DataReporting.getPrimaryIdentity()
    local LogsGenerator = require("LogFileGenerator")
    local userDirectoryPath = Device.userDirectory
    local systemLogFolder, replCount = string.gsub(userDirectoryPath, "user", "system")
    if replCount ~= 1 then
        local msg = "Failed to construct Atlas2 system log folder path"
        Log.LogFlowDebug(msg)
        return false
    end
    local deviceLogPath = systemLogFolder .. "/device.log"
    local slotID = "slot" .. string.match(Device.identifier, "S=%a*(%d+)")
    local pivotCsvPath = userDirectoryPath .. string.format("/%s_pivot.csv", sn)
    local flowLogPath = userDirectoryPath .. string.format("/%s_flow.log", sn)
    local failureSummary = userDirectoryPath .. string.format("/%s_failureSummary.csv", sn)

    LogsGenerator.generateFlowLog(deviceLogPath, slotID, flowLogPath, pivotCsvPath, failureSummary)
    --!@ if need show test item at logs, open it
    -- createTestAction(true, param, true)
end

-- !@brief get mix frimware version
-- !@param timeout: number type
-- !@param queryKey: string type
function API.mixVersion(param)
    local timeout = param.Timeout * 1000
    local queryKey = param.AdditionalParameters.queryKey
    local args = queryKey and {queryKey} or {}
    local bRet, retVal = xpcall(rpcClient.callRPCFunc, debug.traceback, args, timeout)
    if not bRet then
        Log.LogFlowDebug("Get mix Version failed with "..tostring(retVal))
        return false
    end
    return tostring(retVal)
end

-- !@brief get station info
-- !@param timeout: number type
-- !@param queryKey: string type
function API.getGHInfo(param)
    local queryKey = param.AdditionalParameters.queryKey
    local pattern = param.AdditionalParameters.pattern
    local retVal = constant.GH_INFO_GHINFO[queryKey]

    if not retVal then
        Log.LogFlowDebug("Can not get the GH info with "..queryKey)
        return false
    end
    if pattern then
        retVal = tostring(retVal):match(pattern)
    end
    if not retVal then
        Log.LogFlowDebug("Parse Value failed!")
        return false
    end
    return tostring(retVal)
end

-- !@brief user call PDCA amIOK api
function API.UOPCheck(param)
    local InteractiveView = Device.getPlugin("InteractiveView")
    local bRet, retVal = xpcall(ProcessControl.amIOK, debug.traceback)
    if bRet and retVal then
        local failMsg = string.match(retVal, "unit_process_check=(.*)\";")
        if failMsg then
            local viewConfig = {
                ["title"] = param.AdditionalParameters["subsubtestname"],
                ["message"] = failMsg,
                ["button"] = { "OK" }
            }
            InteractiveView.showView(Device.systemIndex, viewConfig)
            Log.LogFlowDebug(failMsg)
            return false
        end
    end
    return true
end

-- !@brief pause api
function API.pause(param)
    local InteractiveView = Device.getPlugin("InteractiveView")

    local viewConfig = {
            ["title"] = param["subsubtestname"],
            ["message"] = "Wait for continue!",
            ["button"] = { "continue" }
        }
    InteractiveView.showView(Device.systemIndex, viewConfig)
    return true
end

-- !@brief calculate string expression
function API.calculate(input, additionalParameters)
    Log.LogFlowDebug("calculate input: "..comFunc.dump(input))
    Log.LogFlowDebug("calculate additionalParameters: "..comFunc.dump(additionalParameters))

    local count = 0
    local elements = input
    for _ in tostring(additionalParameters.expression):gmatch("%%s") do count = count + 1 end

    if #elements ~= count then
        Log.LogFlowDebug("[Error] Element is not enough!")
        return false
    end

    local expression = tostring(additionalParameters.expression):format(table.unpack(elements))
    local bRet, retVal = pcall(rtLib.calculate, expression)

    if not bRet or tonumber(retVal) == nil then
        Log.LogFlowDebug(("calculate %s failed!"):format(expression))
        return false
    end
    Log.LogFlowDebug(("[Calculate] %s = %s"):format(expression, retVal))
    return tonumber(retVal)
end


-- !@brief check dut usb port is exists
-- !@returns bootTime
function API.checkUSBReady(param)
    local timeout = param.Timeout
    local groupNum, slotNum = string.match(Device.identifier, "G=(%d+):S=%a*(%d+)")
    local currSlot = "slot" .. slotNum
    local macMiniType = rtLib.getMacMiniType()
    local usbcTab = {
        J174 = {
            usbc01 = {
                slot1 = "/dev/cu.usbmodem1434101",
                slot2 = "/dev/cu.usbmodem1434201",
                slot3 = "/dev/cu.usbmodem1433101",
                slot4 = "/dev/cu.usbmodem1433201"
            },
            usbc03 = {
                slot1 = "/dev/cu.usbmodem1434103",
                slot2 = "/dev/cu.usbmodem1434203",
                slot3 = "/dev/cu.usbmodem1433103",
                slot4 = "/dev/cu.usbmodem1433203"
            }
        },
        J773 = {
            usbc01 = {
                slot1 = "/dev/cu.usbmodem314101",
                slot2 = "/dev/cu.usbmodem314201",
                slot3 = "/dev/cu.usbmodem313101",
                slot4 = "/dev/cu.usbmodem313201"
            },
            usbc03 = {
                slot1 = "/dev/cu.usbmodem314103",
                slot2 = "/dev/cu.usbmodem314203",
                slot3 = "/dev/cu.usbmodem313103",
                slot4 = "/dev/cu.usbmodem313203"
            }
        },
    }

    local usb01Port = usbcTab[macMiniType]["usbc01"][currSlot]
    local usb03Port = usbcTab[macMiniType]["usbc03"][currSlot]

    if not usb01Port or not usb03Port then
        Log.LogFlowDebug("Please Check USBC table and slot!")
        return false
    end

    local isReady = 0
    local startTime = rtLib.time()
    while rtLib.time() - startTime <= timeout do
        local retTab = runShellCmd.run("ls /dev/cu.*")
        Log.LogFlowDebug(rtLib.dump(retTab))
        if retTab.output:match(usb01Port) and retTab.output:match(usb03Port) then
            isReady = isReady + 1
        end
        if isReady >= 3 then
            break
        end
        rtLib.sleep(0.2)
    end

    if isReady < 3 then
        Log.LogFlowDebug("Can't find USBC port: "..usbPort)
        return false
    end
    return usbPort
end


-- !@brief check pluse width
-- !@param index: int type, plush width array index
-- !@returns numbers
function API.checkPluseWidth(param)
    local timeout = param.Timeout * 1000
    local channel = param.AdditionalParameters.channel
    local index = param.AdditionalParameters.index
    local csvUnit = param.AdditionalParameters.csvUnit
    local duration = param.AdditionalParameters.duration or 0.5

    local bRet, retTab = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.trboardStopMeasure", {channel, duration}, timeout)

    if not bRet or type(retTab) ~= "table" then
        Log.LogFlowDebug("Not capture pluse width wave!")
        return false
    end
    local retVal = tonumber(index) and retTab[tonumber(index)] or retTab[#retTab]
    return retVal
end



-- !@brief send Hex cmd and parse
-- !@param command: string type, hex command
-- !@param timeout: number type, communciate timeout
-- !@param inputVal: string type, write to dut info
-- !@param pattern: string type, lua regex
-- !@param hexback: boolean type, true only return retHex
-- !@param expectedKeyWord: string type
function API.diagsHex(param)
    local command = param.Commands or error("Please input Commands")
    local timeout = param.Timeout or 3
    local inputVal = param.Input or nil
    local channel = param.AdditionalParameters.channel or "USBC"
    local patternStr = param.AdditionalParameters.patternStr
    local patternHex = param.AdditionalParameters.patternHex
    local hexBack = param.AdditionalParameters.hexBack
    local expectedKeyWord = param.AdditionalParameters.expectedKeyWord
    local attributeKey = param.AdditionalParameters.attributeKey
    local clearBufferTag = param.AdditionalParameters.clearBufferTag
    local csvUnit = param.AdditionalParameters.csvUnit
    --!@ handle race command -> '055a...'
    command = command:gsub("%s", "")
    command = string.lower(command)
    if string.find(command, "{}") then
        assert(inputVal ~= nil, "Error empty input!")
        local inputHex = rtLib.ascii2hex(inputVal)
        local lenStr = string.format("%.2x", (#inputHex/2 + 6))
        command = command:gsub("{}", lenStr) .. inputHex
    end
    -- !@ mux communicate via uart
    dutCmd.commMux(channel)
    -- !@ make sure dut port is open
    dutCmd.close()
    dutCmd.open()
    -- !@ if need clear communicate buffer
    if clearBufferTag then dutCmd.clear(0.2) end
    -- !@ send hex command
    local retVal, retHex = dutCmd.sendRead(command, timeout, expectedKeyWord)
    -- !@ make sure dut port close
    dutCmd.close()
    if not retVal then
        Log.LogFlowDebug("Send command failed!")
        return false
    end

    --!@ parse response
    local parseVal = nil
    if patternStr then
        parseVal = tostring(retVal):match(patternStr)
    elseif patternHex then
        parseVal = tostring(retHex):match(patternHex)
    elseif hexBack then
        parseVal = retHex
    --!@ read side handle
    elseif command == "055a0600108053494445" then
        local tailVal = retHex:sub(-2)
        parseVal = tailVal == "01" and "R" or tailVal == "02" and "L" or tailVal
    elseif command == "055a0300132c1e" then
        local ntcTab = {}
        for d in retHex:sub(15, 22):gmatch("%w%w") do
            table.insert(ntcTab, d)
        end
        ntcTab = rtLib.table_reverse(ntcTab)
        parseVal = tonumber(table.concat(ntcTab), 16)
    elseif command == "055a0400142c0000" then
        --!@ check retHex response, retry total 3 times
        for i=1, 3 do   
            if #retHex == 14 and retHex:sub(-2) == "00" then break end
            time.sleep(0.5)
            retVal, retHex = dutCmd.sendRead(command, timeout, expectedKeyWord)
        end
        parseVal = #retHex == 14 and retHex:sub(-2) == "00" or false
    elseif command == "055a0600108042434647" then
        pattern = "%s(%w+%-?.*)$"
        parseVal = tostring(retVal):match(pattern)
        parseVal = parseVal == inputVal and parseVal or false
    elseif command == "055a060010804d4c42230d0a" then
        pattern = string.rep("%w", constant.Scanner.SnLength)
        parseVal = tostring(retVal):match(pattern)
        parseVal = parseVal == inputVal and parseVal or false
    elseif command == "055a0f00920f41542b455245473d4349440d0a" then
        pattern = "CID%:%s*(%d+)"
        parseVal = tostring(retVal):match(pattern)
    elseif command == "055a1000920f41542b53464c4153483d49440d0a" then
        pattern = "0x(%w%w)%,?0x(%w%w)%,?0x(%w%w)"
        local a, b, c = tostring(retVal):match(pattern)
        parseVal = "0x" .. string.upper(a..b..c)
    else
        parseVal = tostring(retVal):gsub("[\r\n]", "")
    end
    --!@ check parse value
    local bRet = parseVal and true or false
    --!@ for innerCall don't need to record!
    if param.innerCall then
        return parseVal
    end
    --!@ immediately upload attibute
    if attributeKey ~= nil and tostring(parseVal) ~= "nil" then
        local testResult = DataReporting.createAttribute(attributeKey, tostring(parseVal))
        DataReporting.submit(testResult)
    end

    return parseVal
end

-- !@brief get usb Device
-- !@returns string types
function API.getUSBDevice(param)
    local timeout = param.Timeout * 1000
    local site = "slot"..Device.systemIndex + 1
    local macMini = rtLib.getMacMiniType()
    local locationIDTab = {
        J64  = {slot1="0x00132100",slot2="0x00132100",slot3="0x00132100",slot4="0x00132100"},
        J174 = {slot1="0x14341000",slot2="0x14342000",slot3="0x14331000",slot4="0x14332000"},
        J773 = {slot1="0x03141000",slot2="0x03142000",slot3="0x03131000",slot4="0x03132000"},
    }
    local locationID = locationIDTab[macMini][site]
    Log.LogFlowDebug("[Slot LocationID] "..locationID)

    local targetTab = nil
    local startTime = rtLib.time()
    while time.time() - startTime < 10 do
        local devTab = rtLib.getUSBDeviceTree()
        for _, subDevice in pairs(devTab) do
            if type(subDevice) == "table" and subDevice["locationID"] == tonumber(locationID) then
                targetTab = subDevice
            end
            if targetTab ~= nil then break end
        end
        if targetTab ~= nil then
            targetTab["vendorID"] = ("0x%04x"):format(targetTab["vendorID"])
            targetTab["productID"] = ("0x%04x"):format(targetTab["productID"])
            break
        end
        time.sleep(0.2)
    end
    local bRet = type(targetTab) == "table" and true or false
    if not bRet then
        Log.LogFlowDebug("getUSBDevice failed")
        return false
    end
    Log.LogFlowDebug("[DeviceTable] "..rtLib.dump(targetTab))
    return targetTab
end

-- !@brief get usb Device
-- !@returns string types
function API.__getUSBDevice(param)
    local timeout = param.Timeout * 1000
    local cmd = "system_profiler SPUSBDataType"
    local site = "slot"..Device.systemIndex + 1
    local macMini = rtLib.getMacMiniType()
    local locationIDTab = {
        J64  = {slot1="0x14140000",slot2="0x14130000",slot3="0x14120000",slot4="0x14114000"},
        J174 = {slot1="0x14540000",slot2="0x14530000",slot3="0x14520000",slot4="0x14514000"}
    }
    local locationID = locationIDTab[macMini][site]
    local startTime = time.time()
    local retTab, retVal
    while time.time() - startTime < 10 do
        retTab = runShellCmd.run(cmd, timeout)
        retVal = retTab.output
        if string.find(retVal, locationID) then
            break
        end
        time.sleep(0.25)
    end
    retVal = retTab.error and retTab.error..retTab.output or retTab.output
    Log.LogFlowDebug("[ReturnCode]", retTab.returnCode)
    Log.LogFlowDebug("[Output]", retVal)

    return retVal
end

-- !@brief get Device vid pid
-- !@returns string types
function API.__getPidVid(param)
    local retStr, key = param.getInput()
    key = tostring(key):upper()
    assert(retStr ~= nil, "parameter is invalid, USBDevice is nil")
    assert(key == "PID" or key == "VID", "Parameter is invalid, ID is wrong")
    local site = "slot"..Device.systemIndex + 1
    local macMini = rtLib.getMacMiniType()
    local locationIDTab = {
        J64  = {slot1="0x14140000",slot2="0x14130000",slot3="0x14120000",slot4="0x14114000"},
        J174 = {slot1="0x14540000",slot2="0x14530000",slot3="0x14520000",slot4="0x14514000"}
    }
    local locationID = locationIDTab[macMini][site]
    local patt1st = "Beats%s*Solo.+Location%s*ID%:%s*"..locationID
    local deviceStr = retStr:match(patt1st)
    Log.LogFlowDebug("[Device]", deviceStr)
    local patt2nd = "Beats%s*Solo.+Product ID%:%s*(0x%w+)%s*Vendor ID%:%s*(0x%w+)%s*.*Location ID:%s*"..locationID
    local pid, vid = retStr:match(patt2nd)

    local retVal, bRet
    if key == "PID" then
        retVal = pid or false
    elseif key == "VID" then
        retVal = vid or false
    end

    bRet = retVal and true or false
    if not bRet then
        Log.LogFlowDebug("getPidVid failed")
        return false
    end
    return retVal
end


-- !@brief wrapper xavier I2C write
-- !@param timeout: rpc timeout
-- !@param IC: IO|LED|Gauge|Charger
-- !@param length: read back length
function API.i2cRead(param)
    local timeout = param.Timeout * 1000
    local IC = param.AdditionalParameters.IC
    local length = param.AdditionalParameters.length
    local slaveTab = { IO=0x24, LED=0x45, Gauge=0x55, Charger=0x6A }
    local slaveAddr = slaveTab[IC] or error("Undefined IC types")

    local retTab = rpcClient.callRPCFunc("wpi2c.read", {slaveAddr, length})
    local bRet = type(retTab) == "table"

    if not bRet then
        Log.LogFlowDebug("i2cRead failed")
        return false
    end
    return retTab
end

-- !@brief wrapper xavier I2C write
-- !@param timeout: rpc timeout
-- !@param IC: IO|LED|Gauge|Charger
-- !@param register: optional, target address
-- !@param data: write data
-- !@param needCheck: boolean, check write success
function API.i2cWrite(param)
    local timeout = param.Timeout * 1000
    local IC = param.AdditionalParameters.IC
    local register = param.AdditionalParameters.register or nil
    local data = param.AdditionalParameters.data
    local length = param.AdditionalParameters.length or 1
    local model = param.AdditionalParameters.model or false
    local slaveTab = { IO=0x24, LED=0x45, Gauge=0x55, Charger=0x6A }
    local slaveAddr = slaveTab[IC] or error("Undefined IC types")

    local wdData = register and {register, data} or {data}
    local retTab = rpcClient.callRPCFunc("wpi2c.write_and_read", {slaveAddr, wdData, length})

    --!@ check write table and read back table
    local bRet, retVal
    if model == "check" then
        local compareTab = rtLib.table_slice(wdData, 2)
        Log.LogFlowDebug("[Compare]"..comFunc.dump(compareTab))
        Log.LogFlowDebug("[readBack]"..comFunc.dump(retTab))
        bRet = comFunc.arrayCmp(retTab, compareTab)
        retVal = bRet and true or false
    elseif model == "NTC" then
        local bits43 = math.floor((tonumber(retTab[1]) or 0) / 8) % 4
        retVal = rtLib.dec2binary(bits43):sub(7,8)
        bRet = retVal and true or false
    else
        --!@ format return
        retVal = #retTab == 1 and retTab[1] or retTab
        bRet = retVal and true or false
    end
    if not bRet then
        Log.LogFlowDebug("i2cWrite failed")
        return false
    end
    return retVal
end


-- !@brief call RP2 RPC function
-- !@param timeout: rpc timeout
-- !@param Commands: mix rpc function
-- !@param args: Input or AdditionalParameters.args
-- !@param attributeKey: string type, if need add attribute
function API.callRP2Func(param)
    local timeout = param.Timeout or 3
    local mixFunc = param.Commands or error("Missing MixFunction")
    local csvUnit = param.AdditionalParameters.csvUnit
    local args = param.Input and {param.Input} or param.AdditionalParameters.args or {}
    local attributeKey = param.AdditionalParameters.attributeKey
    local rp2Proxy = Device.getPlugin("RP2Proxy")

    Log.LogFixtureControlStart(mixFunc, comFunc.dump(args), tostring(timeout))
    local bRet, retVal = xpcall(rp2Proxy.call, debug.traceback, mixFunc, args, timeout)
    Log.LogFixtureControlFinish(comFunc.dump(retVal))

    --!@ check rpc response
    if not bRet then
        Log.LogFlowDebug("Error: Call RP2 func failed!")
        return false
    end
    --!@ if need upload attribute
    if attributeKey then
        local M = require('Matchbox/Matchbox')
        local paraTab = {AdditionalParameters={attributeKey=attributeKey}, Input=tostring(retVal)}
        M.createAttribute(paraTab)
    end
    if not bRet then
        Log.LogFlowDebug("Error: Call RP2 func failed!")
        return false
    end
    return retVal
end

-- !@brief Over voltage protection
-- !@param timeout: timeout
-- !@param voltage: number type, the charger output voltage
function API.checkOVP(param)
    local timeout = param.Timeout or 60
    local voltage = param.AdditionalParameters.startVoltage
    local step = param.AdditionalParameters.step
    local netName = param.AdditionalParameters.netName
    local cycleDelay = 0.05
    local channel = "ch0"
    local mesurePath = "7000mv"

    local bRet = false
    local failMsg = nil
    local stepVolt = tonumber(voltage)
    local startTime = time.time()

    while time.time() - startTime <= timeout do
        if stepVolt >= 6001 then
            bRet = false
            failMsg = "Over Voltage"
            break
        end
        rpcClient.callRPCFunc("psu.enable_charger_output", {stepVolt})
        time.sleep(cycleDelay)
        local targetVoltage = rpcClient.callRPCFunc("mixdevice.measureVoltageWithDMM", {channel, mesurePath, netName})
        if stepVolt - targetVoltage > 100 then
            bRet = true
            break
        end
        --!@ optimize test cycle time
        if step >= 10 and stepVolt >= 5750 then step = 5 end
        stepVolt = stepVolt + step
    end

    if not bRet then
        failMsg = failMsg or "Timeout"
        Log.LogFlowDebug("Error: "..failMsg)
        return false
    end

    return stepVolt
end


function API.dataloggerWithPSU(param)
    local algorithm = param.AdditionalParameters.algorithm
    local duration = param.AdditionalParameters.duration
    local channel = param.AdditionalParameters.channel
    local sampleRate = param.AdditionalParameters.sampleRate or 1000
    local scope = param.AdditionalParameters.scope or "500ma"
    local index = param.AdditionalParameters.index or nil
    local header = param.AdditionalParameters.header or "Datalogger"
    local csvUnit = param.AdditionalParameters.csvUnit or "mA"
    local sn = param.Input or DataReporting.getPrimaryIdentity()
    local dataloggerDir = string.format("%s/Datalogger", Device.userDirectory)
    if not rtLib.path_exists(dataloggerDir) then
        rtLib.path_makedir(dataloggerDir)
    end
    local csvPath = string.format("%s/%s_%s.csv", dataloggerDir, sn, header)
    local module = "psu"
    local needCal = true
    local channelTab = {voltage="ch0", current="ch1"}
    local channel = channelTab[tostring(channel):lower()]
    local retTab = {}
    --!@ check channel is correct
    if channel == nil then
        Log.LogFlowDebug("Error: Undefined Channerl Type!")
        return false
    end
    --!@ set measure path
    rpcClient.callRPCFunc("psu.set_measure_path", {"battery", channel, scope})
    time.sleep(0.05)
    --!@ starting collection data
    rpcClient.callRPCFunc("mixdevice.startDatalogger", {module, channel, sampleRate})
    local startTime = time.time()
    while time.time() - startTime <= duration do
        time.sleep(0.25)
        local tempTab = rpcClient.callRPCFunc("mixdevice.getSamplingData", {module, channel, needCal, index}, 10000)
        retTab = rtLib.array_concat(retTab, tempTab)
    end
    rpcClient.callRPCFunc("mixdevice.stopDatalogger", {module})
    rtLib.dumpToCSV(csvPath, retTab, header)

    --!@ handle algorithm
    local retVal
    if algorithm == nil then
        Log.LogFlowDebug("Info: No algorithm specified, return raw data.")
        retVal = true
    elseif algorithm == "avg" then
        --!@ return average value
        retVal = rtLib.table_average(retTab)
    elseif algorithm == "med" then
        --!@ return median value
        retVal = rtLib.table_median(retTab)
    end
    return retVal
end

function API.dataloggerWithDMM(param)
    local duration = param.AdditionalParameters.duration
    local channel = param.AdditionalParameters.channel
    local scope = param.AdditionalParameters.scope
    local sampleRate = param.AdditionalParameters.sampleRate or 1000
    local header = param.AdditionalParameters.header or "Datalogger"
    local netName = param.AdditionalParameters.netName
    local sn = param.Input or DataReporting.getPrimaryIdentity()
    local dataloggerDir = string.format("%s/Datalogger", Device.userDirectory)
    if not rtLib.path_exists(dataloggerDir) then
        rtLib.path_makedir(dataloggerDir)
    end
    local csvPath = string.format("%s/%s_%s.csv", dataloggerDir, sn, header)
    local retTab = {}
    --!@ check channel is correct
    if scope == nil then
        Log.LogFlowDebug("Error: Undefined Scope Type!")
        return false
    end
    --!@ swtich to Test Point
    if netName then
        rpcClient.callRPCFunc("mixdevice.relay", {netName, "CONNECT"})
        rpcClient.callRPCFunc("mixdevice.relay", {"DUT_GND_TO_VIN_DMM_N", "CONNECT"})
        rpcClient.callRPCFunc("mixdevice.relay", {"DMM_CH12_N", "CONNECT"})
        rpcClient.callRPCFunc("mixdevice.relay", {"DMM_VIN2_SEL@TO_ADG2128", "CONNECT"})
    end
    --!@ starting collection data
    rpcClient.callRPCFunc("dmm.set_measure_path", {channel, scope})
    rpcClient.callRPCFunc("dmm.start_datalogger", {channel, sampleRate})
    local startTime = time.time()
    while time.time() - startTime <= duration do
        time.sleep(0.25)
        local tempTab = rpcClient.callRPCFunc("dmm.sample_datalogging", {true}, {}, 10000)[1]
        retTab = rtLib.array_concat(retTab, tempTab)
    end
    rpcClient.callRPCFunc("dmm.stop_datalogger")
    if netName then
        rpcClient.callRPCFunc("mixdevice.relay", {netName, "DISCONNECT"})
        rpcClient.callRPCFunc("mixdevice.relay", {"DUT_GND_TO_VIN_DMM_N", "DISCONNECT"})
        rpcClient.callRPCFunc("mixdevice.relay", {"DMM_CH12_N", "DISCONNECT"})
        rpcClient.callRPCFunc("mixdevice.relay", {"DMM_VIN2_SEL@TO_ADG2128", "DISCONNECT"})
    end
    rtLib.dumpToCSV(csvPath, retTab, header)
    Log.LogFlowDebug("Info: Datalogger with DMM completed.")
    return true
end

---------------------------------------------
---!@ Wrapper Atlas CSV Level Functions
---------------------------------------------
local function wrapperAPI(funTab)
    local newAPI = {}
    for name, func in pairs(funTab) do
        if type(func) == "function" then
            newAPI[name] = function(params)
                local result = {xpcall(func, debug.traceback, params)}
                if not result[1] then
                    if shouldCreateErrorRecord then
                        createRecord(result[1], params, result[2])
                    else
                        error(result[2])
                    end
                else
                    return table.unpack(result, 2)
                end
            end
        end
    end
    return newAPI
end
-- !@ wrapper API table
-- Will wrap on Common.lua SMTActionHelper
-- API = wrapperAPI(API)


return API
