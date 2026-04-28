-- create fail record if
-- 1. device result is pass and
-- 2. any required limit is orphaned.
-- Test condition value is resolved (only) when used by an orphaned limit's Required column.
-- LRS: Limit Record Sanitizer
local LRS = require('Schooner.SchoonerLimitsRecordsSanitizer')
local record = LRS.dataType.typeOrphanedLimits
local helper = require('Schooner.SchoonerHelpers')
local resultString = helper.atlasResultString

local function createFailRecord()
    -- TODO: use only subsub here.
    DataReporting.submitRecord(false, record.test, record.subtest,
                               record.subsubtest, record.errMsg)
end

-- required could be true/false or a condition expression string like `A == 1`
-- this function resolve `required` into a boolean
-- 1) already boolean: use as-is
-- 2) string: get what condition is used, resolve it, then evaluate the condition expression.
local function resolveRequiredExpression(limit, conditions, cePlugin)
    local required = limit.required
    if type(required) == 'boolean' then
        return required
    else
        assert(type(required) == 'string')
        -- get what condition it is using
        local vars = {}
        -- limit.conditionInRequired should store the condition name used in the expression
        -- like {A} for A == 1
        for _, var in ipairs(limit.conditionInRequired) do
            local value = helper.getResolvableValue(conditions[var])
            -- store the resolved value back in conditions
            -- so when it is used next time we don't need to returnValue() again.
            conditions[var] = value
            -- getResolvableValue() could error out, but it should indicate action error
            -- which shouldn't appear here: action error should cancel this action.
            vars[var] = value
        end

        local ok, result = pcall(cePlugin.eval, required, vars)
        if ok then
            return result
        else
            local msg =
            'Limit table Required column has an invalid condition expression: ' ..
            required .. ', error message: ' .. result
            error(msg)
        end
    end
end

function main(orphanedLimits, limits, conditions, deviceCurrentResult)
    -- ORL: Orphaned Required Limits
    local ORL = {}
    local report = true

    if deviceCurrentResult ~= DataReporting.result.pass then
        print(
        'Schooner: device result is ' .. resultString(deviceCurrentResult) ..
        ' not pass; ignore orphaned require limit.')
        report = false
    end

    local tree = LRS.buildLimitTree(limits)

    -- ce: ConditionEvaluator
    local ce = Atlas.loadPlugin('ConditionEvaluator')
    for _, orphanedLimit in ipairs(orphanedLimits) do
        local limit = LRS.searchLimitInTree(orphanedLimit, tree)
        assert(limit)
        local required = resolveRequiredExpression(limit, conditions, ce)
        if required == true then
            table.insert(ORL, orphanedLimit)
        end
    end

    if next(ORL) and report then
        createFailRecord()
        -- sort it so similar names are printed together; hopefully make it easier to read
        -- print orphaned required limits in log
        local toPrint = {}
        for _, orl in ipairs(ORL) do
            local msg = orl.testname .. ' ' .. orl.subtestname .. ' ' ..
                        (orl.subsubtestname or '')
            table.insert(toPrint, msg)
        end
        table.sort(toPrint)
        for i, orl in ipairs(toPrint) do
            print(
            ('Orphaned Required Limit  %d/%d: %s'):format(i, #toPrint, orl))
        end
    end

    return ORL
end
