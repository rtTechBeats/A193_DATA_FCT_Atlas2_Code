local M = {}

local E = require('Schooner.Compiler.Errors')
local pl = require('pl.import_into')()
local tsort = require('resty.tsort')
local utils = require('Schooner.Compiler.Utils')
local helper = require('Schooner.SchoonerHelpers')
local lcsv = require('lcsv.lcsv')
local error_ = require('Schooner.Compiler.Errors')
local common = require('Schooner.SchoonerCommon')
local ce = Atlas.loadPlugin('ConditionEvaluator')

-- Shared consts
local MAIN = common.MAIN
local ACTIONS_DICTIONARY = 'dictionary'
local ACTIONS_LIST = 'list'

local SEQUENTIAL = common.actionsType.sequential
local GRAPH = common.actionsType.graph
local separators = common.separators

local expectedTableHeaders = {
    [common.MAIN] = {
        'Disable',
        'Technology',
        'Coverage',
        'TestParameters',
        'Dependency',
        'Conditions',
        'Product',
        'StationType',
        'Mode',
        'CoverageFile',
        'StopOnFail',
        'SamplingGroup',
        'TestCoverageCategory',
        'Notes'
    },
    [common.CONDITIONS] = { 'Name', 'When', 'Generator', 'Validator', 'Notes' },
    [common.LIMITS] = {
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
    },
    [common.SAMPLING] = { 'GroupName', 'ProposedRate' }
}

M.expectedTableHeaders = expectedTableHeaders

function M.addDep(dep, deps, keep) deps[M.encodeActionSpec(dep)] = keep end

-- validate if given string is an valid boolean column value:
-- Y, N or empty string ""
-- error if given string is none above.
-- return isBoolean, isY
function M.isBooleanString(value)
    local upperValue = value:upper()
    return value == "" or upperValue == 'Y' or upperValue == 'N',
           upperValue == 'Y'
end

-- support read out CSV files and parse the content to table
function M.loadCSV(CSVPath, CSVType)
    local didSucceed, csvFile = pcall(lcsv.open, CSVPath, "r")
    if not didSucceed then
        error_:CSVFileNotFound(CSVPath)
    end

    local content = csvFile:read('*a')
    M.checkForIsolatedReturns(content)
    local csvLines = lcsv.toLines(content)
    csvFile:close()

    -- trim the last empty line caused by ending eol (\r\n) which is common
    if csvLines[#csvLines] == '' then
        csvLines[#csvLines] = nil
    end

    -- parse header row for only checking later.
    local headerArray
    didSucceed, headerArray = pcall(lcsv.parseLine, csvLines[1])

    if not didSucceed then
        error_(headerArray or 'Unable to parse header row of "' .. CSVType ..
               '" CSV file at "' .. CSVPath .. '"')
    end

    didSucceed, csvTableOrError = pcall(lcsv.parseAll, csvLines, true)
    if not didSucceed then
        error_(csvTableOrError or 'Unable to parse "' .. CSVType ..
               '" CSV file at "' .. CSVPath .. '"')
    end

    -- remove `Notes` as soon as CSV file is loaded
    for _, row in ipairs(csvTableOrError) do
        M.removeNotes(row)
    end

    return headerArray, csvTableOrError
end

function M.validateHeader(file, tableHeader, tableType)
    local expectedTableHeader = expectedTableHeaders[tableType]
    if (#tableHeader ~= #expectedTableHeader) then
        error_:CSVHeaderWrongColumnNumber(file, #tableHeader,
                                          #expectedTableHeader)
    end
    for i, column in ipairs(expectedTableHeader) do
        if column ~= tableHeader[i] then
            error_:CSVColumnMismatch(file, i, column, tableHeader[i])
        end
    end
end

function M.checkAmbiguousWildcards(specWithMatches)
    if not utils.isNonEmptyTable(specWithMatches.matches) then
        return
    end

    local numWildcardsToSpec = {}
    for matchedSpec, numWildcards in pairs(specWithMatches.matches) do
        numWildcardsToSpec[numWildcards] =
        numWildcardsToSpec[numWildcards] or {}
        table.insert(numWildcardsToSpec[numWildcards], matchedSpec)
    end

    local allNumWildcards = pl.tablex.keys(numWildcardsToSpec)
    table.sort(allNumWildcards)

    local firstNumWildcard = allNumWildcards[1]
    if #numWildcardsToSpec[firstNumWildcard] > 1 then
        local encodedRowTestSpec = M.encodeTestSpec(specWithMatches.testSpec)

        E:ambiguousTestDefMatch(encodedRowTestSpec,
                                numWildcardsToSpec[firstNumWildcard])
    end
end

function M.checkDuplicateName(names, name)
    if names[name] ~= nil then
        E:duplicateActionName(name)
    else
        names[name] = true
    end
end

function M.checkMainTableRow(row)
    row.isEmpty = M.isRowEmpty(row)
    row.separator = M.separatorType(row)

    if not (row.isEmpty or row.separator) then
        if M.isBooleanString(row.Disable) == false then
            E:badBooleanColumn('Disable', row.Disable)
        end

        if not utils.isNonEmptyString(row.CoverageFile) then
            E:badCoverage('Coverage must be a nonempty relative path ' ..
                          'to the test definition file')
        end
    elseif row.isEmpty then
        E:emptyRow()
    end

    if M.isBooleanString(row.StopOnFail) == false then
        E:badBooleanColumn('StopOnFail', row.StopOnFail)
    end
end

local function findDuplicatesInArray(array)
    local seen = {}
    for _, value in ipairs(array) do
        if seen[value] then
            return value -- Duplicate found
        end
        seen[value] = true
    end
    return nil -- No duplicates
end

function M.parseFilter(row, filterName)
    local message = '[Internal]: unrecognized filter: %s in parseFilter'
    message = message:format(tostring(filterName))
    assert(common.ALL_FILTERS[filterName] ~= nil, message)

    local lowerCaseFilter = common.ALL_FILTERS[filterName]

    row[lowerCaseFilter] = M.stringToArray(row[filterName])
    -- Mode/Product/StationType doesn't allow duplicate values
    local duplicateValue = findDuplicatesInArray(row[lowerCaseFilter] or {})
    if duplicateValue ~= nil then
        error("Field " .. filterName .. " has duplicate values (" ..
              duplicateValue .. ")")
    end
    for _, filter in ipairs(row[lowerCaseFilter] or {}) do
        M.checkFieldFormat(filter, lowerCaseFilter, 'badSpecFieldFormat')
    end
    row[filterName] = nil

    -- return value indicates whether filter exists in row
    return row[lowerCaseFilter] ~= nil
end

-- Updates allFilters with values from a new row
-- @arg: allFilters - {['mode'] = {'Production'}}
-- @arg: newFilters - {['mode'] = {'Production', 'Rel'}}
-- result: {['mode'] = {'Production', 'Rel'}}
function M.addSeenFilters(allFilters, newFilters)
    for key, newFilter in pairs(newFilters) do
        allFilters[key] = pl.Set(allFilters[key]) + pl.Set(newFilter)
        -- Return back to Lua table
        allFilters[key] = pl.Set.values(allFilters[key])
    end
end

-- field: content being checked
-- fieldName: name of field (e.g. testParameters)
-- errKey: function to call on-error (e.g. name of function in Errors.lua)
-- errArgs: (optional) args to pass to errKey (passed as array to checkFieldFormat)
function M.checkFieldFormat(field, fieldName, errKey, errArgs)
    local format = common.FIELD_FORMAT[fieldName].format
    local isRequired = common.FIELD_FORMAT[fieldName].isRequired

    local stringState
    if isRequired then
        stringState = utils.isNonEmptyString(field)
    else
        stringState = utils.isValidString(field)
    end

    if not stringState or field:match(format) ~= field then
        if errArgs then
            E[errKey](E, table.unpack(errArgs))
        else
            E[errKey](E, field or 'EMPTY', format, fieldName)
        end
    end
end

-- Passing in error keys so I don't have to wrap error functions, since I can't pass E:func
function M.encodeSpec(spec,
                      expectedSpecSize,
                      invalidSpecErrorKey,
                      specWrongSizeErrorKey)
    if not utils.isNonEmptyArray(spec) then
        E[invalidSpecErrorKey](E)
    end

    local encodedSpec = pl.pretty.write(spec, '')
    if #spec ~= expectedSpecSize then
        E[specWrongSizeErrorKey](E, encodedSpec)
    end

    return encodedSpec
end

-- @arg conditionExpression - Condition expression in string form
-- @return identifiers - array of all condition variables in conditionExpression
-- Ex: 'A==1 OR (B==3 AND C=="dog")' ---> {A, B, C}
function M.extractIdentifiers(conditionExpression)
    local identifiers = {}
    local tokens = conditionExpression ~= nil and
                   ce.tokenize(conditionExpression) or {}

    for _, token in ipairs(tokens) do
        if token.type == 'identifier' then
            identifiers[#identifiers + 1] = token.value
        end
    end
    return pl.Set.values(pl.Set(identifiers))
end

function M.encodeActionSpec2(testSpec, actionName)
    if testSpec.actionName then
        assert(actionName == nil,
               'encodeActionSpec2: get both testSpec.actionName and actionName arg, confused which to use')
    end
    local t = {
        testSpec.technology,
        testSpec.coverage,
        testSpec.testParameters,
        testSpec.actionName or actionName
    }
    return M.encodeActionSpec(t)
end

function M.encodeActionSpec(actionSpec)
    local errorKey = 'actionSpecWrongSize'
    return M.encodeSpec(actionSpec, 4, 'invalidActionSpec', errorKey)
end

function M.encodeTestSpec(testSpec)
    local errorKey = 'testSpecWrongSize'
    return M.encodeSpec(testSpec, 3, 'invalidTestSpec', errorKey)
end

-- test as k-v table
function M.encodeTest(test)
    local errorKey = 'testSpecWrongSize'
    local t = M.specNamesToIndices(test)
    return M.encodeSpec(t, 3, 'invalidTestSpec', errorKey)
end

function M.encodeVarSpec(varSpec)
    local errorKey = 'varSpecWrongSize'
    return M.encodeSpec(varSpec, 4, 'invalidVarSpec', errorKey)
end

function M.encodeVarSpecTable(varSpec)
    local t = {
        varSpec.technology,
        varSpec.coverage,
        varSpec.testParameters,
        varSpec.varName
    }
    return M.encodeVarSpec(t)
end

function M.firstCriticalSectionNodes(actions)
    local firstNodes = {}

    for _, action in ipairs(actions) do
        if #action.deps == 0 then
            table.insert(firstNodes, action)
        end
    end

    return firstNodes
end

-- Check test spec from test definition against test specs used in main sequence
-- Expand any wildcards
function M.getUsedTestSpecs(testSpec, specsUsedByMain)
    local used = {}

    for _, usedTestSpec in ipairs(specsUsedByMain) do
        local usedSpec = usedTestSpec.testSpec
        local doesMatch, numWildcards = true, 0

        for testSpecField = 1, 3 do
            local doesMatchWildcard = testSpec[testSpecField] == '*' and
                                      usedSpec[testSpecField] ~= ''
            doesMatch = doesMatch and
                        ((testSpec[testSpecField] == usedSpec[testSpecField]) or
                        doesMatchWildcard)

            if doesMatch and doesMatchWildcard then
                numWildcards = numWildcards + 1
            end
        end

        if doesMatch then
            if not utils.isNonEmptyTable(usedTestSpec.matches) then
                usedTestSpec.matches = {}
            end

            usedTestSpec.matches[M.encodeTestSpec(testSpec)] = numWildcards
            table.insert(used, usedTestSpec.testSpec)
        end
    end

    return used
end

function M.separatorType(row)
    -- new type: -*-, -, -
    -- legacy: -,-,-, =,=,=
    local separator = M.separatorTypeNew(row)
    if separator then
        return separator
    else
        return M.separatorTypeLegacy(row)
    end
end

-- new style:
--  Technology: - or starts and ends with -, like -, -PHASE- and -TEARDOWN-
--  Coverage & TestParameters: -
--  others: blank
function M.separatorTypeNew(row)
    local isSeparator = true
    local areOtherFieldsBlank = true
    local columns = common.SHARED_COLUMNS
    local separatorField = {
        [columns.Technology] = '^%-(.*)%-$',
        [columns.Coverage] = '^-$',
        [columns.TestParameters] = '^-$'
    }

    -- what separator it is: PHASE, PARALLEL or TEARDOWN
    local separator
    for fieldName, field in pairs(row) do
        local pattern = separatorField[fieldName]
        if pattern then
            local match = string.match(field, pattern)
            isSeparator = isSeparator and (match ~= nil)
            if fieldName == columns.Technology then
                separator = match
            end
        else
            areOtherFieldsBlank = areOtherFieldsBlank and
                                  not utils.isNonEmptyString(field)
        end
    end

    -- valid tech/cov/testParam but other columns are non-empty
    -- or tech is valid but cov/testParam is not -
    local invalidSeparator = separator and
                             (not isSeparator or not areOtherFieldsBlank)
    if invalidSeparator then
        assert(separator, '[internal] separator is nil when isSeparator==true')
        local mapping = {
            [separators.PARALLEL] = function()
                E:badParallelGroupSeparator()
            end,
            [separators.TEARDOWN] = function()
                E:badTeardownSeparator()
            end,
            [separators.PHASE] = function() E:badPhaseSeparator() end
        }
        if mapping[separator] == nil then
            E:unrecognizedSeparator(separator)
        end
        mapping[separator]()
    end

    if isSeparator and separator then
        if common.separators[separator] == nil then
            E:unrecognizedSeparator(separator)
        end
    end

    return isSeparator and separator
end

function M.separatorTypeLegacy(row)
    local isParallelGroupSeparator = M.isLegacySeparator(row, '-', function()
        E:badParallelGroupSeparator()
    end)
    local isTeardownSeparator = M.isLegacySeparator(row, '=', function()
        E:badTeardownSeparator()
    end)
    return (isParallelGroupSeparator and separators.PARALLEL) or
           (isTeardownSeparator and separators.TEARDOWN)
end

-- for === and ---
-- return true if
--  Technology, Coverage and TestParameters are the same as given string
-- all other fields are blank
function M.isLegacySeparator(row, separator, errorFn)
    local areAllSeparators, areOtherFieldsBlank = true, true
    local hasSeparators = false
    local isSeparatorField = {
        Technology = true,
        Coverage = true,
        TestParameters = true
    }

    for fieldName, field in pairs(row) do
        if isSeparatorField[fieldName] then
            local isFieldSeparator = field == separator
            areAllSeparators = areAllSeparators and isFieldSeparator
            if isFieldSeparator then
                hasSeparators = true
            end
        else
            areOtherFieldsBlank = areOtherFieldsBlank and
                                  not utils.isNonEmptyString(field)
        end
    end

    if (areAllSeparators and not areOtherFieldsBlank) or
    (not areAllSeparators and hasSeparators) then
        errorFn()
    end

    return areAllSeparators
end

function M.isRowEmpty(row)
    local isEmpty = true

    for _, cell in pairs(row) do
        if utils.isNonEmptyString(cell) then
            isEmpty = false
        end
    end

    return isEmpty
end

function M.lastCriticalSectionNodes(actions)
    local unreferencedNodes = pl.Set(pl.tablex.range(1, #actions))

    for actionIdx, action in ipairs(actions) do
        if #action.deps > 0 then
            unreferencedNodes[actionIdx] = nil
        end
    end

    local sortedUnreferencedNodes = pl.tablex.keys(unreferencedNodes)
    table.sort(sortedUnreferencedNodes)

    return pl.tablex.map(function(idx) return actions[idx].name end,
                         sortedUnreferencedNodes)
end

function M.makeTestNames(technology, coverage, testParameters)
    local subtest = coverage

    if utils.isNonEmptyString(testParameters) then
        subtest = subtest .. '_' .. testParameters
    end

    return technology, subtest
end

function M.createLimitName(testname, subtestname, subsubtest)
    local limitName = {}

    if utils.isNonEmptyString(testname) then
        table.insert(limitName, "Test:" .. testname)
    end

    if utils.isNonEmptyString(subtestname) then
        table.insert(limitName, " Subtest:" .. subtestname)
    end

    if utils.isNonEmptyString(subsubtest) then
        table.insert(limitName, " SubSubTest:" .. subsubtest)
    end

    return pl.stringx.join("", limitName)
end

function M.createLimitNameWithCoverage(limit)
    local testname, subtestname = M.makeTestNames(limit.Technology,
                                                  limit.Coverage,
                                                  limit.TestParameters)
    return M.createLimitName(testname, subtestname, limit.SubSubTest)
end

function M.markCriticalSection(actions)
    local nameToAction = {}
    for _, actionRow in ipairs(actions) do
        local name, action = M.nameAction(actionRow)
        nameToAction[name] = action
    end

    local didChange
    local changedActions = {}
    repeat
        didChange = false
        for _, actionRow in ipairs(actions) do
            local name, action = M.nameAction(actionRow)

            if action.background == nil or action.background == false then
                -- Ensure it's not nil
                action.background = false

                for _, dep in ipairs(action.deps) do
                    local depAction = nameToAction[dep]
                    if depAction.background == true then
                        depAction.background = false
                        didChange = true

                        local changedDeps = changedActions[name] or {}
                        table.insert(changedDeps, 1, dep) -- insert in the front so lists in top to bottom order
                        changedActions[name] = changedDeps
                    end
                end
            end
        end
    until didChange == false

    for actionName, changedDeps in ipairs(changedActions) do
        E:warnChangedBackground(actionName, changedDeps)
    end
end

function M.nameAction(actionRow)
    local name, action = nil, nil
    for name_, action_ in pairs(actionRow) do
        if name ~= nil then
            E:actionRowTooLarge()
        end
        name, action = name_, action_
    end

    return name, action
end

-- Parse Dependencies column, ensure always 3 items per dependency
function M.parseTestDependency(rawDeps)
    local deps = pl.List()

    if utils.isNonEmptyString(rawDeps) then
        for depStr in rawDeps:gmatch(common.dependencyFormat) do
            local dep = pl.stringx.split(depStr, ',')
            if #dep > common.NUM_FIELDS_IN_DEPS then
                E:dependencyWrongSize(depStr)
            end

            -- dep = {Technology, Coverage, testParameters}
            -- Workaround for checkFieldFormat re-factor to avoid magic numbers.
            local fieldNames = {
                common.TECHNOLOGY,
                common.COVERAGE,
                common.TEST_PARAMETERS
            }
            for idx, item in ipairs(dep) do
                item = item:gsub('"', '')
                item = item:gsub("'", '')
                item = pl.stringx.strip(item)
                M.checkFieldFormat(item, fieldNames[idx], 'badSpecFieldFormat')
                dep[idx] = item
            end
            for idx = #dep + 1, common.NUM_FIELDS_IN_DEPS do
                dep[idx] = ''
            end

            local depString = M.encodeTestSpec(dep)
            if not deps:contains(depString) then
                deps:append(depString)
            end
        end

        if #deps == 0 then
            E:dependencyBadFormat(rawDeps)
        end
    end

    return deps
end

function M.specIndicesToNames(spec)
    return {
        technology = spec[1] or '',
        coverage = spec[2] or '',
        testParameters = spec[3] or ''
    }
end

function M.specNamesToIndices(spec)
    return {
        spec.technology or spec.Technology or '',
        spec.coverage or spec.Coverage or '',
        spec.testParameters or spec.TestParameters or ''
    }
end

-- for a background action, all actions depending on it should be background
function M.checkActionsBackground(allActions)
    -- dict with action name as key
    local actionDictionary = {}
    for _, row in ipairs(allActions) do
        local name, action = M.nameAction(row)
        actionDictionary[name] = action
    end

    for _, row in ipairs(allActions) do
        local name, action = M.nameAction(row)
        if action.deps ~= nil and action.background ~= true then
            for _, dep in ipairs(action.deps) do
                if actionDictionary[dep].background == true then
                    E:wrongBackgroundUse(name, dep)
                end
            end
        end
    end
end

-- Create graph for actions within a test definition
function M.sortActions(testDef, names)
    local actions = testDef.actions
    local sortedActions = {}

    local function checkAction(name)
        if not names[name] then
            E:actionNotFound(name)
        end
    end

    local function checkDeps(action)
        if (action.deps ~= nil and type(action.deps) ~= 'table') and
        not utils.isNonEmptyArray(action.deps) then
            E:badDataType('action.deps must be nil or a nonempty array')
        end

        for _, dep in ipairs(action.deps or {}) do
            checkAction(dep)
        end
    end

    if actions.type == SEQUENTIAL then
        -- Already sorted, so just add directly to sortedActions
        local previousAction = nil
        for _, action in ipairs(actions) do
            local name = action.name

            checkAction(name)
            checkDeps(action)

            if previousAction ~= nil then
                local deps = pl.Set(action.deps or {})
                deps = deps + previousAction
                action.deps = pl.Set.values(deps)
            else
                if utils.isNonEmptyArray(action.deps) then
                    E:badInitialAction()
                end
            end

            table.insert(sortedActions, { [name] = action })

            previousAction = name
        end
    elseif actions.type == GRAPH then
        local actionsToSort = {}
        local function getter(action)
            local name = action.name
            checkAction(name)
            checkDeps(action)

            -- Remove duplicates
            action.deps = pl.Set.values(pl.Set(action.deps or {}))

            actionsToSort[name] = action

            for _, dep in ipairs(action.deps) do
                checkAction(dep)
            end

            return name, action.deps
        end

        local sortedActionNames = M.sort(actions, getter)
        for _, name in ipairs(sortedActionNames) do
            table.insert(sortedActions, { [name] = actionsToSort[name] })
        end
    else
        E:unknownSequenceType(actions.type)
    end

    M.checkActionsBackground(sortedActions)

    return sortedActions
end

function M.sortMainGraph(testSpecToRow, dagName)
    -- initialNode is so initial rows don't get dropped
    local mainGraph, initialNode = tsort.new(), {}
    for _, row in pairs(testSpecToRow) do
        E:pushLocation('Row ' .. row.originalRowIdx)

        local secondNode = row

        mainGraph:add(initialNode, secondNode)

        for _, encodedDep in pairs(row.encodedDeps or {}) do
            local firstNode = testSpecToRow[encodedDep]

            -- Dependency found means
            -- 1. Matching Tech + Coverage + TestParameters (within a fixed Mode)
            -- 2. Consumer's Product contained in producer's Product
            -- 3. Consumer's StationType contained in producer's StationType
            if not (utils.isNonEmptyTable(firstNode) and
            M.isSubset(row.product, firstNode.product) and
            M.isSubset(row.stationType, firstNode.stationType)) then
                E:dependentTestNotFound(encodedDep,
                                        firstNode and firstNode.mode or {},
                                        firstNode and firstNode.product or {},
                                        firstNode and firstNode.stationType or
                                        {}, dagName)
            end

            mainGraph:add(firstNode, secondNode)
        end

        for _, dep in pairs(row.additionalDependencies) do
            local firstNode = testSpecToRow[dep]
            if not utils.isNonEmptyTable(firstNode) then
                E:dependentTestNotFound(dep, firstNode and firstNode.mode or {},
                                        firstNode and firstNode.product or {},
                                        firstNode and firstNode.stationType or
                                        {})
            end

            mainGraph:add(firstNode, secondNode)
        end

        -- Pop rowIdx
        E:popLocation()
    end

    -- Topologically sort main graph
    local sortedMainGraph, errMsg = mainGraph:sort()
    if sortedMainGraph == nil then
        E:mainSeqSortError(errMsg)
    end

    -- Remove initial node
    for rowIdx, row in ipairs(sortedMainGraph) do
        if row == initialNode then
            table.remove(sortedMainGraph, rowIdx)
            break
        end
    end

    return sortedMainGraph
end

-- Returns boolean indicating whether field1 is a subset of field2
-- Ex: field1 = {'J1', 'J2'}, field2 = {'J2'} ---> return false
-- Schooner treats nil (empty cell) as ALL_SEEN or expected-from-IN or ANY
-- {'J1'} < ALL_SEEN < IN(...) < ANY
function M.isSubset(field1, field2)
    return field2 == nil or (field1 ~= nil and pl.Set(field1) < pl.Set(field2))
end

-- Remove redundant info from coverage.lua
-- Compare against IN(...) reason:
-- test.filter = { 'J1' }
-- allSeen = { 'J1' }
-- IN('J1', 'J2')
-- If we remove filters from coverage.lua based on test.filter == allSeen,
-- then test can run for 'J2', which is a bug
function M.removeFiltersWhenAll(entries, expectedFilterValues)
    for _, entry in ipairs(entries) do
        -- Remove keys which contain all filters
        for _, filter in pairs(common.ALL_FILTERS) do
            if pl.tablex.compare_no_order(entry[filter] or {}, helper.tableKeys(
                                          expectedFilterValues[filter]) or {}) then
                entry[filter] = nil
            end
        end
    end
end

-- Populate a set of entries (tests or limits) which have empty
-- filter values with desired filter values.
-- @args entries - table of entries (ex. main tests)
-- @args filters - dictionary of all desired filter values
function M.populateEmptyFilters(entries, filters)
    for _, entry in ipairs(entries) do
        for filterType, allFilters in pairs(filters) do
            if entry[filterType] == nil then
                entry[filterType] = allFilters
            elseif not utils.isNonEmptyTable(entry[filterType]) then
                -- only Schooner developer should see this, so using assert.
                local message =
                '[Internal] filterType = %s is %s, expecting nil or non-empty table'
                message = message:format(filterType,
                                         helper.dump(entry[filterType]))
                error(message)
            end
        end
    end
end

-- Process fields (ex. Mode, Product, StationType, AllowedList) for all test or limit entries.
-- This function will transform a single delimiter-separated string (ex. "Production,Rel")
-- into a Lua table (ex. {"Production", "Rel"}). Return nil for empty string.
--
-- @arg fieldString - input string to be split
-- @arg escapeSymbol - (optional) symbol for escaping the delimiter, default='\'
-- @arg delimiterSymbol - (optional) delimiter used to separate values, default=','
function M.stringToArray(fieldString, escapeSymbol, delimiterSymbol)
    -- For empty field, use nil instead of empty table.
    if fieldString == '' then
        return nil
    end

    local delimiter = delimiterSymbol or ','
    local escape = escapeSymbol or '\\'

    if not utils.isValidString(fieldString) then
        local message = "stringToArray: expecting string but got %s (type: %s)"
        message = message:format(tostring(fieldString), type(fieldString))
        E:badDataType(message)
    end

    -- Don't allow isolated escape characters
    if M.containsIsolatedEscape(fieldString, escape, delimiter) then
        error_:isolatedEscapeCharacter(escape)
    end

    -- Find all non-escaped delimiters and split
    local words = M.splitAtNonEscapedDelimiters(fieldString, escape, delimiter)

    -- Resolve all escaped characters
    words = M.resolveAllEscapedCharacters(words, escape, delimiter)

    for idx, word in ipairs(words) do
        -- Erase all prefix and postfix whitespaces for each array element
        words[idx] = pl.stringx.strip(word)
    end

    return words
end

-- Determines if given string contains an isolated escape character
-- When an escape character is found, the only characters allowed before or after are
-- 1. itself (before/after) ex: \\
-- 2. delimiter (after) ex: \,
-- 3. a single alphabetical character (after) ex: \n
-- Otherwise, the escape character is determined to be isolated
function M.containsIsolatedEscape(str, escape, delimiter)
    local tmpStr = str
    -- Try to capture longest consecutive substring of escapes
    local capturePattern = string.format('(%s*)', escape)

    -- Actual findPattern is: '(\*)\(\*)'
    local findPattern = string.format('%s%s%s', capturePattern, escape,
                                      capturePattern)

    while true do

        local _, postCapIdx, preCap, postCap = tmpStr:find(findPattern)

        -- No escape was found
        if postCapIdx == nil then
            break
        end

        -- Find total number of consecutive escapes in the string
        -- Empty captures have length 0 so they don't affect numEscapes
        -- The 1 represents escape matched but not captured in string
        local numEscapes = preCap:len() + 1 + postCap:len()

        -- numEscapes should be even, or odd and followed by allowed char (\ , [%a])
        if numEscapes % 2 == 1 then
            -- Char after last escape captured, could be empty string
            local postChar = pl.stringx.at(tmpStr, postCapIdx + 1)
            if postChar ~= escape and postChar ~= delimiter and
            not utils.isSingleLetter(postChar) then
                return true
            end
        end

        -- Update subject string to non-parsed piece
        tmpStr = tmpStr:sub(postCapIdx + 1)
    end
    return false
end

-- args same as checkForIsolatedReturns
function M.removeQuotedContent(content)
    -- Ex: 'a,b,c,"xxxyy"\r,1,"2",3'
    -- This function removes all content within double quotes, including the quotes
    -- For example, the input string 'a,b,c,"xxxyy"\r,1,"2",3' would become 'a,b,c,\r,1,,3'
    return content:gsub('"(.-)"', '')
end

-- args:
-- content - content of file:read("*a") as one long string
function M.checkForIsolatedReturns(content)
    -- \r should be followed by \n, capture character following \r
    local findPattern = '()\r(.?)'

    local copy = M.removeQuotedContent(content)
    local matchs = copy:gmatch(findPattern, 1)
    local capPos = 1
    for startPos, charAfterCR in matchs do
        if charAfterCR ~= '\n' then
            error_:isolatedReturn(string.sub(copy, capPos, startPos))
        end
        capPos = startPos + 1
    end
end

-- Splits given string at non-escaped occurrences of delimiter
-- Ex. 'a, b\,c, d' becomes {"a", "b\,c", "d"} (escape='\', delimiter=',')
-- Note that escaped characters are not resolved
function M.splitAtNonEscapedDelimiters(str, escape, delimiter)

    -- Edge case if string is empty
    if not utils.isNonEmptyString(str) then
        return {}
    end

    local words = {}
    local searchStart = 1
    local splitIdx = 1

    -- Add delimiter to end of str to capture last element of str
    str = str .. delimiter
    while true do
        -- Find first occurrence of delimiter,
        -- and capture longest chain of escape characters preceeding the delimiter
        local _, foundIdx, captureBefore = str:find(
                                           string.format('(%s*)', escape) ..
                                           delimiter, searchStart)

        if foundIdx == nil then
            break
        end

        -- Even number of escape characters indicates a true-delimiter, so we should split
        if captureBefore:len() % 2 == 0 then
            -- Get substring from last splitIdx to position before foundIdx
            local word = str:sub(splitIdx, foundIdx - 1)
            table.insert(words, word)
            splitIdx = foundIdx + 1
        end
        searchStart = foundIdx + 1
    end
    return words
end

-- @arg words - array of strings split by delimiter
function M.resolveAllEscapedCharacters(words, escape, delimiter)
    for idx, word in ipairs(words) do
        -- '\\' becomes '\'
        word = word:gsub(escape .. escape, escape)
        -- '\,' becomes ','
        word = word:gsub(escape .. delimiter, delimiter)

        -- '\t' stays as '\t'
        words[idx] = word
    end
    return words
end

-- return topo-sorted array
-- args:
--    container: array/table; shouldn't be nil.
--    getter: a function that return (item, deps)
function M.sort(items, getter)
    local graph = tsort.new()
    for _, item in pairs(items) do
        local value, deps = getter(item)
        graph:add(value)
        if deps ~= nil then
            if type(deps) ~= 'table' then
                error('sort: deps ' .. tostring(deps) .. ' is not table')
            end
            for _, dep in ipairs(deps) do
                graph:add(dep, value)
            end
        end
    end

    -- Topologically sort action graph
    local ret, errMsg = graph:sort()
    if ret == nil then
        E:actionSortError(errMsg)
    end

    return ret
end

-- Merge test entries from main tests and teardown tests into a single table
--
-- @arg mainTests - Main test entries
-- @arg teardownTests - Teardown test entries
--
-- @return - A table containing all main and teardown tests
function M.mergeMainAndTeardownTest(mainTests, teardownTests)
    local allTests = pl.tablex.copy(mainTests)
    allTests = table.move(teardownTests, 1, #teardownTests, #allTests + 1,
                          allTests)

    return allTests
end

-- Create a string formatted key for an entry based on its unique test descriptor
--
-- @arg entry - A test or limit entry from main or limit table, respectively
--
-- @return string formatted key
local function createEntryKey(entry)
    local entryKey = "Technology: %s, Coverage: %s, "
    entryKey = entryKey .. "TestParameters: %s, SubSubTest: %s"
    entryKey = entryKey:format(entry.Technology, entry.Coverage,
                               tostring(entry.TestParameters),
                               tostring(entry.SubSubTest))
    return entryKey
end

-- Conditional-limit support allows repeated limit names, so we need to
-- raise error if conditions don't overlap. This check is not exhaustive,
-- and some cases may leak to runner.
function M.findOverlappingConditions(entry, conditionData, entryKey)

    local identifiers = M.extractIdentifiers(entry.conditions)
    local numMatched = M.checkForOverlap(conditionData.identifiersCounter,
                                         identifiers)

    -- If we remove double-counted entries, and end up with < numEntries, then we
    -- removed an entry which
    -- 1. is double-counted AND
    -- 2. contains condition vars that are matched only with that entry
    -- This is not possible, so it's enough to match on more than numEntries
    if numMatched >= conditionData.numEntries then
        -- We've matched on all seen entries, so this entry is good.
        conditionData.numEntries = conditionData.numEntries + 1
        M.updateIdentifiersCounter(conditionData.identifiersCounter, identifiers)
        return false
    end
    error_:nonOverlappingConditionVariables(entryKey, conditionData.firstSeenIdx)
end

function M.checkForSingleEntryWithConditions(row, conditionData, entryKey)
    -- One of a pair of duplicate limits does not have a condition
    -- Possible scenarios:
    -- 1. Current row has conditions AND we've seen a nil condition row
    -- 2. Current row has nil conditions AND we've seen a row with conditions
    if (row.conditions == nil) ~= conditionData.noConditions then
        error_:limitMissingCondition(entryKey, conditionData.firstSeenIdx)
    end
    return false
end

function M.checkForDuplicateConditions(row, conditionData, entryKey)
    -- Two duplicate limits both don't have conditions
    if row.conditions == nil and conditionData.noConditions then
        error_:duplicateLimit(entryKey, conditionData.firstSeenIdx)
    elseif row.conditions and conditionData.rowConditions[row.conditions] then
        -- Both duplicate limits have the exact same condition
        error_:duplicateConditionInLimit(entryKey, conditionData.firstSeenIdx)
    end
    return false
end

local function hasIntersectionBetweenTwoArrays(array1, array2)
    return not pl.Set.isempty(pl.Set(array1) * pl.Set(array2))
end

-- TODO: add unit test for this function
local function hasOverlappingField(field1, field2)
    return field1 == nil or field2 == nil or utils.isEmptyTable(field1) or
           utils.isEmptyTable(field2) or
           hasIntersectionBetweenTwoArrays(field1, field2)
end

-- This function is called to check if a limit entry is a Set limit.
-- @arg entry - limit entry (row in limit table)
function M.isSetLimit(entry)

    local limitFields = {
        entry.relaxedUpperLimit,
        entry.upperLimit,
        entry.lowerLimit,
        entry.relaxedLowerLimit
    }

    return utils.isNonEmptyArray(entry.allowedList) and
           utils.isEmptyTable(limitFields)
end

-- This function is called when a duplicate main entry has been found.
-- Error out if existingModes intersects with newModes since this means
-- 2 main entries with the same name share a common mode.
--
-- @arg existingModes - Modes seen previous to duplicate entry
-- @arg entry         - A duplicate main entry
local function processDuplicateMainEntries(existingEntryData,
                                           entry)
    for _, data in ipairs(existingEntryData) do
        -- New entry or existing entry has blank mode (e.g. all modes) or
        -- duplicate mode is discovered from current entry being processed.
        if hasOverlappingField(entry[common.MODE], data[common.MODE]) then
            E:duplicateTestMode(entry)
        end
    end
end

-- This function is called when a duplicate limit entry has been found.
-- @arg existingEntry - Previously seen instance of limit with a given name
-- @arg entry         - A duplicate limit entry
function M.processDuplicateLimitEntries(entry, conditionData)

    local entryKey = createEntryKey(entry)
    M.checkForSingleEntryWithConditions(entry, conditionData, entryKey)
    M.checkForDuplicateConditions(entry, conditionData, entryKey)

    -- We've seen duplicates, so all rows should have conditions (e.g. entry.conditions ~= nil)
    local message = '[Internal] entry.conditions is nil: %s'
    message = message:format(helper.dump(entry))
    assert(entry.conditions ~= nil, message)

    -- Add seen condition to conditionData
    conditionData.rowConditions[entry.conditions] = true
    M.findOverlappingConditions(entry, conditionData, entryKey)

    -- For a given mode/product/stationType, duplicate limits which pass
    -- overlapping-condition-var-check shouldn't mix between Set/non-Set type
    -- Reasons:
    -- 1. No current use-cases requiring this
    -- 2. Could result in unexpected behavior: on runs 1-10 the limit registered is parametric,
    -- on run 11 the limit registered is Set. Since records are submitted with the
    -- same API (DataReporting.submitRecord) this might cause confusion.
    if M.isSetLimit(entry) ~= conditionData.isSetLimit then
        error_:duplicateLimitWithDifferentType(entryKey)
    end
end

-- @arg: identifiersCounter - dictionary with identifier-count as key-value
-- Ex: {[A] = 5, [B] = 2} => there are 5 conditions which use A as a condition variable
-- (may double count) for some duplicate limit entry
-- @arg: identifiers - array of condition variables used by incoming duplicate limit
function M.updateIdentifiersCounter(identifiersCounter,
                                    identifiers)
    for _, id in ipairs(identifiers) do
        -- If id has been seen before, increment by 1. Else set count to 1
        local count = identifiersCounter[id] or 0
        count = count + 1
        identifiersCounter[id] = count
    end
    return identifiersCounter
end

function M.checkForOverlap(identifiersCounter, identifiers)
    local numMatched = 0
    for _, id in ipairs(identifiers) do
        if identifiersCounter[id] then
            numMatched = numMatched + identifiersCounter[id]
        end
    end
    return numMatched
end

-- Check to see if filter values from Main/Limit appear in expected list
-- @arg     expected        Lua dictionary of expected values from IN validator
-- structure:
-- { mode = {Production = true}, stationType = {J1 = true, J2 = true} }; Product wasn't defined
-- @arg     actual          Lua dictionary of seen values from CSV content
-- structure:
-- { mode = {'Production'}, stationType = {'J1', 'J2'} }; Product didn't appear
function M.validateFilters(expected, actual)
    for filterType, values in pairs(actual) do
        if expected[filterType] then
            for _, val in ipairs(values) do
                if not expected[filterType][val] then
                    error_:unexpectedFilter(filterType, val,
                                            expected[filterType])
                end
            end
        end
        -- Used-but-not-defined handled with checkAllIdentifierInCondition
    end
end

-- Find and throw compiler error if there are duplicate entries within a CSV table.
--
-- The first condition of duplicate entries is that two or more rows in the same CSV table share their
-- technology, coverage, and test parameter values.  For limits, in additional to the previous 3 values,
-- subsubtests are also shared.
--
-- If the first condition is met, one of the following conditions must also be met for entries to be
-- considered duplicates:
-- 1) Entries match on product and stationType and mode filters
-- 2) Empty filter means all filter values (for limits, empty mode means all mode from Main.csv)
-- 3) For limits, overlapping condition expressions is also required to be considered duplicate

-- Duplicate entry checking is done in buildTree (Tree.lua) for limits
-- This function simply returns data used for limitVersion generation
-- TODO: Move logic here for limits to buildTree so that once a tree is constructed, we
-- get existingEntries
--
-- @arg allEntries - All limit or main table entries
-- @arg tableType - 'limits' or 'main'
-- @return existingEntries - Key-value table; key = duplicate entry name, value = dictionary
-- containing info about duplicate limits.
-- This return is only relevant when processing limit table entries.
-- ex: { data = {{index=3, mode={"Rel"}, product={}, stationType={}, identifiers={'A'}, conditions={'A==1'}}, ... },
--       duplicate = true }
function M.findDuplicateEntries(allEntries, tableType)
    local existingEntries = {}

    for _, entry in ipairs(allEntries) do
        -- Do not process group separator rows
        if (tableType == MAIN) and entry.separator then
            goto continue
        end

        -- Increase headlerless index by 1 to get proper index in csv.
        E:pushLocation('Row ' .. entry.originalRowIdx + common.NUM_HEADER_LINES)

        local entryKey = createEntryKey(entry)
        local existingEntry = existingEntries[entryKey]
        -- First time this entry has been observed
        if existingEntry == nil then
            local existingEntryData = {}

            existingEntryData.index = entry.originalRowIdx +
                                      common.NUM_HEADER_LINES
            existingEntryData.mode = helper.clone(entry.mode)

            -- Add additional data from limit entries
            if tableType == common.LIMITS then
                existingEntryData.conditions = entry.conditions
                -- Keep track of condition variables already seen for generating limit version.
                local seenVariables = M.extractIdentifiers(entry.conditions)
                existingEntryData.identifiers = pl.Set(seenVariables)
                existingEntryData.product = entry.product
                existingEntryData.stationType = entry.stationType
                existingEntryData.entry = entry
            end

            existingEntries[entryKey] = {
                data = { existingEntryData },
                entries = { entry }
            }
        else
            -- Used to gather all condition variables for duplicated limit.
            existingEntry.duplicate = true
            local newEntryData = {}
            newEntryData.index = entry.originalRowIdx + common.NUM_HEADER_LINES
            newEntryData.mode = helper.clone(entry.mode)

            -- Not the first time this entry has been observed; Search for duplicates
            if tableType == MAIN then
                processDuplicateMainEntries(existingEntry.data, entry)
            end
            if tableType == common.LIMITS then
                -- Duplicate entry checks performed in buildTree
                newEntryData.conditions = entry.conditions
                newEntryData.product = entry.product
                newEntryData.stationType = entry.stationType
                newEntryData.entry = entry
                -- Keep track of condition variables already seen for generating limit version.
                local rowIdentifiers = pl.Set(
                                       M.extractIdentifiers(entry.conditions))
                newEntryData.identifiers = rowIdentifiers

                -- currently only set duplicates for limits
                -- because it is only used by limits version
                entry.duplicate = true
                if #existingEntry.entries == 1 then
                    existingEntry.entries[1].duplicate = true
                end
            end
            table.insert(existingEntry.data, newEntryData)
            table.insert(existingEntry.entries, entry)
        end
        E:popLocation()
        ::continue::
    end
    for k, v in pairs(existingEntries) do
        if not v.duplicate then
            existingEntries[k] = nil
        end
    end

    return existingEntries
end

function M.singleQuoted(s) return "'" .. s .. "'" end

function M.doubleQuoted(s) return '"' .. s .. '"' end

function M.checkLookupReturnIdx(returnIdx)
    if not utils.isValidNumber(returnIdx) then
        local msg = 'returnIdx must be nil, a number, '
        msg = msg .. 'or "overallResult"'
        E:badDataType(msg)
    end
end

-- remove `Notes` from the row.
-- Notes is for human, schooner does not use it
-- so drop it after reading from CSV file.
function M.removeNotes(row) row.Notes = nil end

-- 1. strip any space characters
-- 2. remove outter level '' or ""
function M.stripAndUnquote(x)
    x = pl.stringx.strip(x)
    if x == '""' or x == "''" then
        return ''
    end
    local ret = x:match("^'(.+)'$") or x:match('^"(.+)"$')
    if ret == nil then
        E:badFieldToStripAndUnquote(x)
    end
    return ret
end

-- pattern: string with *, like A*, *B or A*B
-- str: string that want to check if match the pattern, like AB
function M.stringWildcardMatch(pattern, str)
    pattern = M.escapeMagicChars(pattern, common.MAGIC_CHARACTERS)
    pattern = '^' .. pattern:gsub('*', '(.*)') .. '$'
    return str:find(pattern)
end

-- test1/test2: {technology=x, coverage=y, testParameters=z}
-- test2: testParameters could contains * as pattern, like A*B*
-- test1: actual test names from Main, cannot have *.
-- return: nil if not match.
--         string.find()'s return if match:
--         start, length, [capture groups]
function M.wildcardMatch(test1, test2)
    if test1.technology ~= test2.technology then
        return
    end
    if test1.coverage ~= test2.coverage then
        return
    end
    return M.stringWildcardMatch(test2.testParameters, test1.testParameters)
end

-- Escapes all special characters (e.g. '-', '+', etc) in given string using Lua convention
-- Ex: '-' becomes '%-'
function M.escapeMagicChars(string, charsToEscape)
    if string == nil then
        return ''
    end

    -- Handle '%' first
    -- '%%' as pattern: looking for '%'
    -- '%%%%' as replacement: replace with '%%'
    string = string:gsub('%%', '%%%%')

    for _, char in ipairs(charsToEscape) do
        string = string:gsub(char, '%' .. char)
    end
    return string
end

-- return if the given string is a supported testParameters pattern
-- 1. has "*" inside
-- 2. (in future PR) has loop syntax inside.
function M.hasPattern(str) return str:find('*') ~= nil end

-- loop support

-- only support decimal and floating point like 1, 1.1, -1.2
function M.tonumber(x, name)
    assert(x ~= nil)
    assert(name ~= nil)
    local patternInt = '^[-]?[0-9]+$'
    local patternFloat = '^[-]?[0-9]+%.[0-9]+$'
    if x:find(patternInt) or x:find(patternFloat) then
        return tonumber(x)
    else
        E:notSupportedNumberInLoop(x, name)
    end
end

-- only support decimal and floating point like 1, 1.1, -1.2
function M.toUInt(x)
    if x == nil then
        return nil
    end
    local patternInt = '^[1-9][0-9]*$'
    if x:find(patternInt) then
        return tonumber(x)
    else
        E:notSupportedNumberAsLoopCount(x)
    end
end

-- check if range is one of
--   1. [start:last]
--   2. [start:last#count]
--   3. [start:step:last].
--   4. [start:step:last#count].
-- return start, step, last, [count] if yes, as string.
-- count is nil when user does not provide it.
-- error if not.
function M.parseRange(range)
    local rangeItemsPattern = '^[%w-.]+$'
    local rangePatternToFields = {
        -- the order or pattern make sense here.
        -- need to search from top to bottom or 1:10#10 will be recognized
        -- as start = 1 and last = 10#10 which is not what we want
        {
            '^([^.].*):([^.].*):([^.].*)#([^#]*)$',
            { 'start', 'step', 'last', 'count' }
        },
        { '^([^.].*):([^.].*):([^.].*)$', { 'start', 'step', 'last' } },
        { '^([^.].*):([^.].*)#([^#]*)$', { 'start', 'last', 'count' } },
        { '^([^.].*):([^.].*)$', { 'start', 'last' } }
    }

    for _, patternSetting in ipairs(rangePatternToFields) do
        local pattern = patternSetting[1]
        local fieldNames = patternSetting[2]
        local fields = { range:match(pattern) }
        if #fields > 0 then
            -- mind that pairmap requires f to return value, key
            local f = function(i, v) return v, fieldNames[i] end
            local parsedRange = pl.tablex.pairmap(f, fields)
            parsedRange.step = parsedRange.step or '1'
            return parsedRange
        end
    end
    -- try to parse as comma separated list; ignore space around ,
    local items = pl.stringx.split(range, ',')
    -- [a] doesn't make sense. at least there should be 2 items.
    if #items > 1 then
        for idx, item in ipairs(items) do
            local stripped = pl.stringx.strip(item)
            -- Red, -1, 2.2
            if not stripped:find(rangeItemsPattern) then
                E:unsupportedItemInItems(item, range)
            end
            items[idx] = stripped
        end
        return { items = items }
    end

    E:unrecognizedRange(range)
end

-- get decimal places of start, step and last and return it.
-- error out if they have different decimal places.
-- param range: only for error reporting.
function M.checkAndGetDecimals(start, step, last, range)
    -- number of decimal places should be the same
    local decimalsOfStart = M.numberOfDecimals(start)
    local decimalsOfStep = M.numberOfDecimals(step)
    local decimalsOfLast = M.numberOfDecimals(last)

    if decimalsOfStart ~= decimalsOfLast or decimalsOfStart ~= decimalsOfStep then
        E:rangeHasDifferentDecimals(range, decimalsOfStart, decimalsOfStep,
                                    decimalsOfLast)
    end

    -- should be the same. Just choose one.
    return decimalsOfStart
end

-- 2.01*100 = 200.99999999999997158
-- 2.0001*10000 = 20001.00000000000363798
-- what we want is 201 and 20001
-- math.floor() or math.ceil() does not work here
-- use '%.f' to round to nearest int
function M.nearestInt(x) return tonumber(string.format('%.f', x)) end
function M.checkLastAndCountValid(start, step, last, decimals, count, range)
    -- last should be valid
    local intStart = start
    local intStep = step
    local intLast = last
    if step ~= 1 then
        intStart = M.nearestInt(start * 10 ^ decimals)
        intStep = M.nearestInt(step * 10 ^ decimals)
        intLast = M.nearestInt(last * 10 ^ decimals)
        if ((intLast - intStart) % intStep) ~= 0 then
            E:invalidLastInRange(range, last)
        end
    end
    if count and (intLast - intStart) / intStep + 1 ~= count then
        E:incorrectCountInRange(range, count)
    end
end

-- param range: only for error reporting.
function M.isValidRange(start, step, last, range)
    if step == 0 or (step > 0 and start >= last) or (step < 0 and start <= last) then
        -- [1:0:10]
        -- [1:1], [4:1:3]
        -- [1:-1:1] [1:-1:4]
        E:invalidRange(range, start, step, last)
    end
end

-- 1. parse '1.0:0.1:10.0' into start/step/last
-- 2. validate start/last/step are all numbers.
-- 3. validate start ~= last; [1:1] doesn't make sense.
-- 4. validate last is in the right direction: [1, 1, 0] [4, -1, 5] are invalid.
-- 5. validate number of digits of start/step/last should be the same
-- 6. validate last should be the last valid number
function M.parseAndValidateRange(range)
    local parsed = M.parseRange(range)
    if parsed.items then
        -- items
        return parsed
    else
        -- range
        local start = parsed.start
        local step = parsed.step
        local last = parsed.last
        local count = parsed.count
        E:pushLocation('Range ' .. tostring(range))

        -- number of decimal places should be the same
        local decimals = M.checkAndGetDecimals(start, step, last, range)

        -- start/step/last should be number
        start = M.tonumber(start, 'start')
        step = M.tonumber(step, 'step')
        last = M.tonumber(last, 'last')
        count = M.toUInt(count)

        M.isValidRange(start, step, last, range, count)

        M.checkLastAndCountValid(start, step, last, decimals, count, range)

        E:popLocation()
        return { start = start, step = step, last = last, decimals = decimals }

    end
end

-- if row.TestParameters contains loop syntax
-- expand it and return expanded test.
-- for non loop test, return {row}
function M.expandLoopInTestParameters(row)
    return M.expandLoopInRowForKey(row, 'TestParameters')
end

function M.expandLoopInLimitRow(row)
    return M.expandLoopInRowForKeys(row, { 'TestParameters', 'SubSubTest' })
end

-- if row.key contains loop syntax
-- expand it and return expanded test.
-- for non loop test, return {row}
function M.expandLoopInRowForKey(row, key)
    assert(row[key],
           '[Internal] row does not have key [' .. tostring(key) .. ']: ' ..
           helper.dump(row))
    local regexLoop = '%[([^%[%]]+)%]'
    local ranges = {}
    for range in row[key]:gmatch(regexLoop) do
        table.insert(ranges, M.parseAndValidateRange(range))
    end
    if next(ranges) == nil then
        return { helper.clone(row) }
    end

    return M.expandRanges(ranges, row, key)
end

-- multiple row, single key
function M.expandLoopInRowsForKey(rows, key)
    local ret = {}
    for _, row in ipairs(rows) do
        local expandedRows = M.expandLoopInRowForKey(row, key)
        for _, item in ipairs(expandedRows) do
            table.insert(ret, item)
        end
    end
    return ret
end

function M.expandLoopInRowForKeys(row, keys)
    local ret = { row }
    for _, key in ipairs(keys) do
        ret = M.expandLoopInRowsForKey(ret, key)
    end

    return ret
end

function M.expandRanges(ranges, row, key)
    return M.expandRange(ranges, 1, row, key)
end

-- get the number of decimal places of given number.
-- Purpose:
-- 1. in Loop syntax, start/step/last should have the same decimals
--    Schooner will error out when they don't, like [1:0.1:4].
--    The reason is schooner is confused whether to user 2 or 2.0 for number 2.
-- 2. Determine what should be multiplied when doing the for loop.
--    For decimals = 0, do not multiply.
--    For decimals = 1, like [1.0:0.1:4.0], schooner need to convert
--     start/step/last to integer by multiply by 10 ([1, 1, 4]), then do the loop.
--    The reason is if we don't do this, with a for loop `for i = 1.0, 4.0, 0.1`
--    the last number will not count 4.0 because adding `0.1` is actually adding 0.10000000000000001
--    so accumulatly the last valid number is 3.90000000000000258, not 4.0
--        > 3.90000000000000258 + 0.1 > 4.0
--        true
--        > 3.90000000000000258 + 0.1 == 4.0
--        false
--    But we want 4.0 to be the last valid number because user put it in TestParameters.
function M.numberOfDecimals(x)
    assert(type(x) == 'string')
    local locationOfDot = x:find('%.')
    local decimalPlaces = 0
    if locationOfDot ~= nil then
        decimalPlaces = x:len() - locationOfDot
    end
    -- being defensive; randomly choosing 19 as a max number of decimal places
    -- I cannot image people putting a range like this in TestParameters:
    -- [1.12345678901234567890:2.11112111121111211112:3.09876543210987654321]
    local maxDecimals = 19
    if decimalPlaces > maxDecimals then
        E:exceedMaxSupportedDecimals(x, maxDecimals)
    end
    return decimalPlaces
end

-- create iterator for a range-style loop
-- with start, step, last and decimal.
function M.iterRange(range)
    local start = range.start
    local last = range.last
    local step = range.step or 1
    local decimals = range.decimals

    if decimals ~= 0 then
        start = M.nearestInt(start * 10 ^ decimals)
        step = M.nearestInt(step * 10 ^ decimals)
        last = M.nearestInt(last * 10 ^ decimals)
    end

    local value = start
    local func = function()
        -- finish looping
        if (step > 0 and value > last) or (step < 0 and value < last) then
            assert(value - step == last)
            return nil
        end

        local ret
        if decimals == 0 then
            ret = tostring(value)
        else
            ret = string.format('%.0' .. decimals .. 'f', value / 10 ^ decimals)
        end
        value = value + step
        return ret
    end

    return func
end

-- shark: not sure if there are better implementation...
--        This code is a no-index version of next()
--        looks silly.
function M.iterItems(items)
    local i = nil
    local func = function()
        local v
        i, v = next(items, i)
        return v
    end
    return func
end

-- function to return an iterator of a loop item.
function M.iterLoop(loop)
    if loop.items then
        return M.iterItems(loop.items)
    elseif loop.start ~= nil and loop.last ~= nil then
        return M.iterRange(loop)
    else
        E:internalInvalidLoop(loop)
    end
end

-- param ranges: {range1, range2, ...}
--              range: {start=1.0, step=0.1, last=2.0, decimals=1}
-- param index: the N-th range to proceed. This is to support
--              process recursively.
-- param row: the csv row to expand.
-- param key: the key of row to expand, like TestParameters for test,
--            and TestParameters and SubSubTest for limit.
-- return: list of test/limit rows, expanded from ranges.
--         all tests/limits share the same attributes of row,
--         with row[key] updated according to ranges
--         for example, for range {start=1, step=1, last=10},
--         row.TestParameters='xyz[1:10]',
--         the 2nd item in return will have TestParameters = 'xyz2'
function M.expandRange(ranges, index, row, key)
    local range = ranges[index]
    assert(range, '[Internal] range[' .. index .. '] is nil')
    local numRanges = #ranges

    local rowValue = row[key]
    local ret = {}

    for value in M.iterLoop(range) do
        local isFirst = true

        -- substitue the 1st [] with actual loop value
        local func = function(x)
            if isFirst then
                isFirst = false
                return value
            else
                return x
            end
        end

        local newValue = rowValue:gsub('%[[^%[%]]-%]', func)
        local newRow = helper.clone(row)
        newRow[key] = newValue
        if index == numRanges then
            -- last range: finish the new row.
            table.insert(ret, newRow)
        else
            local newRows = M.expandRange(ranges, index + 1, newRow, key)
            for _, r in ipairs(newRows) do
                table.insert(ret, r)
            end
        end

    end

    return ret
end

-- add CSV rows into existing test tables.
-- Currently only to add rows extended by Loop syntax
-- to main/teardown/all tests.
function M.addRows(tests, rows)
    for _, row in ipairs(rows) do
        table.insert(tests, row)
    end
end

-- end of loop support

-- actions table
-- actions is an array; could iter with ipairs().
-- actions has a `.type` attribute: string `sequential` or `graph`.
-- to be convenient, actions support getting the action via action name
-- like actions.noop could return the 2nd action with name `noop`.
M.metatableActions = {}
-- error out for other values than sequential and graph
setmetatable(M.metatableActions,
             { __index = function(_, k) E:unknownSequenceType(k) end })
M.metatableActions[SEQUENTIAL] = {
    __index = function(_, key)
        if key == 'type' then
            return SEQUENTIAL
        end
    end
}

M.metatableActions[GRAPH] = {
    __index = function(_, key)
        if key == 'type' then
            return GRAPH
        end
    end
}

-- return 'list' or 'dictionary' according to actions structure
function M.getActionsStructure(actions)
    local keyType
    for key in pairs(actions) do
        if keyType then
            if type(key) ~= keyType then
                E:invalidActionsTable()
            end
        else
            keyType = type(key)
        end
    end
    local mapping = { number = ACTIONS_LIST, string = ACTIONS_DICTIONARY }
    return mapping[keyType]
end

-- convert sequence node into array of actions.
-- actions could be list, for sequential and graph test
-- actions could be dictionary, for graph test
function M.actionsToArray(sequence)
    assert(sequence ~= nil, 'test.sequence is nil')
    assert(sequence.actions ~= nil, 'test.actions is nil')
    local actionsType = sequence.type or SEQUENTIAL

    local actions = sequence.actions
    if next(actions) == nil then
        E:emptyActions()
    end
    -- list or dictionary
    local actionsStructure = M.getActionsStructure(actions)
    -- getter functions: return (name, action)
    local function getterList(key, value)
        -- key is index; value is the 1-key dictionary
        assert(type(key) == 'number')
        local actionLocation = 'Action index ' .. tostring(key)
        E:pushLocation(actionLocation)
        local name, action = M.nameAction(value)
        E:popLocation()
        return name, action
    end

    local function getterGraph(key, value)
        -- key is name; value is action dictionary
        assert(type(key) == 'string',
               'graph: key is not string: ' .. tostring(key))
        return key, value
    end

    local mapping = {
        [ACTIONS_LIST] = {
            -- list type actions could be graph or sequential.
            [GRAPH] = getterList,
            [SEQUENTIAL] = getterList
        },
        [ACTIONS_DICTIONARY] = {
            [GRAPH] = getterGraph
            -- dictionary actions is only supported by graph type
        }
    }

    local ret = {}
    local mt = M.metatableActions[actionsType]
    setmetatable(ret, mt)

    local func = mapping[actionsStructure][actionsType]
    if func == nil then
        E:invalidActionsTable()
    end

    for key, value in pairs(sequence.actions) do
        local name, action = func(key, value)

        action.name = name
        table.insert(ret, action)
    end

    return ret
end

function M.checkForRestrictedConditionNames(tokens)
    for _, token in ipairs(tokens) do
        if token.type == common.TOKEN_TYPE_IDENTIFIER then
            local stringValue = token.value
            local lowercaseTokenValue = string.lower(stringValue)
            if lowercaseTokenValue == common.PRODUCT or lowercaseTokenValue ==
            string.lower(common.STATION_TYPE) or lowercaseTokenValue ==
            common.MODE then
                E:conditionInvalidVariable(stringValue)
            end
        end
    end
end

return M
