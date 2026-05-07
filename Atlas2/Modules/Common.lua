-------------------------------------------------------------------
----***************************************************************
---- Station Common Schooner CSV APIs
----***************************************************************
-------------------------------------------------------------------

local time = require("Time")
local json = require("Common/json")
local Log = require("Common/logging")
local comFunc = require("Common/Utilities")
local unitTool = require ("Common/UnitTool")
local vendorProxy = require("VendorProxy")
local constant = require("INVT/constants")
local pluginsLoader = require("INVT/Modules/PluginsLoader")
local runShellCmd = pluginsLoader.getPlugin("RunShellCommand")


-- !@brief StationComm base on vendor CSV APIs
local StationComm = vendorProxy.getCSVAPIs()

-- !@brief get command value from input
local function processCommandInput(input)
    local commandStr
    if type(input) == "table" then
        if input["command"] ~= nil then
            commandStr = input["command"]
        else
            for _, item in pairs(input) do
                commandStr = commandStr .. item
            end
        end
    else
        commandStr = input
    end
    return commandStr
end

-- !@brief Send an RPC command using the VendorProxy.callRPCFunc function
-- !@param input (string or table) The RPC command to be sent. If it's a table, it should contain a "command" key.
-- !@param additionalParameters (table) Optional parameters, such as timeout.
-- !@return (table or boolean) Returns the result table if the command is successful, otherwise returns false.
function StationComm.callRPCFunc(input, additionalParameters)
    Log.LogFlowDebug("callRPCFunc input: "..comFunc.dump(input))
    Log.LogFlowDebug("callRPCFunc additionalParameters: "..comFunc.dump(additionalParameters))
    
    local rpcFunc = processCommandInput(input)
    if not rpcFunc or rpcFunc == "" then
        Log.LogError("Invalid command input")
        return false
    end

    if type(input) == "table" and input["command"] then
        additionalParameters = input
    end

    local args = json.decode((additionalParameters or {}).args or "[]")
    local timeout = (additionalParameters or {}).timeout or 3
    local needParser = (additionalParameters or {}).needParser
    local expectedKeyWord = (additionalParameters or {}).expectedKeyWord
    local convertUnit = (additionalParameters or {}).csvUnit
    local limitTable = (additionalParameters or {}).limitTable
    local unit = (limitTable or {}).unit
    local tableIndex = additionalParameters.tableIndex or nil

    local rpcClient = vendorProxy.require("RPCClient")
    local status, result = xpcall(rpcClient.callRPCFunc, debug.traceback, rpcFunc, args, timeout)

    -- confirm callRPCFunc rpcFunc success
    if not status or string.find(comFunc.dump(result), "Error") or string.find(comFunc.dump(result), "False") then
        Log.LogError("Error executing RPC command: " .. tostring(result))
        return false
    end

    -- parse and return one value with MDParser
    if needParser then
        local MDParser = Device.getPlugin("MDParser")
        -- execute parse function
        local bRet, pData = xpcall(MDParser.parse, debug.traceback, rpcFunc, tostring(result))
        if not bRet then
            Log.LogFlowDebug("MDParser response failed: " .. tostring(rpcFunc))
            return false
        end
        for _, v in pairs(pData) do
            if v ~= nil then
                result = comFunc.trim(v)
                Log.LogFlowDebug("Parse passed! result= " .. tostring(v))
            else
                Log.LogFlowDebug("Parse failed!")
                error("Parse failed!")
            end
        end
    end

    -- parse the value with expectedKeyWord
    if expectedKeyWord then
        if string.find(string.lower(tostring(result)), string.lower(tostring(expectedKeyWord))) then
            Log.LogFlowDebug("ok: find the expected key word")
        else
            Log.LogFlowDebug("error: can't find the expected key word")
            error("can't find the expected key word")
        end
    end

    if type(result) == "table" and tableIndex then 
        result = result[tableIndex]
    end
    
    -- Convert unit if necessary
    if convertUnit and convertUnit ~= "" and unit and unit ~= "" then
        local convertStatus, convertedValue = xpcall(unitTool.convertUnit, debug.traceback, result, convertUnit, unit)
        if not convertStatus then
            Log.LogFlowDebug("Failed to convert unit from " .. convertUnit .. " to " .. unit)
            return false
        end
        result = convertedValue
    end

    return result
end

-- !@brief delay function, wrap delay function in Time.lua
-- !@param delay ms from Input
function StationComm.delay(timeInMs)
    time.sleep_ms(timeInMs)
    return true
end

-- !@brief staggerDelay function, wrap staggerDelay function in Time.lua for passing identifier argument
-- !@param delay ms from Input
function StationComm.staggerDelay(timeInMs)
    local slotID = string.match(Device.identifier, "S=%a*(%d+)")
    local identifier = constant.STAGGER_DELAY_IDENTIFIER and constant.STAGGER_DELAY_IDENTIFIER[tostring(slotID)] or
                           DEFAULT_IDENTIFIER
    local id = "identifier-for-stagger-delay" .. "-" .. identifier
    local ret = time.staggerDelay(timeInMs, id)
    return ret
end

-- !@brief schooner CSV API
-- !@brief create dut attribute
-- !@param Input variable string as attributeValue and attributeKey in additionalParameters is needed
function StationComm.createAttr(additionalParameters)
    Log.LogFlowDebug("createAttr additionalParameters: "..comFunc.dump(additionalParameters))
    local innerFunc = function(attrKey, attrValue)
        local testResult = DataReporting.createAttribute(attrKey, attrValue)
        DataReporting.submit(testResult)
    end
    local status, result = xpcall(innerFunc, debug.traceback, additionalParameters["attributeKey"], tostring(additionalParameters["attributeValue"]))
    if not status then
        Log.LogError("create attribute fail!!! ", result)
        return false
    else
        return true
    end
end

-- !@brief schooner CSV API
-- !@brief query station info
-- !@param keyToQuery string as keyToQuery in additionalParameters is needed
function StationComm.stationInfo(keyToQuery)
    local valid, result

    if keyToQuery == "fixture_id" then
        local stationInfo = Device and Device.getPlugin("StationInfo") or Atlas.loadPlugin("StationInfo")
        valid, result = xpcall(stationInfo["station_id"], debug.traceback)
        local headID = string.match(Device.identifier, "S=%a*(%d+)")
        DataReporting.fixtureID(result, headID)
    elseif keyToQuery == "station_name" then
        local stationInfo = Device and Device.getPlugin("StationInfo") or Atlas.loadPlugin("StationInfo")
        valid, result = xpcall(stationInfo["gh_station_name"], debug.traceback)
    elseif keyToQuery == "vendor_id" then
        result = vendorProxy.getVendorID()
    elseif keyToQuery == "channel_id" then
        result = string.match(Device.identifier, "S=%a*(%d+)")
    elseif keyToQuery == "mix_fw_version" then
        local rpcClient = vendorProxy.require("RPCClient")
        valid, result = xpcall(rpcClient.callRPCFunc, debug.traceback, "mixdevice.mixVersion", {}, 3)
        result = result.MIX_FW_PACKAGE
    elseif keyToQuery == "macmini" then
        local cmd = "sysctl hw.model"
        local fd = io.popen(cmd)
        local resp = fd:read("*a")
        fd:close()
        Log.LogInfo("hw.model resp : ", resp)
        if string.find(resp, "Macmini6,2") then
            result = "J50"
        elseif string.find(resp, "Macmini7,1") then
            result = "J64"
        elseif string.find(resp, "Macmini8,1") then
            result = "J174"
        elseif string.find(resp, "Mac14,12") then
            result = "J474"
        elseif string.find(resp, "Macmini9,1") then
            result = "274"
        elseif string.find(resp, "Mac14,3") then
            result = "J473"
        elseif string.find(resp, "Mac16,11") then
            result = "J773"
        else
            result = "Can't identify macmini model"
            Log.LogInfo(string.format('Can\'t identify macmini model : [%s] ', resp))
            Log.LogError(result)
            return false
        end
    else
        local stationInfo = Device and Device.getPlugin("StationInfo") or Atlas.loadPlugin("StationInfo")
        valid, result = xpcall(stationInfo[keyToQuery], debug.traceback)
        if not valid then
            Log.LogError("Get station info failed: ", result)
            return false
        end
    end
    return result
end

-- !@brief schooner CSV API
-- !@brief query UOP
function StationComm.queryUOP()
    local status, result = xpcall(ProcessControl.amIOK, debug.traceback)
    if not status then
        Log.LogError("query UOP fail!!! ", result)
        return false
    else
        return true
    end
end

-- !@brief query attribute from SFC base on the query key
local function getAttrFromSFC(attrName, sn)
    local dutSN = sn

    if type(dutSN) == "string" then
        -- case1: TP input both attribute key and SN, check if input SN is valid
        if dutSN == "" then
            error("Invalid parameter: input sn cannot be an empty string")
        end
    else
        -- case2: TP only input attribute key, sn type is table, get SN via DataReporting.getPrimaryIdentity()
        dutSN = DataReporting.getPrimaryIdentity()
    end

    if not dutSN then
        error("getPrimaryIdentity mlbsn error!")
    end
    local stationID = stationInfo.station_id()
    local status, attrTable = xpcall(sfc.getAttributesByStationID, debug.traceback, dutSN, stationID, {attrName})

    if not status or attrTable == nil or attrTable[attrName] == nil or attrTable[attrName] == "" then
        error("Get attribute " .. attrName .. " failed from SFC.")
    end
    Log.LogInfo("attrTable: ", comFunc.dump(attrTable))
    return attrTable[attrName]
end

-- !@brief query sbuild attribute from SFC directly
function StationComm.querySbuild()
    local attrName = "sbuild"
    local status, attrValue = xpcall(getAttrFromSFC, debug.traceback, attrName)
    if status and attrValue ~= false then
        local project, build, config = string.match(attrValue, "(.+)-(%w+)_(%w+)")
        Log.LogInfo("<project>: " .. project .. " <build stage>: " .. build .. " <build config>: " .. config)
        return project, build, config
    else
        Log.LogError("querySbuild failed, ", result)
        return false
    end
end

-- !@brief schooner CSV API
-- !@brief internal submitSerialNumber function
-- !@brief support two parameters type - table or string case for different purpose
function StationComm.submitSerialNumber(additionalParameters)
    local sn = type(additionalParameters) == 'table' and additionalParameters.SN or additionalParameters
    if sn == "" and sn == nil then
        Log.LogError("sn is nil, please check")
        return false
    end

    local innerFunc = function (sn)
        DataReporting.primaryIdentity(sn)
        -- local variableTable = Device and Device.getPlugin("VariableTable")
        -- local startTime = variableTable.getVar("startTime")
        -- if not startTime then
        --     error("Failed to get startTime, please check the defined of startTime.")
        -- end
        -- -- Update the start time of the test, the startTime data is defined after fixture lock in GroupFunctions.lua
        -- DataReporting.startTime(startTime, "yyyy-MM-dd HH:mm:ss")
        -- schooner sequence will auto set limits version
        local isSchooner = true
        if not isSchooner then
            local constants = vendorProxy.getConstants()
            local overlayVer = constants.STATION_INFO.stationOverlay
            local retTab = comFunc.splitString(overlayVer, " ")
            local limitVer = retTab[#retTab]
            Log.LogInfo("limitVer Version is:", limitVer)
            DataReporting.limitsVersion(limitVer)
        end
    end

    local status, result = xpcall(innerFunc, debug.traceback, sn)
    if not status then
        Log.LogError("submitSerialNumber failed, ", result)
        return false
    else
        return true
    end
end

-- !@brief schooner CSV API
-- !@brief internal getPrimaryIdentity function
-- !@brief return sn
function StationComm.getPrimaryIdentity()
    local status, result = xpcall(DataReporting.getPrimaryIdentity, debug.traceback)
    if not status then
        Log.LogError("getPrimaryIdentity failed, ", result)
        return false
    else
        return result
    end
end

--! @generate pivot.csv and flow.log and failure.csv
local function generatePivotLogs()
    local logFileGenerator = require("PivotFileGenerator")
    local serialNumber = DataReporting.getPrimaryIdentity()
    local userDirectoryPath = Device.userDirectory
    local systemLogFolder, replCount = string.gsub(userDirectoryPath, "user", "system")
    if replCount ~= 1 then
        error("Failed to construct Atlas2 system log folder path")
    end
    local deviceLogPath = systemLogFolder .. "/device.log"
    local slotID = "slot" .. string.match(Device.identifier, "S=%a*(%d+)")
    local pivotCsvPath = string.format("%s/%s_pivot.csv", userDirectoryPath, serialNumber)
    local flowLogPath = string.format("%s/%s_flow.log", userDirectoryPath, serialNumber)
    local failureSummaryPath = string.format("%s/%s_failure.csv", userDirectoryPath, serialNumber)
    logFileGenerator.generateFlowLog(deviceLogPath, slotID, flowLogPath, pivotCsvPath, failureSummaryPath)
end

-- !@brief schooner CSV API
-- !@brief Upload log to insight
function StationComm.addLogToInsight()
    local status, result = xpcall(generatePivotLogs, debug.traceback)
    if not status then
        Log.LogError("generatePivotLogs failed, ", result)
        return false
    end
    Archive.addPathName(Device.userDirectory, Archive.when.deviceFinish)
    return true
end

local function generateUploadCmd(url, sn, test_station_name, station_id, start_time, stop_time, result, result_table)
    local data = {
        sn = sn,
        c = "ADD_ATTR",
        test_station_name = test_station_name,
        station_id = station_id,
        start_time = start_time,
        stop_time = stop_time,
        result = result,
    }

    for k, v in pairs(result_table) do
        data[k] = v
    end

    local keys = {"sn", "c", "test_station_name", "station_id", "start_time", "stop_time", "result"}
    for k in pairs(result_table) do
        table.insert(keys, k)
    end

    local queryString = ""
    for _, key in ipairs(keys) do
        local value = data[key]
        queryString = queryString .. string.format("%s=%s&", key, value)
    end
    queryString = string.sub(queryString, 1, -2)
    return string.format("curl %s -d \"%s\"", url, queryString)
end

local function gettimes(timefile)
    local ftcsv = require('Common/ftcsv')
    local timerecords = ftcsv.parse(timefile, ',')
    local starttime = os.time()
    local stoptime = 0
    for _, record in ipairs(timerecords) do
        starttime = (starttime < tonumber(record.StartTime)) and starttime or tonumber(record.StartTime)
        stoptime = (stoptime > tonumber(record.StopTime)) and stoptime or tonumber(record.StopTime)
    end
    Log.LogInfo(starttime, stoptime)
    return starttime, stoptime
end

local function uploadInfo(sn, result, resultTable, url)
    -- local url = "http://10.32.36.70/api/workflowcenter/anonymous/v1/bobcat/postv2"
    local stationInfo = Atlas.loadPlugin("stationInfo")
    local testStationName = stationInfo.product() .. " " .. stationInfo.station_type()
    local stationID = stationInfo.station_id()
    local userDirectoryPath =  Device.userDirectory
    local systemDirectory = string.gsub(userDirectoryPath, "/user" , "/system")
    local timefile = string.format("%s/%s",systemDirectory,"time.csv")
    local starttime, stoptime = gettimes(timefile)
    starttime = os.date("%Y-%m-%d %H:%M:%S", math.ceil(starttime))
    stoptime = os.date("%Y-%m-%d %H:%M:%S", math.ceil(stoptime))

    local curlCommand = generateUploadCmd(url, sn, testStationName, stationID, starttime, stoptime, result, resultTable)
    Log.LogFlowDebug("Curl Command: ", curlCommand)
    for _ = 1, 3 do
        local response = runShellCmd.run(curlCommand, 5000).output
        Log.LogFlowDebug("Response from server: ", response)
        if response:match("SFC_OK") then
            return true
        end
    end
    return false
end

function StationComm.uploadFCTInfo(params)
    local attributeKeyTable = Device.getPlugin("AttributeKeyTable")
    local SN = DataReporting.getPrimaryIdentity()
    if not SN then
        error("getPrimaryIdentity mlbsn error!")
    end
    local overallResult = tonumber(params.overallResult)
    local url = params.url
    local variableTable = Device.getPlugin("VariableTable")
    local testMode = variableTable.getVar("testMode")
    Log.LogFlowDebug("TestMode:  ".. testMode)

    -- if testMode == "Audit" then
    --     return true
    -- end

    local uploadAttributeKeyTable = constant["UploadMesInfo"]
    local uploadAttributeKeyTabeLength = #uploadAttributeKeyTable

    Log.LogFlowDebug("SN:  ".. SN)
    Log.LogFlowDebug("overallResult:",overallResult)

    local testResult = "FAIL"
    if overallResult == 2 then
        testResult = "PASS"
    end

    local tableKeyCount = 0
    local tableKey = {}
    for _, value in ipairs(uploadAttributeKeyTable) do
        local attributeValue = attributeKeyTable.getVar(value)
        if attributeValue then
            tableKeyCount = tableKeyCount + 1
            tableKey[value] = attributeValue
        else
            Log.LogFlowDebug("attributeKey not found in attributeTable:", value)
            return false
        end
    end

    Log.LogFlowDebug("target Upload Attribute KeyTabe Length:", tostring(uploadAttributeKeyTabeLength))
    Log.LogFlowDebug("upload Attribute Table Length:", tostring(tableKeyCount))
    local status, uploadResult = xpcall(uploadInfo, debug.traceback, SN, testResult, tableKey, url)
    Log.LogFlowDebug("uploadFCTInfo:", tostring(uploadResult))
    if not uploadResult or uploadAttributeKeyTabeLength ~= tableKeyCount then
        Log.LogError("uploadFCTInfo failed, ", uploadResult)
        return false
    end
    return true
end

-- !@brief schooner CSV API
-- !@brief internal getTestMode function
function StationComm.getTestMode()
    local innerFunc = function ()
        local variableTable = Device.getPlugin("VariableTable")
        local testMode = variableTable.getVar("testMode")
        return testMode
    end
    local status, result = xpcall(innerFunc, debug.traceback)
    if not status or not result then
        Log.LogError("getTestMode failed, ", result)
        return false
    else
        return result
    end
end

-- !@brief schooner CSV API
-- !@brief showDialog function
function StationComm.showDialog(additionalParameters)
    local msg = type(additionalParameters) == 'table' and additionalParameters.msg or additionalParameters

    local innerFunc = function(msg)
        local InteractiveView = Device.getPlugin("InteractiveView")
        local viewConfig = {["message"] = msg, ["button"] = {"OK"}}
        InteractiveView.showView(Device.systemIndex, viewConfig)
        return true
    end

    local status, result = xpcall(innerFunc, debug.traceback, msg)
    if status and result then
        return true
    else
        local failMsg = tostring(result)
        Log.LogError(failMsg)
        return false
    end
end

-- !@brief schooner CSV API
-- !@brief runMutexLock function, lock with identifier
-- !@param additionalParameters contain identifier if needed
-- !@return true or error out
function StationComm.runMutexLock(additionalParameters)
    local identifier = type(additionalParameters) == 'table' and additionalParameters.identifier or additionalParameters
    local status, result = xpcall(StationUtilsCore.runMutexLockCore, debug.traceback, identifier)
    if status and result then
        return true
    else
        local failMsg = tostring(result)
        Log.LogError(failMsg)
        error(failMsg)
    end
end

-- !@brief schooner CSV API
-- !@brief runMutexUnlock function, unlock with identifier
-- !@param additionalParameters contain identifier if needed
-- !@return true or error out
function StationComm.runMutexUnlock(additionalParameters)
    local identifier = type(additionalParameters) == 'table' and additionalParameters.identifier or additionalParameters
    local status, result = xpcall(StationUtilsCore.runMutexUnlockCore, debug.traceback, identifier)
    if status and result then
        return true
    else
        local failMsg = tostring(result)
        Log.LogError(failMsg)
        error(failMsg)
    end
end

local ActionHelper = require("SMTActionHelper")

local CSVInterfaceTable = {delegate = StationComm}

setmetatable(CSVInterfaceTable, ActionHelper.MetaTableFlowLogging)

return CSVInterfaceTable
