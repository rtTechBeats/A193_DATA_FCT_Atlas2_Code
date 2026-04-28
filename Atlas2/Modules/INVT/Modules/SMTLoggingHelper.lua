local Log = require("Common/logging")
local record = require("Common/record")

-- ! @brief logging helper for Hawkeye parsing
-- ！@brief 3 categories helper interfaces:
-- !     - LogFlowStart & LogFlowPass/Fail for marking test item start/finish
-- !     - LogFixtureControlStart & LogFixtureControlFinish for marking fixture actions
-- !     - LogDutCommStart & LogDutCommFinish for marking DutComm content
local helper = {}

helper.FLOW_START = "[TEST START][<%s> <%s> <%s>]"
helper.FLOW_PASS = "[TEST PASSED][<%s> <%s> <%s>]"
helper.FLOW_FAIL = "[TEST FAILED][<%s> <%s> <%s>]"
helper.FIXTURE_START = "[%%fixture cmd%%] method: %s    args: %s    timeout: %s"
helper.FIXTURE_STOP = "[%%fixture response%%] %s"
helper.DUT_COMMAND_START = "[%%dut cmd%%]"
helper.DUT_COMMAND_STOP = "[%%dut response%%]"
helper.RECORD =
    "[%%record%%]   [<%s> <%s> <%s>]   lower: %s   higher: %s  value: %s   unit: %s    result: %s   failMsg: %s"
helper.FLOW_DEBUG = "[%%flow debug%%]"

helper.__testResult = true

-- ! @brief Lua Script API, logging technology item start
-- ! @brief logging format [Test Start][<TestName> <SubTestName> <SubSubTestName>]
-- ! @param params matchbox csv parameter table, will look for params.Technology, params.TestName, params.AdditionalParameters.subsubtestname
function helper.LogFlowStart(params)
    helper.__testResult = true
    Log.LogInfo(string.format(helper.FLOW_START, params.Technology .. params.testNameSuffix, params.TestName,
                              params.AdditionalParameters.subsubtestname))
end

-- ! @brief Lua Script API, logging technology item finish with pass result
-- ! @brief logging format [Test Pass][<TestName> <SubTestName> <SubSubTestName>]
-- ! @param params matchbox csv parameter table, will look for params.Technology, params.TestName, params.AdditionalParameters.subsubtestname
function helper.LogFlowPass(params)
    Log.LogInfo(string.format(helper.FLOW_PASS, params.Technology .. params.testNameSuffix, params.TestName,
                              params.AdditionalParameters.subsubtestname))
end

-- ! @brief Lua Script API, logging technology item finish with fail result
-- ! @brief logging format [Test Fail][<TestName> <SubTestName> <SubSubTestName>]
-- ! @param params matchbox csv parameter table, will look for params.Technology, params.TestName, params.AdditionalParameters.subsubtestname
function helper.LogFlowFail(params)
    Log.LogInfo(string.format(helper.FLOW_FAIL, params.Technology .. params.testNameSuffix, params.TestName,
                              params.AdditionalParameters.subsubtestname))
end

function helper.LogFlowFinish(params)
    if helper.__testResult then
        helper.LogFlowPass(params)
    else
        helper.LogFlowFail(params)
    end
end

-- ! @brief Lua Script API, logging fixture action start
-- ! @brief logging format [%%fixture cmd%%]
function helper.LogFixtureControlStart(...)
    Log.LogInfo(string.format(helper.FIXTURE_START, table.unpack({...})))
end

-- ! @brief Lua Script API, logging fixture action done
-- ! @brief logging format [%%fixture response%%]
function helper.LogFixtureControlFinish(...)
    Log.LogInfo(string.format(helper.FIXTURE_STOP, table.unpack({...})))
end

-- ! @brief Lua Script API, logging dut command start
-- ! @brief logging format [%%dut cmd%%]
function helper.LogDutCommStart(...)
    Log.LogInfo(helper.DUT_COMMAND_START, ...)
end

-- ! @brief Lua Script API, logging dut command finish
-- ! @brief logging format [%%dut response%%]
function helper.LogDutCommFinish(...)
    Log.LogInfo(helper.DUT_COMMAND_STOP, ...)
end

-- ! @brief Lua Script API, logging arbitrary content to be captured in flow log
-- ! @brief logging format[%%flow debug%%]
-- ! @param params matchbox csv parameter table, will look for params.Technology, params.TestName, params.AdditionalParameters.subsubtestname
function helper.LogFlowDebug(...)
    Log.LogInfo(helper.FLOW_DEBUG, ...)
end

-- ! @brief Lua Script API, a wrap function to helper logging record creation. It leverages Matchbox record creation API
-- ! @param result test result value, can be numeric data/binary data/string type data
-- ! @param params matchbox parameter table, params.Technology, params.testNameSuffix & params.TestName are required keys, params.AdditionalParameters.subsubtestname & params.limit are optional keys
-- ! @param msg failure message for the record, optional key
-- ! @param subsubtestname a string to be used to override the subsubtestname for the record, optional key
-- ! @param limit an optional key dictionary to override limit, contains keys: lowerLimit, upperLimit, relaxedLowerLimit, relaxedUpperLimit, units
-- ! @param value test result value, optional key, applicable when the insight result is binary type, but user wants to have string type value recorded in pivot log
function helper.createRecord(result, params, msg, subsubtestname, limit, value)
    local lowerLimit, upperLimit, relaxedLowerLimit, relaxedUpperLimit, unit
    if limit ~= nil then
        lowerLimit = limit.lowerLimit
        upperLimit = limit.upperLimit
        relaxedLowerLimit = limit.relaxedLowerLimit
        relaxedUpperLimit = limit.relaxedUpperLimit
        unit = limit.units
    elseif params.AdditionalParameters.subsubtestname and params.limit and
        params.limit[params.AdditionalParameters.subsubtestname] then
        lowerLimit = params.limit[params.AdditionalParameters.subsubtestname].lowerLimit
        upperLimit = params.limit[params.AdditionalParameters.subsubtestname].upperLimit
        relaxedLowerLimit = params.limit[params.AdditionalParameters.subsubtestname].relaxedLowerLimit
        relaxedUpperLimit = params.limit[params.AdditionalParameters.subsubtestname].relaxedUpperLimit
        unit = params.limit[params.AdditionalParameters.subsubtestname].units
    else
        lowerLimit = ""
        upperLimit = ""
        relaxedLowerLimit = ""
        relaxedUpperLimit = ""
        unit = ""
    end
    local subsubtestnameToHornor = subsubtestname and subsubtestname or params.AdditionalParameters.subsubtestname
    local testResult
    if type(result) == "boolean" then
        record.createBinaryRecord(result, params.Technology .. params.testNameSuffix, params.TestName,
                                  subsubtestnameToHornor, msg)
        testResult = result -- no return from Matchbox createBinary, set true for result always
    else
        local recordLimit
        if limit ~= nil then
            recordLimit = limit
        else
            recordLimit = params.limit and
                              params.limit[subsubtestname and subsubtestname or
                                  params.AdditionalParameters.subsubtestname] or nil
        end
        testResult = record.createRecord(result, params.Technology .. params.testNameSuffix, params.TestName,
                                         subsubtestnameToHornor, recordLimit, msg)
    end
    Log.LogInfo(string.format(helper.RECORD, params.Technology .. params.testNameSuffix, params.TestName,
                              subsubtestnameToHornor, tostring(lowerLimit), tostring(upperLimit),
                              value and tostring(value) or "", unit or "", testResult and "PASS" or "FAIL", msg or ""))
    if not testResult then
        helper.__testResult = false
    end
    return testResult
end

-- ! @brief Lua Script API, a wrap function to helper logging binary record creation. It leverages Matchbox createBinary API
-- ! @param result test result value, expect boolean type
-- ! @param testname string, testname for insight record
-- ! @param subtestname string, subtestname for insight record
-- ! @param subsubtestname string, subsubtestname for insight record
-- ! @param msg failure message for the record, optional key
-- ! @param value test result value, optional key, applicable when the insight result is binary type, but user wants to have string type value recorded in pivot log
function helper.createBinaryRecord(result, testname, subtestname, subsubtestname, msg, value)
    if type(result) ~= 'boolean' then
        error("result for createBinaryRecord should be boolean type, got ", type(result))
    end
    record.createBinaryRecord(result, testname, subtestname, subsubtestname, msg)
    local testResult = result
    if not testResult then
        helper.__testResult = false
    end
    local lowerLimit = ""
    local upperLimit = ""
    local relaxedLowerLimit = ""
    local relaxedUpperLimit = ""
    local unit = ""
    Log.LogInfo(string.format(helper.RECORD, testname, subtestname, subsubtestname, tostring(lowerLimit),
                              tostring(upperLimit), value and tostring(value) or "", unit or "",
                              testResult and 'PASS' or 'FAIL', msg or ""))
    return testResult
end

-- ! @brief Lua Script API, a wrap function to helper logging parametric record creation. It leverages Matchbox createParametric API
-- ! @param value test result number, expect number type
-- ! @param testname string, testname for insight record
-- ! @param subtestname string, subtestname for insight record
-- ! @param subsubtestname string, subsubtestname for insight record
-- ! @param limit a dictionary to declair limits for insight record, should contains keys: lowerLimit, upperLimit, relaxedLowerLimit, relaxedUpperLimit, units
-- ! @param msg failure message for the record, optional key
function helper.createParametricRecord(result, testname, subtestname, subsubtestname, limit, msg)
    local testResult = record.createParametricRecord(result, testname, subtestname, subsubtestname, limit, msg)
    local lowerLimit, upperLimit, relaxedLowerLimit, relaxedUpperLimit, unit
    if not testResult then
        helper.__testResult = false
    end
    if limit ~= nil then
        lowerLimit = limit.lowerLimit
        upperLimit = limit.upperLimit
        relaxedLowerLimit = limit.relaxedLowerLimit
        relaxedUpperLimit = limit.relaxedUpperLimit
        unit = limit.units
    else
        lowerLimit = ""
        upperLimit = ""
        relaxedLowerLimit = ""
        relaxedUpperLimit = ""
        unit = ""
    end
    Log.LogInfo(string.format(helper.RECORD, testname, subtestname, subsubtestname, tostring(lowerLimit),
                              tostring(upperLimit), tostring(result), unit or "", testResult and "PASS" or "FAIL",
                              msg or ""))
    return testResult
end

-- ! @brief Lua Script API, a wrap function to helper logging action. It only do logging and no real insight record wil be created
-- ! @param value test result value, can be numeric data/binary data/string type data
-- ! @param params matchbox parameter table, params.Technology, params.testNameSuffix & params.TestName are required keys, params.AdditionalParameters.subsubtestname & params.limit are optional keys
-- ! @param msg failure message for the record, optional key
-- ! @param subsubtestname a string to be used to override the subsubtestname for the record, optional key
-- ! @param limit an optional key dictionary to override limit, contains keys: lowerLimit, upperLimit, relaxedLowerLimit, relaxedUpperLimit, units
function helper.logTestAction(result, params, msg, subsubtestname, limit, value)
    local lowerLimit, upperLimit, relaxedLowerLimit, relaxedUpperLimit, unit
    if limit ~= nil then
        lowerLimit = limit.lowerLimit
        upperLimit = limit.upperLimit
        relaxedLowerLimit = limit.relaxedLowerLimit
        relaxedUpperLimit = limit.relaxedUpperLimit
        unit = limit.units
    elseif params.AdditionalParameters.subsubtestname and params.limit and
        params.limit[params.AdditionalParameters.subsubtestname] then
        lowerLimit = params.limit[params.AdditionalParameters.subsubtestname].lowerLimit
        upperLimit = params.limit[params.AdditionalParameters.subsubtestname].upperLimit
        relaxedLowerLimit = params.limit[params.AdditionalParameters.subsubtestname].relaxedLowerLimit
        relaxedUpperLimit = params.limit[params.AdditionalParameters.subsubtestname].relaxedUpperLimit
        unit = params.limit[params.AdditionalParameters.subsubtestname].units
    else
        lowerLimit = ""
        upperLimit = ""
        relaxedLowerLimit = ""
        relaxedUpperLimit = ""
        unit = ""
    end
    local subsubtestnameToHornor = subsubtestname and subsubtestname or params.AdditionalParameters.subsubtestname
    local testResult
    if unit == 'string' then
        testResult = (result == upperLimit)
    else
        if type(result) ~= 'boolean' then
            error("Only support binary type for result, fill in data in parameter: value")
        end
        testResult = result
    end
    if not testResult then
        helper.__testResult = false
    end
    Log.LogInfo(string.format(helper.RECORD, params.Technology .. params.testNameSuffix, params.TestName,
                              subsubtestnameToHornor, tostring(lowerLimit), tostring(upperLimit),
                              value and tostring(value) or "", unit or "", testResult and 'PASS' or 'FAIL', msg or ""))
    return testResult
end

-- ! @brief Lua Script API, a wrap function to helper logging test action. It only do logging and no real insight record wil be created
-- ! @param value test result value, expect boolean type
-- ! @param testname string, testname for record
-- ! @param subtestname string, subtestname for record
-- ! @param subsubtestname string, subsubtestname for record
-- ! @param msg failure message for the record, optional key
function helper.logTestActionWithNames(result, testname, subtestname, subsubtestname, msg, value)
    testResult = result
    if not testResult then
        helper.__testResult = false
    end
    local lowerLimit = ""
    local upperLimit = ""
    local relaxedLowerLimit = ""
    local relaxedUpperLimit = ""
    local unit = ""
    Log.LogInfo(string.format(helper.RECORD, testname, subtestname, subsubtestname, tostring(lowerLimit),
                              tostring(upperLimit), value and tostring(value) or "", unit or "", testResult, msg or ""))
    return testResult
end

-- ! @brief Lua Script API, logging info message function mapped to sequencer function Log.LogInfo()
-- ! @param args acceptable by Log.LogInfo()
function helper.LogInfo(...)
    Log.LogInfo(...)
end

-- ! @brief Lua Script API, logging debug message function mapped to sequencer function Log.LogDebug()
-- ! @param args acceptable by Log.LogDebug()
function helper.LogDebug(...)
    Log.LogDebug(...)
end

-- ! @brief Lua Script API, logging error message function mapped to sequencer function Log.LogError()
-- ! @param args acceptable by Log.LogError()
function helper.LogError(...)
    Log.LogError(...)
end

return helper
