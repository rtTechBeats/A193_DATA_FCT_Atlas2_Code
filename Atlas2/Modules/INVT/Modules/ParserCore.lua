local ParserCore = {}

local comFunc = require("Common/Utilities")
local helper = require("Common/logging")
local socAttributeTable

ParserCore.AttributeRecord = 0
ParserCore.ParametricRecord = 1
ParserCore.BinaryRecord = 2

-- !@breif Lua script API
-- !@breif Parse response with MD Parser
-- !@param command command string, mdparser finds parsing template based on this string
-- !@param response response string to parse
-- !@return parsing result in a table
function ParserCore.mdParse(command, response)
    helper.LogInfo("Running MD parser")
    local mdParser = Device.getPlugin("MDParser")
    local result, pData = xpcall(mdParser.parse, debug.traceback, command, response)
    helper.LogDebug(result, pData)

    if not result then
        helper.LogInfo("test failure: " .. tostring(pData))
    end
    return pData
end

function ParserCore.createRecordWithSoCExecData(testName, subTestName, subSubTestName, pResult, value, dataType, limit,
                                                failureMsg)
    local pDataTab = {}

    pDataTab["testname"] = testName:sub(1, 48)
    pDataTab["subtestname"] = subTestName:sub(1, 64)
    pDataTab["subsubtestname"] = subSubTestName:sub(1, 128)
    pDataTab["result"] = pResult
    pDataTab["value"] = value
    pDataTab["type"] = dataType
    pDataTab["limit"] = limit
    pDataTab["failuremessage"] = failureMsg
    return pDataTab
end

-- Create records based on data table
-- @param dataTable: data table with full definition of test names, limits, type...
-- @return true/false: result of creating records and failures records

function ParserCore.createRecordWithData(dataTable)
    if type(dataTable) ~= "table" then
        error("table expected for createRecordWithData: " .. tostring(dataTable))
    end

    local result = true

    for _, pData in ipairs(dataTable) do
        local testName = pData["testname"]
        local subTestName = pData["subtestname"]
        local subSubTestName = pData["subsubtestname"]
        local pResult = pData["result"]
        local value = pData["value"]
        local type = pData["type"]
        local failureMsg = pData["failuremessage"]
        local limit = pData["limit"]

        if pResult == true or string.lower(tostring(pResult)) == "pass" then
            pResult = true
        else
            pResult = false
        end

        if testName == nil or testName == "" then
            error("invalid data table, no testname defined: " .. tostring(testName))
        end

        if subSubTestName == 'TIME' then
            type = ParserCore.ParametricRecord
        end

        if type == ParserCore.AttributeRecord then
            DataReporting.submit(DataReporting.createAttribute(subSubTestName, tostring(value)))
        elseif type == ParserCore.BinaryRecord then
            pResult = DataReporting.submitRecord(pResult, testName, subTestName, subSubTestName, failureMsg) or pResult
        elseif type == ParserCore.ParametricRecord then
            pResult = (DataReporting.submitRecord(tonumber(value), testName, subTestName, subSubTestName, limit,
                                                  failureMsg)) ~= 0 and pResult
        else
            error("invalid record type, should be 0, 1 or 2" .. tostring(type))
        end
        result = pResult and result
    end

    return result
end

-- !@brief Gets the currentEnv previously stored in "EnterEnv.enterEnv" from the "variableTable" plugin
local function getCurrentEnv()
    local variableTable = Device.getPlugin("VariableTable")
    return variableTable.getVar("currentEnv") or error("Failed to get 'currentEnv' variable.")
end

local function getAttributeTable()
    local attributePath = Atlas.assetsPath .. "/supportFiles/config/SOC_Attributes.plist"
    local plistLoader = Device and Device.getPlugin("PListSerializationPlugin") or
                            Atlas.loadPlugin("PListSerializationPlugin")

    if not comFunc.fileExists(attributePath) then
        error(attributePath .. " not exist!")
    end
    if not socAttributeTable then
        socAttributeTable = plistLoader.decodeFile(attributePath)
    end
    local env = string.upper(getCurrentEnv())
    return socAttributeTable["Attributes"][env]
end

-- fetch limits for specific test names
-- @param subTestName: Test name
-- @param subSubTestName: subsubtestname in tech csv
-- @param parseKey: parseKey for command
-- @return table: limit table for specified test names
function ParserCore.fetchLimit(limitsTable, testName, subTestName, subSubTestName, pKey)
    if limitsTable == nil then
        return nil
    end
    for _, v in pairs(limitsTable) do
        if v.Technology == testName and string.find(subTestName, v.Coverage) then
            if v.TestParameters == subSubTestName or string.find(tostring(pKey), v.TestParameters) then
                return v
            end
        end
    end

    return nil
end

-- Create records based on SoCParser paraTab, data table, attribute list and limit file
-- @param paraTab: tech csv parameters
-- @return true/false: result of creating records and failures records

function ParserCore.createRecordWithSoCExecTable(params, dataTable, limitsTable, isTTRSuffixApplied)
    local result = true
    if dataTable == nil or type(dataTable) ~= 'table' then
        helper.LogError("dataTable is nil or dataTable type is not table")
        return false
    end
    local testName = params.RTOS_TECHNOLOGY
    local subTestName
    local subSubTestName
    local pResult
    local value
    local dataType
    local limit = {}
    local pDataTab = {}
    local pDataTabSub
    local failureMessage
    local attributeTable = getAttributeTable()
    helper.LogInfo("attributeTable >> ", comFunc.dump(attributeTable))
    for k, v in pairs(dataTable) do
        if type(v) ~= 'table' then
            subTestName = params.RTOS_SUB_SUB_TEST_NAME -- exec socstn.cmd
            subTestName = string.gsub(subTestName, " ", "_")
            subTestName = string.gsub(subTestName, "%.", "_") -- exec_socstn_cmd
            subSubTestName = k
            value = v
            dataType = ParserCore.ParametricRecord
            pResult = true
            pDataTabSub = ParserCore.createRecordWithSoCExecData(testName, subTestName, subSubTestName, pResult, value,
                                                                 dataType)
            table.insert(pDataTab, pDataTabSub)
        else
            for _, pValue in pairs(v) do
                for k2, v2 in pairs(pValue) do
                    subTestName = pValue["subsubtestname"] -- 1_PERTOS_INFO_FUSE_ECID
                    local delimiter = "PERTOS_"
                    local pos, length = string.find(subTestName, delimiter)
                    subTestName = delimiter .. string.sub(subTestName, 1, pos - 1) ..
                                      string.sub(subTestName, length + 1) -- PERTOS_1_INFO_FUSE_ECID
                    if k2 == 'parseKey' then
                        subSubTestName = "Result"
                        value = pValue["result"]
                        failureMessage = pValue["failureMessage"]
                        dataType = ParserCore.BinaryRecord
                        pResult = value > 0 and true or false
                        pDataTabSub = ParserCore.createRecordWithSoCExecData(testName, subTestName, subSubTestName,
                                                                             pResult, value, dataType, limit,
                                                                             failureMessage)
                        table.insert(pDataTab, pDataTabSub)
                        for k3, v3 in pairs(v2) do
                            subSubTestName = k3
                            value = v3
                            dataType = ParserCore.BinaryRecord
                            if comFunc.hasVal(attributeTable, k3) then
                                if isTTRSuffixApplied then
                                    subSubTestName = subSubTestName .. "_TTR"
                                end
                                dataType = ParserCore.AttributeRecord
                            else
                                if tonumber(value) ~= nil then
                                    dataType = ParserCore.ParametricRecord
                                end
                            end
                            limit = ParserCore.fetchLimit(limitsTable, testName, subTestName, subSubTestName, k3)
                            pDataTabSub = ParserCore.createRecordWithSoCExecData(testName, subTestName, subSubTestName,
                                                                                 pResult, value, dataType, limit)
                            table.insert(pDataTab, pDataTabSub)
                        end
                    elseif k2 == 'CMD_TIME' then
                        limit = {}
                        pResult = pValue["result"] > 0 and true or false
                        if pValue["result"] > 0 then
                            subSubTestName = "CMD_TIME"
                        else
                            subSubTestName = "CMD_TIME_TTF"
                        end
                        value = pValue["CMD_TIME"]
                        dataType = ParserCore.ParametricRecord
                        pDataTabSub = ParserCore.createRecordWithSoCExecData(testName, subTestName, subSubTestName,
                                                                             pResult, value, dataType, limit)
                        table.insert(pDataTab, pDataTabSub)
                    end
                end
            end
        end
    end
    helper.LogInfo(pDataTab)
    result = ParserCore.createRecordWithData(pDataTab) and result
    return result
end

-- Create records based on data table, attribute list and limit file
-- @param dataTable: dataTable contains the parsed key and value, such as {["reg_0x3082BC24C"] = 0,}
-- @return true/false: result of creating records and failures records
function ParserCore.createRecordWithDataTable(dataTable, subsubtest, limitsTable)
    if dataTable == nil or type(dataTable) ~= 'table' then
        helper.LogError("dataTable is nil or dataTable type is not table")
        return false
    end
    helper.LogInfo("dataTable >>", comFunc.dump(dataTable))

    local pDataTab = {}
    local result = true
    local attributeTable = getAttributeTable()
    helper.LogInfo("attributeTable >> ", comFunc.dump(attributeTable))

    for pKey, pValue in pairs(dataTable) do
        local testName = tostring(Device.test)
        local subTestName = tostring(subsubtest)
        local subSubTestName = tostring(pKey)
        local pResult = true
        local value = tostring(pValue)
        local recordType = ParserCore.BinaryRecord

        if tonumber(pValue) ~= nil then
            value = tonumber(pValue)
            recordType = ParserCore.ParametricRecord
        end

        if comFunc.hasVal(attributeTable, subSubTestName) then
            recordType = ParserCore.AttributeRecord
        end

        local limit = ParserCore.fetchLimit(limitsTable, testName, subTestName, subSubTestName, tostring(pKey))
        local pDataTabSub = ParserCore.createRecordWithSoCExecData(testName, subTestName, subSubTestName, pResult,
                                                                   value, recordType, limit, "")
        table.insert(pDataTab, pDataTabSub)
    end
    helper.LogInfo("pDataTab >>", comFunc.dump(pDataTab))
    result = ParserCore.createRecordWithData(pDataTab) and result
    return result
end

return ParserCore
