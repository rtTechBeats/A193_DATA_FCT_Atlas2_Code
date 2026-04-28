-- create fail record if
-- 1. device result is pass and
-- 2. limit count form limit table does not match limit count registered in atlas
local record = require("Schooner.SchoonerLimitsRecordsSanitizer").dataType
               .typePreRegisteredLimits
local resultString = require('Schooner.SchoonerHelpers').atlasResultString

function main(countRegistered, countExpected, deviceCurrentResult)
    -- TODO: use only subsub here.
    if deviceCurrentResult ~= DataReporting.result.pass then
        print(
        'Schooner: device result is ' .. resultString(deviceCurrentResult) ..
        ' not pass; skipping registerd limit count check')
        return
    end
    if countRegistered ~= countExpected then
        local msg = '%d limits registered; expecting %d'
        Atlas.logError(string.format(msg, countRegistered, countExpected))
        DataReporting.submitRecord(false, record.test, record.subtest,
                                   record.subsubtest, record.errMsg)
    end
end
