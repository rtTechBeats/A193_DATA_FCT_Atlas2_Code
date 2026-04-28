local record = {}

local helper = require("INVT/Modules/SMTLoggingHelper")
local rtLib = require("INVT/Modules/RTCommonLib")


function record.createRecord(status, params, result, unit)
    local limit = nil
    local subsubtestname = params.AdditionalParameters.subsubtestname or nil
    if (not status) then
        local failMsg = subsubtestname .. " failed; " .. tostring(result)
        helper.createRecord(status, params, failMsg)
        Matchbox.reportFailure(subsubtestname .. " failed; " .. tostring(result))
    end
    if params.isLimitApplied and params.limit and params.limit[subsubtestname] and unit then
        limit = params.limit[subsubtestname]
        result = rtLib.convertUnit(result, unit, limit.units)
    end
    local bRet = helper.createRecord(result, params, nil, nil, nil, result)
    if not bRet then
        Matchbox.reportFailure(subsubtestname .. " failed; " .. tostring(result))
    end
end

function record.createTestAction(status, params, result)
    local subsubtestname = params.AdditionalParameters.subsubtestname or nil

    if (not status) then
        local failMsg = subsubtestname .. " failed; " .. tostring(result)
        helper.logTestAction(status, params, failMsg)
        Matchbox.reportFailure(subsubtestname .. " failed; " .. tostring(result))
    end
    local bRet = helper.logTestAction(result, params)
    if not bRet then
        Matchbox.reportFailure(subsubtestname .. " failed; " .. tostring(result))
    end
end

return record
