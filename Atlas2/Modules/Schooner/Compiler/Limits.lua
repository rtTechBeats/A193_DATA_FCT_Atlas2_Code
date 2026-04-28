local error_ = require('Schooner.Compiler.Errors')
local pl = require('pl.import_into')()
local utils = require('Schooner.Compiler.Utils')
local helper = require('Schooner.SchoonerHelpers')
local C = require('Schooner.Compiler.CompilerHelpers')
local tree = require('Schooner.Tree')
local common = require('Schooner.SchoonerCommon')
local conditionEvaluator = Atlas.loadPlugin('ConditionEvaluator')

local M = {}

-------------------------------------------------------------------------------
--- Parse Required
-------------------------------------------------------------------------------

-- Parse 'Required' column
-- Only check if column entry is non-empty. Actual condition handling in SchoonerCore.

local parseRequired = function(row)
    local requiredStr, required = row.Required, false

    -- 'Required' column is non-optional, so error out if empty.
    if not utils.isNonEmptyString(requiredStr) then
        error_:limitErrBadRequired('EMPTY STRING')
    else
        local isBoolean, value = C.isBooleanString(requiredStr)
        if isBoolean then
            required = value
        else
            -- condition expression
            required = requiredStr
            local tokens = conditionEvaluator.tokenize(requiredStr)
            C.checkForRestrictedConditionNames(tokens)
        end
    end

    row.required, row.Required = required, nil
end

-------------------------------------------------------------------------------
--- Parse test identifiers
-------------------------------------------------------------------------------

-- Columns: Technology, Coverage, TestParameters, SubSubTest
-- Check field formatting for limit spec, TestParameters and SubSubTest are optional
local parseTestIdentifiers = function(row)
    C.checkFieldFormat(row.Technology, common.TECHNOLOGY, 'badSpecFieldFormat')
    C.checkFieldFormat(row.Coverage, common.COVERAGE, 'badSpecFieldFormat')
end

-------------------------------------------------------------------------------
--- Parse priority
-------------------------------------------------------------------------------

local parsePriority = function(row)
    local priority = row.Priority
    if priority == '' then
        priority = nil
    end

    row.priority, row.Priority = priority, nil
end

-------------------------------------------------------------------------------
--- Parse units
-------------------------------------------------------------------------------

local parseUnits = function(row)
    local units = row.Units
    if units == '' then
        units = nil
    end

    row.units, row.Units = units, nil
end

-------------------------------------------------------------------------------
--- Parse conditions
-------------------------------------------------------------------------------

local parseConditions = function(row)
    local condition = row.Conditions
    if condition == '' then
        condition = nil
    else
        local tokens = condition ~= nil and
                       conditionEvaluator.tokenize(condition) or {}
        C.checkForRestrictedConditionNames(tokens)
    end

    row.conditions, row.Conditions = condition, nil
end

-------------------------------------------------------------------------------
--- Parse limits
-------------------------------------------------------------------------------

function M.convertLimit(limit, name)
    local convertedLimit = nil

    if limit == nil then
        -- just return nil for empty string.
        return nil
    elseif utils.isValidString(limit) then
        if pl.stringx.strip(limit) == '' then
            return nil
        end

        convertedLimit = tonumber(limit)
        -- If tonumber fails (e.g. limit = "fifteen")
        if convertedLimit == nil then
            error_:limitErrBadLimitValue(limit, name)
        end
    else
        -- only for schooner developer
        error(
        '[INTERNAL] convertLimit() only accepts string or nil, while got a ' ..
        type(limit))
    end

    return convertedLimit
end

-- TODO: do we want to move these local functions into module
-- so they can have unit test?
-- TODO: remove logic of skipping when unit is 'string'
local function convertLimits(row)
    row.relaxedUpperLimit = M.convertLimit(row.RelaxedUpperLimit,
                                           'RelaxedUpperLimit')
    row.upperLimit = M.convertLimit(row.UpperLimit, 'UpperLimit')
    row.lowerLimit = M.convertLimit(row.LowerLimit, 'LowerLimit')
    row.relaxedLowerLimit = M.convertLimit(row.RelaxedLowerLimit,
                                           'RelaxedLowerLimit')
    row.RelaxedUpperLimit, row.UpperLimit, row.LowerLimit, row.RelaxedLowerLimit =
    nil, nil, nil, nil
end

local function checkValidLimit(lower, upper, lowerName, upperName)
    if lower ~= nil and upper ~= nil and lower > upper then
        error_:limitErrBadLimitRange(lower, lowerName, upper, upperName)
    end
end

local function checkValidLimits(row)
    checkValidLimit(row.relaxedLowerLimit, row.relaxedUpperLimit,
                    common.RELAXED_LOWER_LIMIT, common.RELAXED_UPPER_LIMIT)
    checkValidLimit(row.lowerLimit, row.upperLimit, common.LOWER_LIMIT,
                    common.UPPER_LIMIT)
    checkValidLimit(row.relaxedLowerLimit, row.lowerLimit,
                    common.RELAXED_LOWER_LIMIT, common.LOWER_LIMIT)
    checkValidLimit(row.upperLimit, row.relaxedUpperLimit, common.UPPER_LIMIT,
                    common.RELAXED_UPPER_LIMIT)
end

-- Return error if unit is not supported or wrong limits
local parseLimits = function(row)
    convertLimits(row)
    checkValidLimits(row)
end

-------------------------------------------------------------------------------
--- Parse AllowedList
-------------------------------------------------------------------------------

local validateAllowedList = function(row)
    local allowedList = row.AllowedList

    local limitFields = {
        row.relaxedUpperLimit,
        row.upperLimit,
        row.lowerLimit,
        row.relaxedLowerLimit
    }
    if helper.isNonEmptyString(allowedList) and
    helper.isNonEmptyTable(limitFields) then
        error_:ambiguousLimitType()
    end

    row.allowedList = C.stringToArray(row.AllowedList)
    row.AllowedList = nil
end

-- return array of tests that has given technology and coverage
local function testsWithGivenTechnologyAndCoverage(tests,
                                                   technology,
                                                   coverage)
    local ret = {}
    for _, test in ipairs(tests) do
        if test.Technology == technology and test.Coverage == coverage then
            ret[#ret + 1] = test
        end
    end
    return ret
end

local function noop() end

local function hasStrictLimitWithSubSub(matchingLimits, limitSubSub)
    for subsub, _ in pairs(matchingLimits) do
        if subsub == limitSubSub then
            -- limit: (A, B, *, D) and (A, B, C, D), Main table has (A, B, C);
            -- (A, B, C, D) is already in limit table, shouldn't expand from * again.
            -- this test+subsub has a specific limit and shouldn't use wildcard limit.
            return true
        else
            -- limit: (A, B, *, E) and (A, B, C, D), Main table has (A, B, C);
            -- needs to expand into (A, B, C, E).
            noop()
        end
    end

    return false
end

local function expandNewLimit(expandedLimits,
                              limit,
                              newTestParameters)
    local newLimit = helper.clone(limit)
    if newTestParameters then
        newLimit.TestParameters = newTestParameters
    end
    expandedLimits[#expandedLimits + 1] = newLimit
end

local function generatePossibleLimitVersion(conditionExpression)
    local limitVersion = ""
    local tokens = conditionExpression ~= nil and
                   conditionEvaluator.tokenize(conditionExpression) or {}

    for _, token in ipairs(tokens) do
        if token.type == common.TOKEN_TYPE_IDENTIFIER then
            limitVersion = limitVersion .. token.value
        elseif token.type == common.TOKEN_TYPE_OPERATOR or token.type ==
        common.TOKEN_TYPE_GROUP then
            assert(common.operatorMap[token.value])
            limitVersion = limitVersion .. common.operatorMap[token.value]
        elseif token.type == common.TOKEN_TYPE_QUOTED_STRING then
            token.value = token.value:match("'([%g ]*)'") or
                          token.value:match('"([%g ]*)"')
            limitVersion = limitVersion .. token.value
        else
            limitVersion = limitVersion .. tostring(token.value)
        end
    end

    return limitVersion
end

local function definedCustomFilter(generator)
    local msg = '[Internal]: nil/empty generator passed to definedCustomFilter'
    assert(helper.isNonEmptyTable(generator), msg)
    return generator.module ~= "Schooner/DefaultConditionGeneratorAndValidator"
end

-- if condition table has overridden product/stationType
-- then they need to be added into limit version string
local function processLimitInfo(limitInfo, conditions)
    local hasProduct = false
    local hasStationType = false
    -- do not search Product and StationType in Test conditions
    for _, conditionsForType in ipairs({ conditions.group, conditions.init }) do
        for _, row in ipairs(conditionsForType) do
            if row.name == 'Product' and definedCustomFilter(row.generator) then
                hasProduct = true
            elseif row.name == 'StationType' and
            definedCustomFilter(row.generator) then
                hasStationType = true
            end
        end
    end

    -- Two conditions for adding product/stationType into limit version
    -- 1. duplicate limits have different product
    -- 2. product/stationType has been overridden in condition.csv
    limitInfo.withProduct = limitInfo.withProduct and hasProduct
    limitInfo.withStationType = limitInfo.withStationType and hasStationType
end

-- Finds all common condition variables used by duplicated limits. Also includes whether
-- different modes occur in duplicated limits.
-- @arg duplicateEntries - table of duplicate limit entries from findDuplicateEntries
-- @return limitInfo - table for compiler output. limitInfo.withMode
-- (or withProduct or withStationType)=true indicates that
-- a duplicated limit contained different modes/products/stations
-- (e.g. mode/product/stationType can produce duplicate limits);
-- limitInfo.conditions gives a list of all condition vars used by *duplicate* limits.
-- Condition vars used by limits which are not duplicated are *not* included in limitInfo.conditions
local function getLimitInfo(duplicateEntries, conditions)
    local limitInfo = {
        withMode = false,
        withProduct = false,
        withStationType = false,
        conditions = {}
    }
    local allModes = pl.Set({})
    local allProducts = pl.Set({})
    local allStationTypes = pl.Set({})
    local allConditionVars = pl.Set({})
    local possibleConditionTable = {}
    local limitNames = {}
    for _, limit in pairs(duplicateEntries) do
        local possibleCondition = {}
        local limitName = nil
        -- TODO: Is it possible to refactor structure of limit.data so we
        -- don't need to loop over it?
        -- Ex:
        -- limit = {
        --      mode = {'Production', 'Audit'},
        --      product = {'A1', 'B2'}
        -- }
        -- Then we can just use allModes = allModes + pl.Set(limit.mode)
        -- instead of looping
        for _, value in ipairs(limit.data) do
            local singleLimitEntry = {}
            allModes = allModes + pl.Set(value[common.MODE])
            allProducts = allProducts + pl.Set(value[common.PRODUCT])
            allStationTypes = allStationTypes +
                              pl.Set(value[common.STATION_TYPE])
            allConditionVars = allConditionVars + value.identifiers

            local conditionString = generatePossibleLimitVersion(
                                    value.conditions)
            value.entry.conditionString =
            conditionString ~= '' and conditionString or nil
            table.insert(singleLimitEntry, conditionString)

            table.sort(value[common.MODE] or {})
            local modeString = pl.stringx.join('_', value[common.MODE] or {})
            value.entry.modeString = modeString ~= '' and modeString or nil
            table.insert(singleLimitEntry, modeString)

            table.sort(value[common.PRODUCT] or {})
            local productString = pl.stringx.join('_',
                                                  value[common.PRODUCT] or {})
            value.entry.productString = productString ~= '' and productString or
                                        nil
            table.insert(singleLimitEntry, productString)

            table.sort(value[common.STATION_TYPE] or {})
            local stationTypeString = pl.stringx.join('_',
                                                      value[common.STATION_TYPE] or
                                                      {})
            value.entry.stationTypeString =
            stationTypeString ~= '' and stationTypeString or nil
            table.insert(singleLimitEntry, stationTypeString)
            table.insert(possibleCondition, singleLimitEntry)
        end

        if #limit.data >= 1 then
            limitName = C.createLimitNameWithCoverage(limit.data[1].entry)
        end

        if limitName == nil then
            error("Limit name is nil for limit: " .. helper.dump(limit.data))
        end

        if not helper.isEmptyTable(possibleCondition) then
            table.insert(limitNames, limitName)
            if possibleConditionTable[limitName] == nil then
                possibleConditionTable[limitName] = possibleCondition
            else
                error("Duplicate limit name: " .. limitName .. " for " ..
                      helper.dump(limit.data))
            end
        end
    end
    limitInfo.withMode = #allModes > 1
    limitInfo.withProduct = #allProducts > 1
    limitInfo.withStationType = #allStationTypes > 1

    processLimitInfo(limitInfo, conditions)
    table.sort(limitNames)

    local uniqueStrings = {}
    local setsOfDuplicateLimitsData = {}
    local limitPositionInfos = {}
    local weight = 1
    for _, limitName in ipairs(limitNames) do
        local comboStrings = {}
        for _, row in ipairs(possibleConditionTable[limitName]) do
            local limitVersionForEachRow = {}

            if helper.isNonEmptyString(row[1]) then
                table.insert(limitVersionForEachRow, row[1])
            end

            if limitInfo.withMode and helper.isNonEmptyString(row[2]) then
                table.insert(limitVersionForEachRow, row[2])
            end
            if limitInfo.withProduct and helper.isNonEmptyString(row[3]) then
                table.insert(limitVersionForEachRow, row[3])
            end
            if limitInfo.withStationType and helper.isNonEmptyString(row[4]) then
                table.insert(limitVersionForEachRow, row[4])
            end

            if helper.isNonEmptyTable(limitVersionForEachRow) then
                table.insert(comboStrings,
                             pl.stringx.join('_', limitVersionForEachRow))
            end

        end
        table.sort(comboStrings)

        if helper.isNonEmptyTable(comboStrings) then
            -- There is chance that non of the condition is true
            table.insert(comboStrings, "")
            local lineStr = helper.dump(comboStrings)
            if not uniqueStrings[lineStr] then
                uniqueStrings[lineStr] = true
                local comboStringsMap = helper.invertArray(comboStrings)
                -- The empty condition ("") which implies that we have not chosen this limit.
                -- When calculating the limit index, this limit will not be included when condition is "",
                -- it means that 0 * (weight) always equals 0.
                -- so in comboStringsMap, we didn't need to include ""
                comboStringsMap[""] = nil
                limitPositionInfos[limitName] = {
                    comboStringsMap = comboStringsMap,
                    weight = weight
                }
                weight = weight * #comboStrings
                table.insert(setsOfDuplicateLimitsData, comboStrings)
            end
        end
    end
    local numberPossibleLimitVersions = 1
    if not helper.isEmptyTable(setsOfDuplicateLimitsData) then
        -- check if too many dup items that index will exceed 48
        for _, item in ipairs(setsOfDuplicateLimitsData) do
            numberPossibleLimitVersions = numberPossibleLimitVersions * #item
            assert(numberPossibleLimitVersions < math.maxinteger and
                   numberPossibleLimitVersions > 0,
                   'Too many possible combinations that cannot fit in lua integer: ' ..
                   tostring(numberPossibleLimitVersions) ..
                   '; number of duplicated limits: ' ..
                   #setsOfDuplicateLimitsData)
        end
    end

    -- Maintain used condition vars in ascending alphabetical order
    allConditionVars = pl.Set.values(allConditionVars)
    table.sort(allConditionVars)
    limitInfo.conditions = allConditionVars
    limitInfo.limitPositionInfos = limitPositionInfos
    limitInfo.numberPossibleLimitVersions = numberPossibleLimitVersions
    return limitInfo
end

-- @arg         expectedFilterValues            values from IN validator
-- @arg         allLimitFilters                 values from Limit.csv
-- @returns     limitFiltersForReplacement      values to replace empty cells
function M.prepareReplacementLimitFilters(expectedFilterValues,
                                          allLimitFilters)
    return {
        -- Always non-nil; condition defines at least 1 allowed mode
        [common.MODE] = helper.tableKeys(expectedFilterValues[common.MODE]),
        -- Could be nil (not used + not defined)
        [common.PRODUCT] = allLimitFilters[common.PRODUCT],
        [common.STATION_TYPE] = allLimitFilters[common.STATION_TYPE]
    }
end

-- TODO: Move to LimitCSV class rdar://111764096
function M.duplicateLimitHandler(row, node)
    if node.conditionData == nil then
        -- noConditions == true means we've seen a duplicate entry with nil conditions
        local identifiers = C.extractIdentifiers(row.conditions)
        node.conditionData = {
            seenDuplicate = false,
            noConditions = row.conditions == nil,
            firstSeenIdx = row.originalRowIdx + common.NUM_HEADER_LINES,
            identifiersCounter = C.updateIdentifiersCounter({}, identifiers),
            numEntries = 1,
            isSetLimit = C.isSetLimit(row),
            rowConditions = {}
        }
        if row.conditions ~= nil then
            node.conditionData.rowConditions[row.conditions] = true
        end
        node.entries = {}
    else
        node.conditionData.seenDuplicate = true
    end
    if node.conditionData.seenDuplicate then
        C.processDuplicateLimitEntries(row, node.conditionData)
    end
    table.insert(node.entries, row)
end

function M.processLimits(limitsCSVPath,
                         allTests,
                         conditions,
                         expectedFilterValues)

    error_:pushLocation(limitsCSVPath)

    local limitsFromFile, DORC, allLimitFilters = M.parseLimitCSV(limitsCSVPath)
    C.validateFilters(expectedFilterValues, allLimitFilters)

    local limitFiltersForReplacement = M.prepareReplacementLimitFilters(
                                       expectedFilterValues, allLimitFilters)

    -- buildTree treats nil fields as empty string
    -- need to replace EMPTY with ALL to identify duplicates
    -- i.e. EMPTY should overlap with {'J1'}, but '' doesn't
    local limitCopy = helper.clone(limitsFromFile)
    C.populateEmptyFilters(limitCopy, limitFiltersForReplacement)

    local keys = {
        common.SHARED_COLUMNS.Technology,
        common.SHARED_COLUMNS.Coverage,
        common.SHARED_COLUMNS.TestParameters,
        'SubSubTest',
        common.PRODUCT,
        common.STATION_TYPE,
        common.MODE
    }
    local t = tree.new(limitCopy, keys, M.duplicateLimitHandler)
    t:buildTree()

    -- limitsCSV: [limit1, limit2, limit3]; each limit is a table with keys:
    -- technology: string
    -- coverage: string
    -- testParameters: string, could be "*"
    -- subSubTest: string
    -- mode: string, could be '' which means limit is applied to all test modes
    -- priority: string
    -- lowerLimit/upperLimit/relaxedLowerLimit/relaxedUpperLimit: number or nil
    -- units: string
    -- orignalIdx: number; is this needed?
    local ret = {}
    -- Error out in Core if AllowedList is non-empty with incompatible Atlas version
    local usesAllowedList = false
    for _, limit in ipairs(limitsFromFile) do
        if usesAllowedList == false and limit.allowedList then
            usesAllowedList = true
        end

        -- if wildcard limit, do not include it in limit table returned.
        local isWildcardLimit = false
        -- ignore space around *
        local trimmedTestParameters = helper.trim(limit.TestParameters)
        if trimmedTestParameters == '*' then
            -- if testParameters is *, expand it:
            --     if technology and coverage match that in main table, and
            --     the testParameters in main table is not in limit table, add it to limit table.
            --     finally remove the item with *.
            -- for example, limit has {A, B, *, (0-1)} and {A, B, X, (2-3)},
            -- main table has {A, B, C}, {A, B, X}, {A, B, D},
            -- limit table will be {A, B, C, (0-1)}, {A, B, X, (2-3)}, {A, B, D, (0-1)}
            isWildcardLimit = true
            local technology = limit.Technology
            local coverage = limit.Coverage
            local matchingTests = testsWithGivenTechnologyAndCoverage(allTests,
                                                                      technology,
                                                                      coverage)
            if #matchingTests == 0 then
                -- no test matching this limit item; keep it there so orphan limit could be captured
                -- or error out?
                local msg = 'No test in Main table matches limit item: '
                msg = msg .. 'Technology=%s, Coverage=%s, TestParameters=*'
                msg = msg:format(technology, coverage)
                helper.debugPrint(msg)
                -- adding the limit as-is, even if testParameters is *
                local newLimit = helper.clone(limit)
                ret[#ret + 1] = newLimit
            else
                local matched = false
                for _, test in ipairs(matchingTests) do
                    local limitsMatchingTestParameters = t:find({
                        test.Technology,
                        test.Coverage,
                        test.TestParameters
                    })
                    if limitsMatchingTestParameters == nil then
                        -- limit (A, B, *, D), main test (A, B, C) and there is no (A, B, C, anything)
                        -- in limit table
                        expandNewLimit(ret, limit, test.TestParameters)
                        -- this limit item is used at least once.
                        matched = true
                    else
                        if hasStrictLimitWithSubSub(
                        limitsMatchingTestParameters, limit.SubSubTest) == false then

                            expandNewLimit(ret, limit, test.TestParameters)
                            matched = true
                        end
                    end
                end

                if matched == false then
                    expandNewLimit(ret, limit, nil)
                end
            end
        end

        if isWildcardLimit == false then
            C.addRows(ret, C.expandLoopInLimitRow(limit))
        end
    end

    -- build test, subtest from tech/cov/testpara
    for _, limit in ipairs(ret) do
        limit.testname, limit.subtestname =
        C.makeTestNames(limit.Technology, limit.Coverage, limit.TestParameters)
        limit.subsubtestname = limit.SubSubTest
    end

    local duplicateLimitEntries = C.findDuplicateEntries(ret, common.LIMITS)

    local limitInfo = getLimitInfo(duplicateLimitEntries, conditions)
    -- Don't add key to limitInfo if value is false
    limitInfo.usesAllowedList = usesAllowedList or nil

    -- Need to put all modes back so filterLimitForMode can find the correct limits.
    C.populateEmptyFilters(ret, {
        [common.MODE] = limitFiltersForReplacement[common.MODE]
    })
    error_:popLocation()

    return ret, DORC, limitInfo
end

-- return true if the limit row means disable orphaned record checking:
--   - except for Notes, only Technology is not empty
--   - Technology is `DisableOrphanedRecordChecking`
function M.rowIsDisableOrphanedRecordCheck(limit)
    if limit == nil then
        return
    end

    local isDORC

    if limit.Technology == common.DisableOrphanedRecordChecking then
        isDORC = true
    else
        return false
    end

    local nonEmptyColumns = {}

    -- Technology cannot be empty.
    -- We don't care what's in Notes.
    -- originalRowIdx is not from CSV.
    local keysToIgnore = { 'Technology', 'Notes', 'originalRowIdx' }
    for key, value in pairs(limit) do
        if pl.tablex.find(keysToIgnore, key) == nil and value ~= '' then
            table.insert(nonEmptyColumns, key)
        end
    end

    if isDORC == true then
        if #nonEmptyColumns ~= 0 then
            error_:DORCWithNonEmptyColumn(helper.dump(nonEmptyColumns))
        end
    end

    return isDORC
end

--[[
    'Required',
    'Technology',
    'Coverage',
    'TestParameters',
    'SubSubTest',
    'Conditions',
    'Product',
    'StationType',
    'Mode',
    'Units',
    'Priority',
    'AllowedList',
    'RelaxedUpperLimit',
    'UpperLimit',
    'LowerLimit',
    'RelaxedLowerLimit',
    'Notes'
]]
-- Function to parse limit csv file
-- Input: Path to limit csv file
-- Outputs: Parsed table with limits
function M.parseLimitCSV(limitCSVPath)

    local header, limits = C.loadCSV(limitCSVPath, common.LIMITS)
    C.validateHeader(limitCSVPath, header, common.LIMITS)

    local DORC = nil
    local allFilters = {}
    for idx, row in ipairs(limits) do
        error_:pushLocation('Row: ' .. idx)

        for colName, item in pairs(row) do
            row[colName] = pl.stringx.strip(item)
        end
        row.originalRowIdx = idx

        if idx == 1 then
            DORC = M.rowIsDisableOrphanedRecordCheck(row)
        end
        if idx ~= 1 or not DORC then
            M.checkIfDORCInWrongPlace(row, idx)
            parseRequired(row)
            parseTestIdentifiers(row)
            C.parseFilter(row, common.SHARED_COLUMNS.Mode)
            C.parseFilter(row, common.SHARED_COLUMNS.Product)
            C.parseFilter(row, common.SHARED_COLUMNS.StationType)
            C.addSeenFilters(allFilters, {
                [common.MODE] = row[common.MODE],
                [common.PRODUCT] = row[common.PRODUCT],
                [common.STATION_TYPE] = row[common.STATION_TYPE]
            })
            parsePriority(row)
            parseConditions(row)
            parseUnits(row)
            parseLimits(row)
            validateAllowedList(row)
        end
        error_:popLocation()
    end

    -- if the 1st line is DisableOrphanedRecordChecking, remove it
    -- because it is not a real limit item.
    if DORC then
        table.remove(limits, 1)
    end

    return limits, DORC, allFilters
end

function M.checkIfDORCInWrongPlace(row, idx)
    -- make sure normal limit item doesn't
    -- have DisableOrphanedRecordChecking as value
    local limitColumns = C.expectedTableHeaders[common.LIMITS]
    local DORCString = common.DisableOrphanedRecordChecking
    for _, field in ipairs(limitColumns) do
        if field ~= 'Notes' and row[field] == DORCString then
            error_:DORCInWrongPlace(field, idx)
        end
    end
end

return M
