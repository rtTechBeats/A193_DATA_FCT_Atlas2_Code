local log = require "Common/logging"
local comFunc = require("Common/Utilities")
local pluginsLoader = require("INVT/Modules/PluginsLoader")
local runShellCmd = pluginsLoader.getPlugin("RunShellCommand")

local csvlogger = {}

local logPath = "/vault/Teseco_Logs/"
function csvlogger.createHeader(filepath, headers, upperlimits, lowerlimits, units)
    --[[
    Serial Number,
    Config,
    Station ID,
    Fixture ID,
    Site ID,
    PASS/FAIL,
    Error Message,
    Fail Item,
    Test Start Time,
    Test Stop Time,
    Total Test Time,
    --]]
    local strHeaders = "Product,Serial Number,Config,Station ID,Fixture ID,Site ID," ..
                        "PASS/FAIL,Error Message,Fail Item,Test Start Time," .. "Test Stop Time,Total Test Time," ..
                        headers .. "\n"
    upperlimits = "Upper Limited----------->,,,,,,,,,,,," .. upperlimits .. "\n"
    lowerlimits = "Lower Limited----------->,,,,,,,,,,,," .. lowerlimits .. "\n"
    units = "Measurement unit------>,,,,,,,,,,,," .. units .. "\n"
    local f = io.open(filepath, "a+")
    f:write(strHeaders)
    f:write(upperlimits)
    f:write(lowerlimits)
    f:write(units)
    f:close()
end

function csvlogger.createLogsForGroup(default_units, default_groups, islaunch, openTime)
    print("GroupStoped")
    if not default_groups then
        default_groups = "1"
    end
    log.LogInfo("----active_units--", default_units)
    local allSlotSN = {}
    for slotindex, _ in pairs(default_units) do
        local workingDirectory = Group.getDeviceUserDirectory("G=" .. default_groups .. ":S=" .. slotindex)
        print(workingDirectory)
        local systemDirectory = string.gsub(workingDirectory, "/user", "/system")
        local recordFile = systemDirectory .. "/records.csv"
        local timeFile = systemDirectory .. "/time.csv"
        local limitsFile = Atlas.assetsPath .. "/Coverage/LimitsTable.csv"
        local sn = csvlogger.createLog(slotindex, recordFile, limitsFile, timeFile, islaunch, openTime)
        allSlotSN[slotindex] = sn
    end
    log.LogInfo(allSlotSN)
    return allSlotSN
end

local function toint(floatnumber)
    local intpart = string.match(tostring(floatnumber), "(%d+)")
    return tonumber(intpart)
end

function csvlogger.gettimes(timefile)
    local lcsv = require('lcsv.lcsv')
    local csvh = lcsv.open(timefile, "r")
    local timerecords, _ = lcsv.readAll(csvh, true)
    csvh:close()
    local starttime = os.time()
    local stoptime = 0
    for _, record in ipairs(timerecords) do
        if record.StartTime and record.StopTime and tonumber(record.StartTime) and tonumber(record.StopTime) then
            starttime = (starttime < tonumber(record.StartTime)) and starttime or tonumber(record.StartTime)
            stoptime = (stoptime > tonumber(record.StopTime)) and stoptime or tonumber(record.StopTime)
        end
    end
    log.LogInfo(starttime, stoptime)
    return starttime, stoptime
end

function csvlogger.createLog(slot, recordfile, limitsFile, timefile, islaunch, openTime)
    local stationInfo = Atlas.loadPlugin("StationInfo")
    local fileName = tostring(stationInfo.product()) .. "_" .. stationInfo.station_type() .. "_"
                   .. tostring(stationInfo.build_stage()) .. "_" .. tostring(openTime or os.date("%Y-%m-%d_%H_%M_%S")) .. ".csv"

    -- local fileNameTemp = tostring(stationInfo.product()) .. "_" .. stationInfo.station_type() .. "_" ..
    --                          tostring(stationInfo.build_stage()) .. "_" .. os.date("%Y-%m-%d") .. ".csv"
    -- local fileName = fileNameTemp:gsub("^%s*(.-)%s*$", "%1")

    log.LogInfo("Teseco fileName :", fileName)
    local filePath = logPath .. fileName

    local headers = ""
    local upperlimits = ""
    local lowerlimits = ""
    local units = ""

    local lcsv = require('lcsv.lcsv')
    local limitsTable = {}
    
    local f = io.open(limitsFile, "r")
    if f then
        f:close()
        local csvh = lcsv.open(limitsFile, "r")
        local limitRecords, _ = lcsv.readAll(csvh, true)
        csvh:close()
        for _, limit in ipairs(limitRecords) do
            if limit.Technology and limit.Coverage and limit.SubSubTest then
                local key = limit.Technology .. "_" .. limit.Coverage .. "_" .. limit.SubSubTest
                limitsTable[key] = {
                    units = limit.Units or "",
                    upperLimit = limit.UpperLimit or "",
                    lowerLimit = limit.LowerLimit or ""
                }
            end
        end
    else
        log.LogInfo("Warning: Limits file not found: ", limitsFile)
    end


    local values = table.concat({
        "[Product]", --  Single  SN
        "[serialNumber]", --    Serial Number,
        "[sBuild]", --    Config,
        stationInfo.station_id(), --    Station ID,
        "[fixtureID]", --    Fixture ID,
        string.match(slot, "slot(%d+)"), --    Site ID,
        "[PASSFAIL]", --    PASS/FAIL,
        "", --    Error Message,
        "[FAILITEMS]", --    Fail Item,
        "[STARTTIME]", --    Test Start Time,
        "[STOPTIME]", --    Test Stop Time,
        "[TOTALTIME]"
    }, ",") .. ","

    local status, result = pcall(function()
        local lcsv = require('lcsv.lcsv')
        local recordCSVFile = recordfile
        local csvh = lcsv.open(recordCSVFile, "r")
        local records, _ = lcsv.readAll(csvh, true)
        csvh:close()
        local starttime, stoptime = csvlogger.gettimes(timefile)
        local failedList = {}
        local totalResult = "PASS"
        local serialNumber = ""
        local fixtureID = ""
        local panelSN = ""
        local sBuild = ""
        for _, record in ipairs(records) do
            if record.subTestName and record.subTestName ~= "" and record.testName ~= "Process" and record.testName ~= "Group" then
                local headerName = record.testName .. "_" .. record.subTestName .. "_" .. record.subSubTestName
                headers = headers .. headerName .. ","

                local key = record.testName .. "_" .. record.subTestName .. "_" .. record.subSubTestName
                local limit = limitsTable[key] or {}

                local uLimit = (record.upperLimit ~= "" and record.upperLimit) or (limit.upperLimit or "")
                local lLimit = (record.lowerLimit ~= "" and record.lowerLimit) or (limit.lowerLimit or "")
                local unit   = (record.measurementUnits ~= "" and record.measurementUnits) or (limit.units or "")
                local value  = (record.measurementValue ~= "" and record.measurementValue) or ""

                upperlimits = upperlimits .. uLimit .. ","
                lowerlimits = lowerlimits .. lLimit .. ","
                units = units .. unit .. ","
                values = values .. value .. ","

                if record.status ~= "PASS" then
                    totalResult = "FAIL"
                    failedList[#failedList + 1] = tostring(record.subTestName) .. "_" .. tostring(record.subSubTestName)
                end
            end
            if record.attributeName == "PrimaryIdentity" then
                serialNumber = record.attributeValue
            end
            if record.attributeName == "fixtureID" then
                fixtureID = record.attributeValue
            end
            if record.attributeName == "PanelSN" then
                panelSN = record.attributeValue
            end
            if record.attributeName == "S_BUILD" then
                sBuild = record.attributeValue
            end
        end
        values = string.gsub(values, "%[Product%]", "A193")
        values = string.gsub(values, "%[serialNumber%]", serialNumber)
        values = string.gsub(values, "%[panelSN%]", panelSN)
        values = string.gsub(values, "%[sBuild%]", sBuild)
        values = string.gsub(values, "%[fixtureID%]", fixtureID)
        values = string.gsub(values, "%[PASSFAIL%]", totalResult)
        values = string.gsub(values, "%[FAILITEMS%]", table.concat(failedList, ";"))
        values = string.gsub(values, "%[STARTTIME%]", os.date("%Y-%m-%d %H:%M:%S", toint(starttime)))
        values = string.gsub(values, "%[STOPTIME%]", os.date("%Y-%m-%d %H:%M:%S", toint(stoptime)))
        values = string.gsub(values, "%[TOTALTIME%]", string.format("%.3f", stoptime - starttime))

        -- if not comFunc.fileExists(filePath) then
        --     os.execute("mkdir -pv " .. logPath)
        --     csvlogger.createHeader(filePath, headers, upperlimits, lowerlimits, units)
        -- end
        if not comFunc.fileExists(filePath) then
            os.execute("mkdir -pv " .. logPath)
            csvlogger.createHeader(filePath, headers, upperlimits, lowerlimits, units)
        end
        local f = io.open(filePath, "a+")
        f:write(values .. "\n")
        f:close()
        return {serialNumber, totalResult}
    end)
    if not status then
        log.LogInfo("error = " .. result)
    end
    return result
end

local function uploadInfo(url, sn, test_station_name, station_id, start_time, stop_time, result, result_table)
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
    print("queryString: ", queryString)
    return string.format("curl %s -d \"%s\"", url, queryString)
end

function csvlogger.uploadFCTInfo(sn, result, resultTable, url)
    -- local url = "http://10.32.36.70/api/workflowcenter/anonymous/v1/bobcat/postv2"
    local stationInfo = Atlas.loadPlugin("stationInfo")
    local testStationName = stationInfo.product() .. " " .. stationInfo.station_type()
    local stationID = stationInfo.station_id()
    local userDirectoryPath =  Device.userDirectory
    local systemDirectory = string.gsub(userDirectoryPath, "/user" , "/system")
    local timefile = string.format("%s/%s",systemDirectory,"time.csv")
    local starttime, stoptime = csvlogger.gettimes(timefile)
    starttime = os.date("%Y-%m-%d %H:%M:%S", toint(starttime))
    stoptime = os.date("%Y-%m-%d %H:%M:%S", toint(stoptime))

    local curlCommand = uploadInfo(url, sn, testStationName, stationID, starttime, stoptime, result, resultTable)
    log.LogInfo("Curl Command: ", curlCommand)
    for _ = 1, 3 do
        local response = runShellCmd.run(curlCommand, 5000).output
        log.LogInfo("Response from server: ", response)
        if response:match("SFC_OK") then
            return true
        end
    end
    return false
end

function csvlogger.downloadFCTInfo(sn, station, url)
    log.LogInfo("debug----------:", sn, station, url)

    local command = string.format("curl \"%s\" -d \"c=QUERY_RECORD&p=P105GetSMTData&sn=%s\" -X POST", url, sn) --rel url
    if station == "IQC" then
        command = string.format("curl \"%s\" -d \"c=Query_Record&p=P105GetSMTData&sn=%s\" -X POST", url, sn) --iqc url
    end

    for _ = 1, 3 do
        local fctInfo = {}
        log.LogInfo("downloadFCTInfo: ", command)
        local response = runShellCmd.run(command, 5000).output
        log.LogInfo("Response from server: ", response)
        if response:match("SFC_OK") then
            local fisrtKey,firstValue = response:match("RESULT=([^:|]+):([^|]+)|")
            if fisrtKey and firstValue then
                fctInfo[fisrtKey] = firstValue
                log.LogInfo("Response from server: ", fisrtKey, firstValue)
            end

            for key, value in response:gmatch("|([^:|]+):([^|]+)") do
                fctInfo[key] = value
                log.LogInfo("Response from server: ", key, value)
            end

            return fctInfo
        end
    end
    return false
end

return csvlogger
