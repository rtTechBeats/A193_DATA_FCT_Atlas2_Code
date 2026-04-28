-------------------------------------------------------------------
----***************************************************************
---- Shared library for creating records
----***************************************************************
-------------------------------------------------------------------
local log = require ("Common/logging")
local comFunc = require ("Common/Utilities")

local Record = {}

-- create binary record; do not return anything.
-- DataReporting will raise Error when record cannot be submitted successfully.
function Record.createBinaryRecord(result, testname, subtestname, subsubtestname, failureMsg)
    log.LogInfo('creating binary record with result=' .. tostring(result) .. ', test=' .. tostring(testname) ..
                    ', subtest=' .. tostring(subtestname) .. ',subsubtest=' .. tostring(subsubtestname))
    local record = DataReporting.createBinaryRecord(result, testname, subtestname, subsubtestname)
    if failureMsg ~= '' and failureMsg ~= nil then
        log.LogInfo('creating FAIL binary record: ' ..
                        table.concat(comFunc.map(tostring, {testname, subtestname, subsubtestname, failureMsg}), '|'))
        record.addFailureReason(comFunc.trimFailureMsg(failureMsg))
    end
    DataReporting.submit(record)
end

-- create parametric record for a given number result and limit.
-- @param numResult: numeric data to create record for
-- @param testname, subtestname, subsubtestname: names for the record.
-- @param limit: limit table, with 5 keys: relaxedLowerLimit, lowerLimit,
--               upperLimit, relaxedUpperLimit and units
--               could be nil or empty table.
-- @param msg: additional failure reason to append for failure record; not used for pass record.
-- @return: bool, fail when record has limit and limit check fail.
--          true otherwise: no limit, pass or relaxed pass.
function Record.createParametricRecord(numResult, testname, subtestname, subsubtestname, limit, msg)
    local record = DataReporting.createParametricRecord(numResult, testname, subtestname, subsubtestname)
    local recordResult = false
    if limit ~= nil then
        -- apply limit when limit is provided; a table is expected; each limit key could be nil.
        -- applyLimit does not return limit check result but only return nil.
        -- record.applyLimit(limit.relaxedLowerLimit, limit.lowerLimit, limit.upperLimit,
        --                   limit.relaxedUpperLimit, limit.units)
        -- record.getResult() have limit check pass/fail
        -- 0: fail 1: relaxed pass 2: pass
        -- these values are accessible as Group.OverallResult.pass/fail/relaxedPass
        -- requesting Atlas to expose them in rdar://73307376
        recordResult = record.getResult()
        if recordResult == 0 then
            local failureMsg = 'Out of limit'

            if msg and msg ~= '' then
                failureMsg = failureMsg .. '; additional msg: ' .. tostring(msg)
            end

            log.LogError(failureMsg)
            record.addFailureReason(comFunc.trimFailureMsg(failureMsg))
            log.LogInfo('createParametricRecord: creating fail p-record')
        elseif recordResult == 1 or recordResult == 2 then
            -- no action actually
            log.LogInfo('createParametricRecord: creating pass p-record')
        end
    end
    DataReporting.submit(record)

    return recordResult ~= 0
end


-- create parametric record for a given number result and limit.
-- @param numResult: numeric data to create record for
-- @param testname, subtestname, subsubtestname: names for the record.
-- @param limit: limit table, with 5 keys: relaxedLowerLimit, lowerLimit,
--               upperLimit, relaxedUpperLimit and units
--               could be nil or empty table.
-- @param msg: additional failure reason to append for failure record; not used for pass record.
-- @return: bool, fail when record has limit and limit check fail.
--          true otherwise: no limit, pass or relaxed pass.
function Record.createCustomizedParametricRecord(numResult, testname, subtestname, subsubtestname, limit, msg)
    local record = DataReporting.createParametricRecord(numResult, testname, subtestname, subsubtestname)
    local recordResult = false
    if limit ~= nil then
        -- apply limit when limit is provided; a table is expected; each limit key could be nil.
        -- applyLimit does not return limit check result but only return nil.
        record.applyLimit(limit.relaxedLowerLimit, limit.lowerLimit, limit.upperLimit,
                          limit.relaxedUpperLimit, limit.units)
        -- record.getResult() have limit check pass/fail
        -- 0: fail 1: relaxed pass 2: pass
        -- these values are accessible as Group.OverallResult.pass/fail/relaxedPass
        -- requesting Atlas to expose them in rdar://73307376
        recordResult = record.getResult()
        if recordResult == 0 then
            local failureMsg = 'Out of limit'

            if msg and msg ~= '' then
                failureMsg = failureMsg .. '; additional msg: ' .. tostring(msg)
            end

            log.LogError(failureMsg)
            record.addFailureReason(comFunc.trimFailureMsg(failureMsg))
            log.LogInfo('createParametricRecord: creating fail p-record')
        elseif recordResult == 1 or recordResult == 2 then
            -- no action actually
            log.LogInfo('createParametricRecord: creating pass p-record')
        end
    end
    DataReporting.submit(record)

    return recordResult ~= 0
end


--  check limit and create record
--  limit: limit dict for current test item
--  if limit is nil, create record without applying limit:
--      binary PASS record for non-numeric result,
--      p-record for numeric result
--  for other unit, treat it as parametric record.
function Record.createRecord(result, testname, subtestname, subsubtestname, limit, msg)
    local failureMsg
    local errorSubSubTesName
    -- when limit is not found, treat as open limit
    log.LogDebug('judge result: ', result, limit)

    if limit == nil then
        log.LogDebug('Does not have limit.')
        -- create p-record for number; otherwise create pass binary record
        if tonumber(result) ~= nil then
            return Record.createParametricRecord(tonumber(result), testname, subtestname, subsubtestname, nil, nil)
        else
            if type(result) == "boolean" then
                Record.createBinaryRecord(result, testname, subtestname, subsubtestname, msg)
            else
                Record.createBinaryRecord(true, testname, subtestname, subsubtestname, nil)
                result = true
            end
            return result
        end
    else
        log.LogDebug('has limit defined.')
        -- has limit defined;
        log.LogDebug('checking numeric limits......: result: ' .. tostring(result) .. ', lowerLimit: ' ..
                         tostring(limit.lowerLimit) .. ', upperLimit: ' .. tostring(limit.upperLimit))
        -- support strings parsed from uart output, like '32'; convert into number 32.
        local numResult = tonumber(result)
        if numResult == nil then
            -- failed to convert to number; result is not a number or numeric string.
            failureMsg = 'Failed to convert ' .. tostring(result) ..
                             ' into number while it has numeric limit; check if test function return types match limit type.'
            errorSubSubTesName = 'ERROR_FROM_FUNCTION ' .. subsubtestname
            Record.createBinaryRecord(false, testname, subtestname, errorSubSubTesName, failureMsg)
            return false

        else
            if type(numResult) == "number" and (numResult == math.huge or numResult == -math.huge) then
                failureMsg = "result value is inf"
                errorSubSubTesName = 'INF_VALUE ' .. subsubtestname
                Record.createBinaryRecord(false, testname, subtestname, errorSubSubTesName, failureMsg)
                return false
            else
                return Record.createParametricRecord(numResult, testname, subtestname, subsubtestname, limit, msg)
            end
        end
    end
end



--  check limit and create record
--  limit: limit dict for current test item
--  if limit is nil, create record without applying limit:
--      binary PASS record for non-numeric result,
--      p-record for numeric result
--  for other unit, treat it as parametric record.
function Record.createCustomizedRecord(result, testname, subtestname, subsubtestname, limit, msg)
    local failureMsg
    local errorSubSubTesName
    -- when limit is not found, treat as open limit
    log.LogDebug('judge result: ', result, limit)

    if limit == nil then
        log.LogDebug('Does not have limit.')
        -- create p-record for number; otherwise create pass binary record
        if tonumber(result) ~= nil then
            return Record.createCustomizedParametricRecord(tonumber(result), testname, subtestname, subsubtestname, nil, nil)
        else
            if type(result) == "boolean" then
                Record.createBinaryRecord(result, testname, subtestname, subsubtestname, msg)
            else
                Record.createBinaryRecord(true, testname, subtestname, subsubtestname, nil)
                result = true
            end
            return result
        end
    else
        log.LogDebug('has limit defined.')
        -- has limit defined;
        log.LogDebug('checking numeric limits......: result: ' .. tostring(result) .. ', lowerLimit: ' ..
                         tostring(limit.lowerLimit) .. ', upperLimit: ' .. tostring(limit.upperLimit))
        -- support strings parsed from uart output, like '32'; convert into number 32.
        local numResult = tonumber(result)
        if numResult == nil then
            -- failed to convert to number; result is not a number or numeric string.
            failureMsg = 'Failed to convert ' .. tostring(result) ..
                             ' into number while it has numeric limit; check if test function return types match limit type.'
            errorSubSubTesName = 'ERROR_FROM_FUNCTION ' .. subsubtestname
            Record.createBinaryRecord(false, testname, subtestname, errorSubSubTesName, failureMsg)
            return false

        else
            if type(numResult) == "number" and (numResult == math.huge or numResult == -math.huge) then
                failureMsg = "result value is inf"
                errorSubSubTesName = 'INF_VALUE ' .. subsubtestname
                Record.createBinaryRecord(false, testname, subtestname, errorSubSubTesName, failureMsg)
                return false
            else
                return Record.createCustomizedParametricRecord(numResult, testname, subtestname, subsubtestname, limit, msg)
            end
        end
    end
end

return Record
