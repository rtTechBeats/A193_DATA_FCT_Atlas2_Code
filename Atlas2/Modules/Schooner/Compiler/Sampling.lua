local compilerHelper = require('Schooner.Compiler.CompilerHelpers')
local common = require('Schooner.SchoonerCommon')
local errors = require("Schooner.Compiler.Errors")

local Sampling = {}

-- name: alphanumeric_-
function Sampling.validateName(samplings)
    local names = {}
    for idx, sampling in ipairs(samplings) do
        errors:pushLocation('line ' .. idx + common.NUM_HEADER_LINES)
        local name = sampling.GroupName
        if names[name] ~= nil then
            errors:duplicatedSamplingGroupName(name)
        end
        names[name] = true
        compilerHelper.checkFieldFormat(name, common.SAMPLE_GROUP_SAMPLE_TABLE,
                                        'badSpecFieldFormat')

        errors:popLocation()
    end
end

function Sampling.validateProposedRate(samplings)
    for _, sampling in ipairs(samplings) do
        local rate = tonumber(sampling.ProposedRate)
        if rate == nil then
            errors:samplingRateIsNotNumber(sampling.ProposedRate)
        end
        if rate > 99 or rate < 1 then
            errors:samplingRateOutOfRange(rate)
        end
    end
end

-- parse Sampling CSV and return parsed Sampling table
-- to be used by runner
-- @param SampleCSV    (string)path of SampleCSV file
function Sampling.processSampling(SampleCSVPath)
    errors:pushLocation(SampleCSVPath)

    if SampleCSVPath == nil then
        -- No sampling CSV is provided; supported.
        return {}
    end
    local headerArray, samplingTable = compilerHelper.loadCSV(SampleCSVPath,
                                                              common.SAMPLING)
    compilerHelper.validateHeader(SampleCSVPath, headerArray, common.SAMPLING)
    Sampling.validateName(samplingTable)
    Sampling.validateProposedRate(samplingTable)

    errors:popLocation()

    -- change to key-value pairs
    local ret = {}
    for _, row in ipairs(samplingTable) do
        ret[row.GroupName] = tonumber(row.ProposedRate)
    end

    return ret
end

return Sampling
