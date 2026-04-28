-- create fail record if
-- 1. device result is pass and
-- 2. orphaned record count (passed in) > 0.
local record = require("Schooner.SchoonerLimitsRecordsSanitizer").dataType
               .typeOrphanedRecords
local resultString = require('Schooner.SchoonerHelpers').atlasResultString

function main(orphanedRecordCount, deviceCurrentResult)
    if deviceCurrentResult ~= DataReporting.result.pass then
        print(
        'Schooner: device result is ' .. resultString(deviceCurrentResult) ..
        ' not pass; skipping orphaned record check')
        return
    end

    -- TODO: use only subsub here.
    if orphanedRecordCount > 0 then
        DataReporting.submitRecord(false, record.test, record.subtest,
                                   record.subsubtest, record.errMsg)
    end
end
