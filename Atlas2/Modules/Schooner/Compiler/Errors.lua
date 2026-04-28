local pl = require('pl.import_into')()
local utils = require('Schooner.Compiler.Utils')
local common = require('Schooner.SchoonerCommon')
local helper = require('Schooner.SchoonerHelpers')
local dump = helper.dump

local M = { locationStack = {} }

local function raise(self, msgType, brief, msg)
    local msgType_ = tostring(msgType)
    msgType_ =
    ({ error = 'error', internal = 'internal', warning = 'warning' })[msgType_] or
    ('UNKNOWN MESSAGE TYPE "' .. msgType_ .. '"')

    local prefix = ({
        error = 'Error',
        internal = 'Internal error',
        warning = 'Warning'
    })[msgType_] or msgType_

    local msg_ = string.format("\n\n%s: %s\n", prefix, tostring(brief))
    msg_ = msg_ .. string.format("Details: %s\n", msg)

    if utils.isNonEmptyArray(self.locationStack) then
        msg_ = msg_ ..
               string.format("Location: %s\n",
                             pl.stringx.join(' --> ', self.locationStack))
    end

    if msgType_ == 'warning' then
        print(msg_)
    else
        M.locationStack = {}
        error(msg_)
    end
end

function M:clearLocations() self.locationStack = {} end

function M:pushLocation(location) table.insert(self.locationStack, location) end

function M:popLocation() return table.remove(self.locationStack) end

function M:error(brief, errMsg) raise(self, 'error', brief, errMsg) end

function M:internalError(brief, errMsg) raise(self, 'internal', brief, errMsg) end

function M:warning(brief, warningMsg) raise(self, 'warning', brief, warningMsg) end

-------------------------------------------------------------------------------
--- Errors
-------------------------------------------------------------------------------

M.actionNotFoundBrf = 'Action not found'
function M:actionNotFound(name)
    self:error(M.actionNotFoundBrf, 'Action "' .. name .. '" not found')
end

M.actionFileDoNotExistsBrf = 'Action file not found. '
function M:actionFileDoNotExists(name, stationActionDirectories)
    self:error(M.actionFileDoNotExistsBrf,
               'Action file "' .. name ..
               '" not found in the following action folders: ' ..
               dump(stationActionDirectories) ..
               '. Note that filename is case-sensitive.')
end

M.actionParameterParseFailedBrf = 'Action parameters parse failed'
function M:actionParameterParseFailed(name, errorMsg)
    self:error(M.actionParameterParseFailedBrf,
               'Parse action file failed: "' .. name .. '". ' .. errorMsg .. [[
We only support action files with clear argument definitions, and there should be only one main definition, such as:
```lua
function main(arg1, arg2)
```
or
```lua
main = function(arg1, arg2)
```
        ]])
end

M.actionFileParametersNoFoundBrf = 'Action file parameters not found'
function M:actionFileParametersNoFound(name)
    self:error(M.actionFileParametersNoFoundBrf,
               'Can\'t find parameters for action file: "' .. name .. '"')
end

M.actionRowTooLargeBrf = 'Action row too large'
function M:actionRowTooLarge()
    local msg = 'Too many key / values in action row. '
    msg = msg .. 'Each action row in test definition should '
    msg = msg .. 'contain a table with '
    msg = msg .. 'exactly one key (action name) / value (table) pair'
    self:error(M.actionRowTooLargeBrf, msg)
end

M.actionSortErrorBrf = 'Action sort error'
function M:actionSortError(errMsg)
    self:error(M.actionSortErrorBrf, errMsg or 'Unknown sort error')
end

M.actionIndexNotFoundBrf = 'Action index not found'
function M:actionIndexNotFound(actionSpec)
    self:error(M.actionIndexNotFoundBrf,
               'Missing index for action spec: ' .. actionSpec)
end

M.actionSpecWrongSizeBrf = 'Action spec wrong size'
function M:actionSpecWrongSize(encodedActionSpec)
    self:error(M.actionSpecWrongSizeBrf, 'Action spec ' .. encodedActionSpec ..
               ' must have exactly 4 elements')
end

M.invalidActionsTableBrf = 'Invalid Actions Table'
function M:invalidActionsTable()
    self:error(M.invalidActionsTableBrf,
               'actions should be list of 1-key-value dictionary for ' ..
               'sequential or graph type, or key-value dictionary for ' ..
               'graph type.')
end

M.ambiguousLimitMatchBrf = 'Ambiguous limit match'
function M:ambiguousLimitMatch(encodedTestSpec, matchingLimitSpecs)
    local msg = 'For test ' .. encodedTestSpec .. ' multiple limits match: ' ..
                pl.pretty.write(matchingLimitSpecs)
    self:error(M.ambiguousLimitMatchBrf, msg)
end

M.ambiguousTestDefMatchBrf = 'Ambiguous test definition match'
function M:ambiguousTestDefMatch(encodedTestSpec,
                                 matchingTestDefSpecs)
    local msg = 'For test ' .. encodedTestSpec ..
                ' multiple test definitions match: '
    msg = msg .. pl.pretty.write(matchingTestDefSpecs)
    self:error(M.ambiguousTestDefMatchBrf, msg)
end

M.noTestDefMatchBrf = 'No matching test definition'
function M:noTestDefMatch(testName)
    local msg = 'No test definition found for test ' .. testName
    self:error(M.noTestDefMatchBrf, msg)
end

M.badCoverageBrf = 'Bad coverage'
function M:badCoverage(errMsg)
    self:error(M.badCoverageBrf, errMsg or 'Coverage is nil')
end

M.badDataTypeBrf = 'Bad data type'
function M:badDataType(errMsg) self:error(M.badDataTypeBrf, errMsg) end

M.badBooleanColumnBrf = 'Bad Boolean Column'
function M:badBooleanColumn(column, value)
    self:error(M.badBooleanColumnBrf,
               'Column ' .. column ..
               ' is Boolean column and should be "", N, or Y, ' ..
               'while having value (' .. tostring(value) .. ')')
end

M.teardownTestSetStopOnFailBrf = 'Teardown Test set StopOnFail'
function M:teardownTestSetStopOnFail(row)
    self:error(M.teardownTestSetStopOnFailBrf,
               'Teardown test has non-empty ' ..
               'StopOnFail which is not supported: [' .. row.Technology .. ' ' ..
               row.Coverage .. ' ' .. row.TestParameters .. '] in Mode [' ..
               pl.stringx.join('_', row.mode or {}) .. ']')
end

M.badInitialActionBrf = 'Bad initial action'
function M:badInitialAction()
    self:error(M.badInitialActionBrf,
               'Initial action in "sequential" action list must have no deps')
end

M.badInputExprBrf = 'Bad input expression'
function M:badInputExpr(varName, errMsg)
    local msg = 'For input var: ' .. varName .. ', '
    msg = msg ..
          (errMsg or
          "Can't parse input expression or input expression resolves to nil")
    self:error(M.badInputExprBrf, msg)
end

M.badLuaExpressionBrf = 'Bad Lua expression'
function M:badLuaExpression(expression, errMsg)
    local msg = 'For Lua expression: ' .. tostring(expression) .. ', ' ..
                (errMsg or
                "invalid Lua expression or Lua expression resolves to nil")
    self:error(M.badLuaExpressionBrf, msg)
end

M.badLookupKeyFormatBrf = 'Bad \'lookup\' key format'
function M:badLookupKeyFormat()
    local msg = 'Bad format for \'lookup\' key. '
    msg = msg .. 'The expected format is '
    msg = msg .. '[varName] = { lookup = "actionName" } or '
    msg = msg .. '[varName] = { lookup = {"actionName", returnIdx} }.'
    self:error(M.badLookupKeyFormatBrf, msg)
end

M.badSpecFieldFormatBrf = 'Bad test spec field format'
function M:badSpecFieldFormat(fieldValue, format, fieldName)
    local value = 'Empty field'
    if fieldValue ~= "EMPTY" then
        value = fieldValue .. ', type=' .. type(fieldValue)
    end

    local msg = 'Field ' .. fieldName .. ' value (=' .. value ..
                ') must be present and be a string ' .. 'with format "' ..
                format .. '".'
    self:error(M.badSpecFieldFormatBrf, msg)
end

M.badParallelGroupSeparatorBrf = 'Bad parallel group separator'
function M:badParallelGroupSeparator()
    local msg = 'Parallel group separator should have Technology, Coverage ' ..
                'and TestParameters as [-PARALLEL-, -, -] or [-, -, -], ' ..
                'and all other fields should be empty.'
    self:error(M.badParallelGroupSeparatorBrf, msg)
end

M.badTeardownSeparatorBrf = 'Bad teardown separator'
function M:badTeardownSeparator()
    local msg = 'Teardown separator should have Technology, Coverage and ' ..
                'TestParameters as [-TEARDOWN-, -, -] or [=, =, =], and all' ..
                ' other fields should be empty.'
    self:error(M.badTeardownSeparatorBrf, msg)
end

M.badPhaseSeparatorBrf = 'Bad Phase separator'
function M:badPhaseSeparator()
    local msg = 'Phase separator should have Technology, Coverage and ' ..
                'TestParameters as [-PHASE-, -, -], and all other fields ' ..
                'should be empty.'
    self:error(M.badPhaseSeparatorBrf, msg)
end

M.unrecognizedSeparatorBrf = 'Unrecognized separator'
function M:unrecognizedSeparator(sep)
    local msg = 'found separator ' .. tostring(sep) ..
                ', expecting one of PARALLEL, TEARDOWN or PHASE'
    self:error(M.unrecognizedSeparatorBrf, msg)
end

M.badVarNameFormatBrf = 'Bad variable name format'
function M:badVarNameFormat(varName, format)
    self:error(M.badVarNameFormatBrf, 'Variable name "' .. varName ..
               '" must have format "' .. format .. '"')
end

M.coverageInMultipleFolderBrf =
'Multiple coverage folders have the same yaml file'
function M:coverageInMultipleFolder(coverage)
    self:error(M.coverageInMultipleFolderBrf,
               'Coverage: ' .. coverage .. 'is found in multiple folder')
end

M.cantReadCoverageBrf = "Can't read coverage file"
function M:cantReadCoverage(readErrMsg)
    self:error(M.cantReadCoverageBrf,
               readErrMsg or 'Unable to read coverage file')
end

M.circularDependencyBrf = "Circular dependency"
function M:circularDependency(encodedTestSpec)
    self:error(M.circularDependencyBrf, 'Test "' .. encodedTestSpec ..
               '" refers to itself as a dependency')
end

M.haveExtraSpaceBrf = "Extra space in " ..
                      "testParameters for wildcard test definition."
function M:haveExtraSpace(msg) self:error(M.haveExtraSpaceBrf, msg) end

M.conditionsKeyNilBrf = 'Conditions key nil'
function M:conditionsKeyNil(varName)
    local msg = 'For input variable "' .. varName ..
                '", key to conditions table is nil, '
    msg = msg .. 'did you forget to quote key?'
    self:error(M.conditionsKeyNilBrf, msg)
end

M.coverageNotTableBrf = 'Coverage not table'
function M:coverageNotTable()
    self:error(M.coverageNotTableBrf, 'Coverage is not a valid table')
end

M.undefinedConditionVariableBrf = 'Undefined Condition Variable.'
function M:undefinedConditionVariable(name, usedLocations)
    local msg = 'Condition variable ' .. name .. ' not found in ' ..
                'Condition table, but is used in [' ..
                pl.stringx.join(', ', usedLocations) .. ']'
    self:error(M.undefinedConditionVariableBrf, msg)
end

M.dependencyBadFormatBrf = 'Dependency bad format'
function M:dependencyBadFormat(rawDeps)
    local msg = 'Dependency field "' .. rawDeps .. '" not formatted correctly, '
    msg = msg .. 'must be comma-separated Lua-like lists of items'
    self:error(M.dependencyBadFormatBrf, msg)
end

M.dependentTestNotFoundBrf = 'Dependent test not found'
function M:dependentTestNotFound(encodedDep,
                                 activeModes,
                                 activeProducts,
                                 activeStationTypes,
                                 dagName)
    local msg = 'Dependent test "%s" with Modes: %s, Products: %s, '
    msg = msg ..
          'StationTypes: %s not found or not enabled in %s section of coverage table'
    msg = msg:format(encodedDep, helper.dump(activeModes),
                     helper.dump(activeProducts),
                     helper.dump(activeStationTypes), dagName)
    self:error(M.dependentTestNotFoundBrf, msg)
end

M.dependencyWrongSizeBrf = 'Dependency wrong size'
function M:dependencyWrongSize(depStr)
    local msg = 'Too many items in dependency "' .. depStr
    msg = msg .. '", only 1 each for Technology, Coverage and TestParameters'
    self:error(M.dependencyWrongSizeBrf, msg)
end

M.duplicateActionNameBrf = 'Duplicate action name'
function M:duplicateActionName(name)
    self:error(M.duplicateActionNameBrf,
               'Duplicate name "' .. name .. '" in ' .. 'actions')
end

M.emptyActionsBrf = 'Bad actions'
function M:emptyActions()
    self:error(M.emptyActionsBrf,
               'No valid action is recognized in test definition; ' ..
               'expecting an non-empty list for sequential type or ' ..
               'non-empty list or dictionary for graph type.')
end

M.duplicateTestModeBrf = 'Duplicate test mode'
function M:duplicateTestMode(entry)
    local technology = entry.Technology
    local coverage = entry.Coverage
    local testParameters = entry.TestParameters
    local subSubTest = entry.SubSubTest

    local errMsg = "Main table contains duplicate test modes for "
    errMsg = errMsg .. "Technology: " .. technology
    errMsg = errMsg .. ", Coverage: " .. coverage

    if (utils.isNonEmptyString(testParameters)) then
        errMsg = errMsg .. ", TestParameters: " .. testParameters
    end

    if (utils.isNonEmptyString(subSubTest)) then
        errMsg = errMsg .. ", SubSubTest: " .. subSubTest
    end

    errMsg = errMsg .. ". Please view Schooner documentation on "
    errMsg = errMsg .. "test mode conflicts to resolve this issue."

    self:error(M.duplicateTestModeBrf, errMsg)
end

M.duplicateTestSpecBrf = 'Duplicate test definition'
function M:duplicateTestSpec(encodedTestSpec)
    self:error(M.duplicateTestSpecBrf,
               'Duplicate test definition ' .. encodedTestSpec)
end

M.duplicateLimitBrf = 'Duplicate limit entry'
function M:duplicateLimit(encodedLimitSpec, firstSeenIdx)
    local msg = 'Duplicate limit entry ' .. encodedLimitSpec
    msg = msg .. ' found in row ' .. firstSeenIdx .. ' of the limit table.'
    self:error(M.duplicateLimitBrf, msg)
end

M.testDefNilFindoutBrf = 'find.output expression contains an empty string'
function M:testDefNilFindout(msg) self:error(M.testDefNilFindoutBrf, msg) end

function M:duplicateTestSpecWithFirstInstance(sourcePath, idx)
    local msg = 'Duplicate test specifier. First instance @ "' .. sourcePath ..
                '" @ Test definition index ' .. idx
    self:error(M.duplicateTestSpecBrf, msg)
end

M.duplicateVariableBrf = 'Duplicate variable'
function M:duplicateVariable(varName, errMsg)
    self:error(M.duplicateVariableBrf,
               'Duplicate variable "' .. varName .. '". ' .. errMsg)
end

M.emptyRowBrf = 'Empty row'
function M:emptyRow() self:error(M.emptyRowBrf, 'Row is empty') end

M.invalidActionSpecBrf = 'Invalid action spec'
function M:invalidActionSpec()
    self:error(M.invalidActionSpecBrf, 'actionSpec must be a nonempty array')
end

M.invalidTestSpecBrf = 'Invalid test spec'
function M:invalidTestSpec()
    self:error(M.invalidTestSpecBrf, 'testSpec must be a nonempty array')
end

M.invalidVarSpecBrf = 'Invalid var spec'
function M:invalidVarSpec()
    self:error(M.invalidVarSpecBrf, 'varSpec must be a nonempty array')
end

M.actionParameterNotFoundBrf = 'Action parameter is not found'
function M:actionParameterNotFound(parameterName, actionFileName)
    self:error(M.actionParameterNotFoundBrf,
               'Parameter "' .. parameterName ..
               '" is not found in main function of "' .. actionFileName ..
               '" action file.')
end

M.limitErrBadLimitRangeBrf = 'Bad limit range'
function M:limitErrBadLimitRange(lowerLimit,
                                 lowerName,
                                 upperLimit,
                                 upperName)
    self:error(M.limitErrBadLimitRangeBrf,
               'Lower limit "' .. lowerName .. '" (=' .. tostring(lowerLimit) ..
               ') must be <= upper limit "' .. upperName .. '" (=' ..
               tostring(upperLimit) .. ')')
end

M.limitErrBadLimitValueBrf = 'Bad limit value'
function M:limitErrBadLimitValue(limit, name)
    self:error(M.limitErrBadLimitValueBrf,
               'Limit "' .. name ..
               '" must be nil or a string representing a number, not ' ..
               tostring(limit))
end

M.limitChangedAfterToNumberBrf = 'Limit changed after converted into number'
function M:limitChangedAfterToNumber(name, limit, convertedLimit)
    self:error(M.limitChangedAfterToNumberBrf,
               'Limit "' .. name ..
               '" changed after converted into number. Original: ' .. limit ..
               ', tonumber(): ' .. convertedLimit)
end

M.limitErrBadRequiredBrf = 'Bad "Required" field in Limits table.'
function M:limitErrBadRequired(required)
    local msg = '"Required" column must be "Y/y", "N/n", '
    msg = msg .. 'or a valid condition expression, not '
    msg = msg .. tostring(required) .. '.'
    self:error(M.limitErrBadRequiredBrf, msg)
end

M.limitMissingConditionBrf = 'Missing condition for duplicate limit'
function M:limitMissingCondition(duplicateLimitSpec,
                                 firstSeenIdx)
    local msg = 'Limit: ' .. duplicateLimitSpec
    msg = msg .. ' is duplicated in the limit table (first seen on line '
    msg = msg .. tostring(firstSeenIdx) .. '), but one of the duplicates'
    msg = msg .. ' does not have a condition.'
    self:error(M.limitMissingConditionBrf, msg)
end

M.stationVersionLengthErrorWithoutConditionalLimitBrf =
'Total length of stationVersion and limitVersionPrefix exceeds ' ..
common.MAX_LENGTH_OF_STATION_VERSION_WITH_DIVIDER .. ' characters limit. '
function M:stationVersionLengthErrorWithoutConditionalLimit()
    local msg =
    "Please check plist and rename the stationVersion or change the limitVersionPrefix."
    self:error(M.stationVersionLengthErrorWithoutConditionalLimitBrf, msg)
end

M.stationVersionLengthErrorWithoutConditionalLimitAndLimitVersionPrefixBrf =
'Length of stationVersion exceeds ' .. common.MAX_LENGTH_OF_STATION_VERSION ..
' characters without limitVersionPrefix and conditionalLimit.'
function M:stationVersionLengthErrorWithoutConditionalLimitAndLimitVersionPrefix()
    local msg = 'Please check plist and rename the stationVersion.'
    self:error(
    M.stationVersionLengthErrorWithoutConditionalLimitAndLimitVersionPrefixBrf,
    msg)
end

M.limitVersionExceedBrf = 'Length of possible software version exceeds ' ..
                          tostring(common.MAX_LENGTH_OF_STATION_VERSION) ..
                          ' characters'
function M:limitVersionExceedLength(sv, length)
    local msg = 'There is one possible software version (' .. sv .. ') has ' ..
                tostring(length) .. ' characters.'
    self:error(M.limitVersionExceedBrf, msg)
end

M.duplicateConditionInLimitBrf = 'Duplicate condition for duplicate limit'
function M:duplicateConditionInLimit(duplicateLimitSpec,
                                     firstSeenIdx)
    local rowNum = M:popLocation()
    local msg = 'Limit: ' .. duplicateLimitSpec
    msg = msg .. ' is duplicated in the limit table (first seen on line '
    msg = msg .. tostring(firstSeenIdx) .. '). '
    msg = msg .. rowNum .. ' has a duplicate condition.'
    self:error(M.duplicateConditionInLimitBrf, msg)
end

M.nonOverlappingConditionVariablesBrf =
'Limits contain non-overlapping condition variables'
function M:nonOverlappingConditionVariables(duplicateLimitSpec,
                                            firstSeenIdx)
    local rowNum = M:popLocation()
    local msg = 'Limit: ' .. duplicateLimitSpec
    msg = msg .. ' is duplicated in the limit table (first seen on line '
    msg = msg .. tostring(firstSeenIdx) .. '). '
    msg = msg .. rowNum .. ' has a condition which'
    msg = msg .. ' does not use condition variables shared by '
    msg = msg .. 'the previously seen limit.'
    self:error(M.nonOverlappingConditionVariablesBrf, msg)
end

M.ambiguousLimitTypeBrf = 'Limit type is ambiguous'
function M:ambiguousLimitType()
    local msg = 'A limit entry cannot simultaneously have '
    msg = msg .. 'nonempty "AllowedList" and parametric limit columns.'
    self:error(M.ambiguousLimitTypeBrf, msg)
end

M.duplicateLimitWithDifferentTypeBrf = 'Duplicate limit with different types'
function M:duplicateLimitWithDifferentType(entryKey)
    local msg = 'Limit entry with ' .. entryKey
    msg = msg .. ' is duplicated with different types.'
    msg = msg .. ' Duplicate entries cannot mix between Set/non-Set types.'
    self:error(M.duplicateLimitWithDifferentTypeBrf, msg)
end

M.unsupportedConditionTypeInLimitTableBrf =
'Condition type currently not supported in limit table.'
function M:unsupportedConditionTypeInLimitTable(conditionVariableName,
                                                location)
    local msg = 'A  test condition (=' .. conditionVariableName ..
                ') was found in ' .. location ..
                ". Schooner currently does not support test conditions in the limit table."
    self:error(M.unsupportedConditionTypeInLimitTableBrf, msg)
end

M.wrongTypeConditionInitializeBrf =
"Group/Init condition initialized in test definition. "
function M:wrongTypeConditionInitialize(conditionVariableName)
    local msg = 'Test definition initialize a condition: ' ..
                conditionVariableName ..
                ', but it is not declared in condition table as Test condition'
    self:error(M.wrongTypeConditionInitializeBrf, msg)
end

M.limitErrValueNotInTreeBrf = 'Value not in tree'
function M:limitErrValueNotInTree(value)
    self:error(M.limitErrValueNotInTreeBrf,
               'Value (=' .. tostring(value) .. ') not found in tree')
end

-- limit DisableOrphanedRecordChecking errors.
-- DORC: DisableOrphanedRecordChecking.
M.DORCInWrongPlaceBrf = '"' .. common.DisableOrphanedRecordChecking ..
                        '" found in Limit table but in the wrong place'
function M:DORCInWrongPlace(column, row)
    self:error(M.DORCInWrongPlaceBrf,
               'Row: ' .. tostring(row) .. ' Column: ' .. tostring(column) ..
               '; it is only allowed in ' ..
               'Technology column of the first row.')
end

M.DORCWithNonEmptyColumnBrf = '"' .. common.DisableOrphanedRecordChecking ..
                              '" found in the first row of Limit table but ' ..
                              'with other non-empty column'
function M:DORCWithNonEmptyColumn(column)
    self:error(M.DORCWithNonEmptyColumnBrf, ': ' .. tostring(column) ..
               '; only Notes and Technology can have value.')
end
-- end of limit DisableOrphanedRecordChecking errors.

-- CSV file errors
M.CSVFileNotFoundBrf = 'File not found'
function M:CSVFileNotFound(path)
    self:error(M.CSVFileNotFoundBrf,
               'Could not open CSV file at given path: ' .. tostring(path))
end

M.CSVHeaderWrongColumnNumberBrf = 'Wrong CSV Header column number'
function M:CSVHeaderWrongColumnNumber(file, actual, expected)
    self:error(M.CSVHeaderWrongColumnNumberBrf,
               file .. ': Header row column number mismatch: expecting ' ..
               expected .. ' columns, actually get ' .. actual .. ' columns')
end

M.CSVColumnMismatchBrf = 'CSV column mismatch'
function M:CSVColumnMismatch(name, i, expect, actual)
    self:error(M.CSVColumnMismatchBrf,
               name .. ' column ' .. i .. ' mismatch; expecting ' .. expect ..
               ' , actual ' .. actual)
end

M.CSVHeaderParseErrBrf = "Unable to parse CSV header row"
function M:CSVHeaderParseError(CSVType, CSVPath)
    self:error(M.CSVHeaderParseErrBrf,
               'Unable to parse header row of "' .. CSVType .. '" CSV file at "' ..
               CSVPath .. '"')
end

M.CSVFileParseErrBrf = "Unable to parse CSV file"
function M:CSVFileParseError(CSVType, CSVPath)
    self:error(M.CSVFileParseErrBrf,
               'Unable to parse content of "' .. CSVType .. '" CSV file at "' ..
               CSVPath .. '"')
end

-- This error is raised by Atlas, so it may change if Atlas changes.
M.conditionInvalidCharBrf = "[tokenize error] Unsupported char"
function M:conditionInvalidChar(c)
    self:error(M.conditionInvalidCharBrf,
               'Unsupported char type: ' .. tostring(c))
end
-- condition errors

M.conditionInvalidVariableBrf = "'Conditions'/'Required' column contains " ..
                                "a restricted variable name that is not " ..
                                "supported by Schooner. "
function M:conditionInvalidVariable(Var)
    self:error(M.conditionInvalidVariableBrf,
               'Restricted condition variable name: ' .. Var ..
               '. Please use Mode/Product/StationType column instead')
end

M.duplicatedConditionNameBrf = 'Duplicated condition definition'
function M:duplicatedConditionName(name)
    self:error(M.duplicatedConditionNameBrf, 'Multiple conditions with name ' ..
               name .. ' are defined in condition table.')
end

M.duplicateTestConditionInitializationBrf = 'Duplicated ' ..
                                            'test condition initiliazation'
function M:duplicatedTestConditionInitialization(name)
    self:error(M.duplicateTestConditionInitializationBrf,
               'Test condition ' .. name .. ' was initialized multiple times' ..
               ' inside your test definition files.  Please ensure that each test condition variable is' ..
               ' only initialized a single time.')
end

M.invalidReservedConditionNameBrf = 'Invalid Reserved Condition Name column'
function M:invalidReservedConditionName(name, expectedName)
    self:error(M.invalidReservedConditionNameBrf,
               'Condition name: "' .. name .. '" is not allowed, should use "' ..
               expectedName .. '"')
end

M.invalidConditionWhenBrf = 'Invalid Condition When column'
function M:invalidConditionWhen(name, when, allowedString)
    self:error(M.invalidConditionWhenBrf,
               'Condition name ' .. name .. ' has invalid When "' .. when ..
               '", expecting one in ' .. allowedString)
end

M.invalidConditionGeneratorFormatBrf = 'Invalid Condition generator format'
function M:invalidConditionGeneratorFormat(name, generator, format)
    self:error(M.invalidConditionGeneratorFormatBrf,
               'Condition "' .. name .. '" generator "' .. tostring(generator) ..
               '" is not of format ' .. format)
end

M.testConditionHasGeneratorBrf = 'Test condition unexpectedly has generator'
function M:testConditionHasGenerator(name, generator)
    self:error(M.testConditionHasGeneratorBrf,
               'Test Condition "' .. name ..
               '" has unexpected non-empty generator "' .. tostring(generator) ..
               '"')
end

M.usingTestConditionNotInitializedBrf =
'Test condition used without initialization under certain condition'
function M:usingTestConditionNotInitialized(conditionName,
                                            UsingConditionLocation,
                                            generateConditionLocation)
    self:error(M.usingTestConditionNotInitializedBrf,
               "Test Condition: " .. conditionName .. " Is initialized in " ..
               generateConditionLocation .. " and used in " ..
               UsingConditionLocation ..
               ", it has chance to be used without initialization")
end

M.NoClConditionHasGeneratorBrf = 'NoCl condition unexpectedly has generator'
function M:NoClConditionHasGenerator(name, generator)
    self:error(M.NoClConditionHasGeneratorBrf,
               'NoCl Condition "' .. name .. '" has unexpected generator "' ..
               tostring(generator) .. '", it should be empty.')
end

M.ModeHasGeneratorBrf = 'Mode unexpectedly has generator'
function M:ModeHasGenerator(generator)
    self:error(M.ModeHasGeneratorBrf,
               'Mode condition has unexpected generator "' ..
               tostring(generator) .. '", it should be empty.')
end

M.NoClConditionHasValidatorBrf = 'NoCl condition unexpectedly has validator'
function M:NoClConditionHasValidator(name, validator)
    self:error(M.NoClConditionHasValidatorBrf,
               'NoCl Condition "' .. name .. '" has unexpected validator "' ..
               tostring(validator) .. '", it should be empty.')
end

M.enableSamplingConditionHasValidatorBrf =
'EnableSampling condition unexpectedly has validator'
function M:enableSamplingConditionHasValidator(name, validator)
    self:error(M.enableSamplingConditionHasValidatorBrf,
               'EnableSampling Condition "' .. name ..
               '" has unexpected validator "' .. tostring(validator) ..
               '", it should be empty.')
end

M.testConditionNotGenerateBrf = 'Test condition do not have generate test'
function M:testConditionNotGenerate(name)
    self:error(M.testConditionNotGenerateBrf,
               'Test Condition:' .. name .. ' is not generated by any test')
end

M.conditionMissingGeneratorBrf = 'Missing generator for Group or Init condition'
function M:conditionMissingGenerator(name)
    self:error(M.conditionMissingGeneratorBrf, 'Condition ' .. name ..
               ' is of Type Group or Init but does not have generator defined.')
end

M.conditionMissingValidatorBrf = 'Condition missing validator'
function M:conditionMissingValidator(name)
    self:error(M.conditionMissingValidatorBrf,
               'Condition ' .. tostring(name) .. ' has empty validator.')
end

M.invalidConditionValidatorFormatBrf = 'Invalid Condition validator format'
function M:invalidConditionValidatorFormat(name, validator)
    self:error(M.invalidConditionValidatorFormatBrf,
               'Condition "' .. name .. '" validator "' .. tostring(validator) ..
               '" is not of format module:function, IN(array) or RANGE(min, max).')
end

M.unexpectedFilterBrf = 'Unexpected filter value'
function M:unexpectedFilter(filterType, value, expected)
    local msg = 'Unexpected %s value: %s, expecting one from %s'
    msg = msg:format(filterType, value, dump(expected))
    self:error(M.unexpectedFilterBrf, msg)
end

M.invalidFilterValidatorBrf = 'Invalid filter validator'
function M:invalidFilterValidator(name, validator)
    local msg = 'Filter "%s" must use an IN() validator, but got %s'
    msg = msg:format(name, validator)
    self:error(M.invalidFilterValidatorBrf, msg)
end

M.conditionValidatorEmptyINBrf = 'IN validator with no allowed value'
function M:conditionValidatorEmptyIN(name)
    self:error(M.conditionValidatorEmptyINBrf,
               'Condition "' .. name .. '" defines no allowed value in IN()')
end

M.conditionValidatorInvalidMinInRANGEBrf = 'Condition has ' ..
                                           'no min in RANGE validator'
function M:conditionValidatorInvalidMinInRANGE(name, validator, min)
    self:error(M.conditionValidatorInvalidMinInRANGEBrf,
               'Condition "' .. name .. '" validator "' .. tostring(validator) ..
               '" is of format RANGE() but min(' .. min ..
               ') is not a number; expecting RANGE(min, max) with numeric min and max')
end

M.conditionValidatorInvalidMaxInRANGEBrf = 'Condition has ' ..
                                           'no max in RANGE validator'
function M:conditionValidatorInvalidMaxInRANGE(name, validator, max)
    self:error(M.conditionValidatorInvalidMaxInRANGEBrf,
               'Condition "' .. name .. '" validator "' .. tostring(validator) ..
               '" is of format RANGE() but max(' .. tostring(max) ..
               ')is not a number; expecting RANGE(min, max) with numeric min and max')
end

-- end of condition errors

-- sampling errors
M.samplingRateOutOfRangeBrf = 'Sampling rate is out of range. '
function M:samplingRateOutOfRange(rate)
    self:error(M.samplingRateOutOfRangeBrf,
               'Sampling rate: ' .. rate .. ' is out range; expecting 1-99.')
end

M.duplicatedSamplingGroupNameBrf = 'Duplicated sampling group definition. '
function M:duplicatedSamplingGroupName(name)
    self:error(M.duplicatedSamplingGroupNameBrf,
               'Multiple sampling with group name ' .. name ..
               ' are defined in sampling table.')
end

M.mainTestUseUndefinedSampleGroupBrf = 'Main Test Use Undefined Sample Group'
function M:mainTestUseUndefinedSampleGroup(testFullName,
                                           sampleGroupName)
    self:error(M.mainTestUseUndefinedSampleGroupBrf,
               'Test: ' .. tostring(testFullName) .. ', sample group name: ' ..
               tostring(sampleGroupName))
end

M.sampleGroupNotConsumedBrf = 'Sample Group Not Consumed'
function M:sampleGroupNotConsumed(sampleGroupName)
    self:error(M.sampleGroupNotConsumedBrf,
               'Sample group ' .. tostring(sampleGroupName) ..
               ' is defined in sample table but not used by any test.')
end

M.invalidSamplingConditionTypeBrf = 'Invalid Sampling condition type'
function M:invalidSamplingConditionType()
    self:error(M.invalidSamplingConditionTypeBrf, 'Condition EnableSampling' ..
               ' cannot be declared as group condition.')
end

M.invalidFilterWhenBrf = 'Invalid When for filter condition'
function M:invalidFilterWhen(filter, when)
    local msg = 'Filter "%s" cannot be declared as %s condition.'
    msg = msg:format(filter, when)
    self:error(M.invalidFilterWhenBrf, msg)
end

M.conditionHasNonEmptyWhenBrf = 'Condition has non-empty When'
function M:conditionHasNonEmptyWhen(name, when)
    self:error(M.conditionHasNonEmptyWhenBrf, 'Condition ' .. name ..
               ' should have empty "When" column, while got ' .. when)
end

M.missingModeBrf = 'Missing Mode filter'
function M:missingMode()
    local msg = 'Condition table must define the Mode filter. '
    msg = msg .. 'See Schooner documentation for details.'
    self:error(M.missingModeBrf, msg)
end

M.teardownTestHasSampleGroupBrf = 'Teardown test has sample group'
function M:teardownTestHasSampleGroup(testFullName)
    self:error(M.teardownTestHasSampleGroupBrf,
               'Teardown test: ' .. tostring(testFullName))
end

-- end of sampling errors

M.limitErrUnsupportedUnitBrf = 'Unsupported unit type'
function M:limitErrUnsupportedUnit(unit)
    self:error(M.limitErrUnsupportedUnitBrf,
               'Unit : ' .. unit .. ' is not supported')
end

M.mainSeqSortErrorBrf = 'Main sequence sort error'
function M:mainSeqSortError(errMsg)
    self:error(M.mainSeqSortErrorBrf, errMsg or 'Unknown sort error')
end

M.missStationPlistOrDirectoryBrf = 'Missing plist or plist directory.'
function M:missStationPlistOrDirectory()
    local msg = 'Please input at least one station plist or directory' ..
                ' if conditional limits are used or a limitVersionPrefix is provided.'
    self:error(M.missStationPlistOrDirectoryBrf, msg)
end

M.missStationVersionKeyBrf = 'Missing StationVersion in plist.'
function M:missStationVersionKey(plistPath)
    self:error(M.missStationVersionKeyBrf, 'Please check plist file: ' ..
               plistPath .. ' and add StationVersion')
end

M.emptyStationVersionBrf = 'Empty StationVersion in plist.'
function M:emptyStationVersion(plistPath)
    self:error(M.emptyStationVersionBrf, 'Please check plist file: ' ..
               plistPath .. ' and modify StationVersion')
end

M.missGroupArgsKeyBrf = 'Missing GroupArgs in plist.'
function M:missGroupArgsKeyKey(plistPath)
    self:error(M.missGroupArgsKeyBrf,
               'Please check plist file: ' .. plistPath .. ' and add GroupArgs')
end

M.emptyStationModeBrf = 'Empty StationMode in plist.'
function M:emptyStationMode(plistPath)
    self:error(M.emptyStationModeBrf,
               'Please check plist file: ' .. plistPath ..
               ' and modify GroupArgs')
end

M.invalidStationModeBrf = 'Invalid StationMode in plist.'
function M:invalidStationMode(plistPath, modes, modeInPlist)
    self:error(M.invalidStationModeBrf,
               'Invalid Mode: The mode `' .. modeInPlist ..
               '` specified in the plist file is not valid for the current ' ..
               'overlay. The currently supported modes are: ' ..
               helper.dump(modes) .. '. ' ..
               'Please modify the StationMode in the plist file located at ' ..
               plistPath .. ' and try again.')
end

M.caseMismatchStationModeBrf = 'Mode case mismatch'
function M:caseMismatchStationMode(plistPath, mode, modeInPlist)
    self:error(M.caseMismatchStationModeBrf, modeInPlist .. " from " ..
               plistPath .. " doesn't match with " .. mode)
end

M.missingInputsBrf = 'Missing inputs key inside test definition block'
function M:missingInputs(msg)
    self:error(M.missingInputsBrf, msg .. '. Did you mispell the inputs key?')
end

M.missingVarNameBrf = 'Missing var name'
function M:missingVarName(varName)
    self:error(M.missingVarNameBrf, 'Var name "' .. varName ..
               '" not found in inputs for test definition')
end

M.specializedDepNotFoundBrf = 'Specialized dependency not found'
function M:specializedDepNotFound(encodedSpecializedSpec,
                                  encodedOriginalSpec)
    local msg = 'Specialized dependency ' .. encodedSpecializedSpec ..
                ' (original: '
    msg = msg .. encodedOriginalSpec .. ') not found or coverage not enabled'
    self:error(M.specializedDepNotFoundBrf, msg)
end

M.teardownSepAlreadySeenBrf = 'More than one teardown separator found'
function M:teardownSepAlreadySeen(firstTeardownIdx)
    local msg = 'Already in teardown sequence, '
    msg = msg .. 'first teardown separator at row ' .. firstTeardownIdx
    self:error(M.teardownSepAlreadySeenBrf, msg)
end

M.testDefNotTableBrf = 'Test definition not table'
function M:testDefNotTable()
    self:error(M.testDefNotTableBrf, 'Test definition is not a valid table')
end

M.wrongBackgroundUseBrf = 'Wrong background use'
function M:wrongBackgroundUse(name, dep)
    self:error(M.wrongBackgroundUseBrf, 'Action name: ' .. name ..
               " is not a background action, but it depends on the background action: " ..
               dep .. ' . Please visit Schooner docs for proper usage.')
end

M.testDefValueWrongTypeBrf =
'Test definition file contains a value of the wrong type.'
function M:testDefValueWrongType(key, value, expectedType)
    local testID = M:popLocation()
    local msg
    if key ~= nil then
        msg = 'Found in: ' .. testID
        msg = msg .. '. The value for test definition key=' .. key
    else
        msg = testID
    end
    msg = msg .. ' is of the wrong type.'
    msg = msg .. ' Expected type: ' .. dump(expectedType)
    msg = msg .. ', actual type: ' .. type(value) .. '.'
    msg = msg .. ' Please visit Schooner docs for expected usage.'
    self:error(M.testDefValueWrongTypeBrf, msg)
end

M.testDefMissingRequiredKeyBrf = 'Test definition file missing required key.'
function M:testDefMissingRequiredKey(key, missingKeys)
    local testID = M:popLocation()
    local msg
    if key ~= nil then
        msg = 'Found in: ' .. testID
        msg = msg .. '. The value for test definition key=' .. key
    else
        msg = testID
    end
    msg = msg .. ' is missing the following required keys: '
    msg = msg .. dump(missingKeys) .. '.'
    msg = msg .. ' Please visit Schooner docs for expected usage.'
    self:error(M.testDefMissingRequiredKeyBrf, msg)
end

M.testDefKeyNotFoundBrf = 'Test definition key not found.'
function M:testDefKeyNotFound(extraKeys, expectedKeys)
    local testID = M:popLocation()
    local msg = 'Test definition keys=' .. dump(extraKeys)
    msg = msg .. ' doesn\'t match allowed keys. '
    msg = msg .. 'Key must be strictly from ' .. dump(expectedKeys) .. '. '
    msg = msg .. 'Did you misspell a key?'
    msg = msg .. ' Found in ' .. testID
    self:error(M.testDefKeyNotFoundBrf, msg)
end

M.testSpecWrongSizeBrf = 'Test spec wrong size'
function M:testSpecWrongSize(encodedTestSpec)
    self:error(M.testSpecWrongSizeBrf,
               'Test spec ' .. encodedTestSpec .. ' must have exactly ' ..
               common.NUM_TEST_SPEC .. ' elements')
end

M.unknownInputTypeBrf = 'Unknown input type'
function M:unknownInputType(inputsToProcess)
    local msg = "The following inputs weren't processed: " ..
                pl.pretty.write(pl.Set.values(inputsToProcess)) ..
                ", inputs must be one of find.output(), find.outputs()" ..
                "condition, " .. "or an expression using a test spec field"
    self:error(msg)
end

M.unknownSequenceTypeBrf = 'Unknown sequence type'
function M:unknownSequenceType(seqType)
    self:error(M.unknownSequenceTypeBrf,
               'Unknown sequence type "' .. tostring(seqType) .. '"')
end

M.unusedTestSpecsBrf = 'Unused test specs'
function M:unusedTestSpecs(encodedSpecsUsedByMain)
    local unusedSpecs = pl.stringx.join(', ',
                                        pl.Set.values(encodedSpecsUsedByMain))
    local msg = "The following test specs are used in main sequence "
    msg = msg .. "but don't have a matching test definition: "
    self:error(M.unusedTestSpecsBrf, msg .. unusedSpecs)
end

M.varSpecWrongSizeBrf = 'Var spec wrong size'
function M:varSpecWrongSize(encodedVarSpec)
    self:error(M.varSpecWrongSizeBrf,
               'Var spec ' .. encodedVarSpec .. ' must have exactly 4 elements')
end

M.wrongParamsFindOutputBrf = 'Wrong find.output() param count'
function M:wrongParamsFindOutput(numParams)
    local msg = 'Wrong number of parameters to find.output(): ' .. numParams
    msg = msg .. ', must be technology, coverage, testParameters, varName'
    self:error(M.wrongParamsFindOutputBrf, msg)
end

M.invalidLuaCodeFindOutput3rdArgBrf = 'Invalid Lua code in find.output 3rd arg'
function M:invalidLuaCodeFindOutput3rdArg(arg, msg)
    self:error(M.invalidLuaCodeFindOutput3rdArgBrf, 'Failed to run 3rd arg(' ..
               tostring(arg) .. ') as Lua code; msg=' .. msg)
end

M.badFieldToStripAndUnquoteBrf = 'Bad field to strip and unquote'
function M:badFieldToStripAndUnquote(field)
    self:error(M.badFieldToStripAndUnquoteBrf,
               'field = ' .. tostring(field) .. '; expecting quoted string.')
end

M.isolatedEscapeCharacterBrf = 'Isolated escape character found'
function M:isolatedEscapeCharacter(escapeChar)
    local msg = string.format("An isolated escape character: '%s' was found.",
                              escapeChar)
    self:error(M.isolatedEscapeCharacterBrf, msg)
end

M.isolatedReturnBrf = 'Isolated return found'
function M:isolatedReturn(subContent)
    local message = "An isolated return (\\r) was found near: %s."
    message = message .. " Please use \\r\\n (CRLF) to indicate new lines."
    local msg = string.format(message, subContent)
    self:error(M.isolatedReturnBrf, msg)
end

M.noMatchingTestFoundBrf = 'No matching tests found for find.output(s)'
function M:noMatchingTestFound(testNames)
    local tech = testNames.technology
    local cov = testNames.coverage
    local testParameterPattern = testNames.testParameters
    self:error(M.noMatchingTestFoundBrf,
               'Technology = ' .. tostring(tech) .. ', Coverage = ' ..
               tostring(cov) .. ', TestParameters Pattern = ' ..
               tostring(testParameterPattern))
end

M.findOutputs3rdArgNotPatternBrf =
'find.outputs 3rd arg does not represent multiple tests'
function M:findOutputs3rdArgNotPattern(testNames)
    local tech = testNames.technology
    local cov = testNames.coverage
    local testParameterPattern = testNames.testParameters
    self:error(M.findOutputs3rdArgNotPatternBrf,
               'Technology = ' .. tostring(tech) .. ', Coverage = ' ..
               tostring(cov) .. ', TestParameters Pattern = ' ..
               tostring(testParameterPattern) .. '. Please use find.output() ' ..
               'to get output data from 1 test.')
end

M.findOutput3rdArgHasPatternBrf = 'find.output 3rd arg represent multiple tests'
function M:findOutput3rdArgHasPattern(testNames)
    local tech = testNames.technology
    local cov = testNames.coverage
    local testParameterPattern = testNames.testParameters
    self:error(M.findOutput3rdArgHasPatternBrf,
               'Technology = ' .. tostring(tech) .. ', Coverage = ' ..
               tostring(cov) .. ', TestParameters Pattern = ' ..
               tostring(testParameterPattern) .. '. Please use find.outputs() ' ..
               'to get output data from multiple test.')
end

M.findOutputPointToTestWithoutOutputsBrf =
'find.output(s) points to test without outputs'
-- from: test with inputs
-- to: test that should output but does not
function M:findOutputPointToTestWithoutOutputs(from, to)
    local nameFrom = pl.stringx.join(' ', {
        from.technology,
        from.coverage,
        from.testParameters
    })
    local nameTo = pl.stringx.join(' ', {
        to.technology,
        to.coverage,
        to.testParameters
    })
    self:error(M.findOutputPointToTestWithoutOutputsBrf,
               'find.output(s) [' .. nameFrom .. '] use output from test [' ..
               nameTo .. '] which has no outputs.')

end

M.findOutputPointToTestNotOutputingVariableBrf =
'find.output(s) points to test without specific output variable'
-- from: test with inputs
-- to: test that should have output var but does not
function M:findOutputPointToTestNotOutputingVariable(from, to, varName)
    local nameFrom = pl.stringx.join(' ', {
        from.technology,
        from.coverage,
        from.testParameters
    })
    local nameTo = pl.stringx.join(' ', {
        to.technology,
        to.coverage,
        to.testParameters
    })
    self:error(M.findOutputPointToTestNotOutputingVariableBrf,
               'find.output(s) [' .. nameFrom .. '] use output variable [' ..
               tostring(varName) .. '] from test [' .. nameTo ..
               '] which does not define it.')
end

M.findOutputUseNonExistingTestInMainBrf =
'find.output(s) in teardown test ' .. 'use non-existing main test'
function M:findOutputUseNonExistingTestInMain(action)
    self:error(M.findOutputUseNonExistingTestInMainBrf,
               'Cannot find ' .. tostring(action) .. 'in Main tests')
end

M.findOutputUseNonExistingOutputInMainBrf =
'find.output(s) in teardown test ' .. 'use non-existing main test output'
function M:findOutputUseNonExistingOutputInMain(item, output)
    self:error(M.findOutputUseNonExistingOutputInMainBrf, 'Cannot find ' ..
               tostring(output) .. 'in ' .. tostring(item) .. ' outputs')
end

M.usingFindMainOutputBrf =
'find.mainOutput is deprecated; please use find.output'
function M:usingFindMainOutput() self:error(M.usingFindMainOutputBrf) end

M.pipelineDoesntSupportPolicyBrf =
'pipeline stations using phases cannot support actions with policies'
function M:pipelineDoesntSupportPolicy()
    self:error(M.pipelineDoesntSupportPolicyBrf)
end

M.pipelineDoesNotSupportInitConditionBrf =
'Pipeline stations using phases cannot support Init conditions'
function M:pipelineDoesNotSupportInitCondition()
    self:error(M.pipelineDoesNotSupportInitConditionBrf)
end

M.pipelineDoesNotSupportTeardownTestBrf =
'Pipeline stations using phases cannot support teardown test'
function M:pipelineDoesNotSupportTeardownTest()
    self:error(M.pipelineDoesNotSupportTeardownTestBrf)
end

-------------------------------------------------------------------------------
--- Internal errors
-------------------------------------------------------------------------------

M.intMissingRowBrf = 'Missing row'
function M:internalMissingRow(testIdx, tableName)
    self:internalError(M.missingRowBrf,
                       'row ' .. testIdx .. ' not found in ' .. tableName)
end

M.internalUnsupportedKeyBrf = 'Unsupported Key'
function M:internalUnsupportedKey(key)
    self:internalError(M.internalUnsupportedKeyBrf, key)
end

M.intBadDataTypeBrf = 'Bad data type'
function M:intBadDataType(errMsg) self:internalError(M.intBadDataTypeBrf, errMsg) end

-------------------------------------------------------------------------------
--- Loop related errors
-------------------------------------------------------------------------------
M.notSupportedNumberInLoopBrf = 'Not supported number in loop'
function M:notSupportedNumberInLoop(n, name)
    self:error(M.notSupportedNumberInLoopBrf, name .. ' = ' .. n ..
               '. Expecting integer or floating point number.')
end

M.notSupportedNumberAsLoopCountBrf = 'Not supported number as loop count'
function M:notSupportedNumberAsLoopCount(n)
    self:error(M.notSupportedNumberAsLoopCountBrf,
               'count = [' .. n .. ']. Expecting unsigned integer.')
end

M.exceedMaxSupportedDecimalsBrf = 'Exceeds max supported decimals places'
function M:exceedMaxSupportedDecimals(n, max)
    self:error(M.exceedMaxSupportedDecimalsBrf,
               n .. ' has a decimal places larger than ' .. max ..
               '; contact Schooner-FactorySW-Help@group.apple.com ' ..
               'if this is really needed.')
end

M.unrecognizedRangeBrf = 'Unrecognized range'
function M:unrecognizedRange(range)
    self:error(M.unrecognizedRangeBrf,
               'Unrecognized range: ' .. tostring(range) ..
               '; expecting [start:last], [start:last#count], ' ..
               '[start:step:last] or [start:step:last#count]')
end

M.rangeHasDifferentDecimalsBrf =
'Start/step/last in range has different decimal places'
function M:rangeHasDifferentDecimals(range,
                                     decimalsOfStart,
                                     decimalsOfStep,
                                     decimalsOfLast)
    self:error(M.rangeHasDifferentDecimalsBrf,
               'Range ' .. tostring(range) .. ': decimal places of start(' ..
               decimalsOfStart .. ')/step(' .. decimalsOfStep .. ')/last(' ..
               decimalsOfLast .. ') are not' ..
               ' the same; expecting the same number of decimal places.')
end

M.invalidLastInRangeBrf = 'Last in range not valid'
function M:invalidLastInRange(range, last)
    self:error(M.invalidLastInRangeBrf,
               'last=' .. last .. ' in range ' .. range ..
               ' is not an effective number.')
end

M.incorrectCountInRangeBrf = 'Incorrect count in range'
function M:incorrectCountInRange(range, count)
    self:error(M.incorrectCountInRangeBrf,
               'count=' .. count .. ' in range ' .. range ..
               ' is incorrect; expecting the exact number of loop counts,' ..
               ' with last number counted.')
end

M.invalidRangeBrf = 'Invalid range'
function M:invalidRange(range, start, step, last)
    if step < 0 then
        self:error(M.invalidRangeBrf,
                   'Invalid range ' .. tostring(range) .. ': start(' .. start ..
                   ') <= last(' .. last .. ') when step(' .. step .. ') < 0.')
    elseif step > 0 then
        self:error(M.invalidRangeBrf,
                   'Invalid range ' .. tostring(range) .. ': start(' .. start ..
                   ') >= last(' .. last .. ') when step(' .. step .. ') > 0.')
    else
        self:error(M.invalidRangeBrf, 'Invalid range ' .. tostring(range) ..
                   ': step is zero, while it should not.')
    end

end

M.unsupportedItemInItemsBrf =
'Unsupported item in [item1, item2, ...] loop syntax'
function M:unsupportedItemInItems(item, range)
    self:error(M.unsupportedItemInItemsBrf,
               'item ' .. item .. ' in range ' .. range ..
               ' is unsupported; expecting string or numeric ' ..
               'string, without quotes, like Red, 1.1 or -2')
end

-- compiler setting error
M.unexpectedCompilerSettingBrf = 'Unexpected Compiler Configuration'
function M:unexpectedCompilerSetting(key, keys)
    self:error(M.unexpectedCompilerSettingBrf, 'Invalid key in table:' ..
               tostring(key) .. '; expecting one of ' .. dump(keys))
end

M.unexpectedCompilerSettingTypeBrf = 'Unexpected Compiler Configuration Type'
function M:unexpectedCompilerSettingType(key, value, expectedType)
    self:error(M.unexpectedCompilerSettingTypeBrf,
               'key ' .. tostring(key) .. ' has value ' .. tostring(value) ..
               ', type is ' .. type(value) .. ', expecting type ' ..
               expectedType)
end

-- compiler setting error
M.unexpectedCompilerPlistKeyBrf = 'Unexpected Compiler Plist Key'
function M:unexpectedCompilerPlistKey(key, keys)
    local keyOfKeys = {}
    for k in pairs(keys) do
        table.insert(keyOfKeys, k)
    end
    self:internalError(M.unexpectedCompilerPlistKeyBrf,
                       'Invalid key in table:' .. tostring(key) ..
                       '; expecting one of ' .. pl.stringx.join(', ', keyOfKeys))
end

M.unexpectedCompilerPlistKeyTypeBrf = 'Unexpected Compiler Plist Key Type'
function M:unexpectedCompilerPlistKeyType(key, value, expectedType)
    self:internalError(M.unexpectedCompilerPlsitKeyTypeBrf,
                       'key ' .. tostring(key) .. ' has value ' ..
                       tostring(value) .. ', type is ' .. type(value) ..
                       ', expecting type ' .. expectedType)
end

M.emptyCompilerPlistKeysBrf = 'Compiler get no argument from Group.args'
function M:emptyCompilerPlistKeys()
    self:internalError(M.emptyCompilerPlistKeysBrf,
                       'Is a coreless plist supplied?')
end

M.internalInvalidLoopBrf = 'Invalid Loop'
function M:internalInvalidLoop(loop)
    self:internalError(M.internalInvalidLoopBrf,
                       'invalid loop to iterate:' .. tostring(loop) ..
                       '; expecting {items={}} or ' .. '{start=, last=, ...}')
end

M.internalInvalidActionsKeyTypeBrf = 'Invalid "actions" key type'
function M:internalInvalidActionsKeyType(key)
    self:internalError(M.internalInvalidActionsKeyTypeBrf,
                       'key: ' .. tostring(key) .. ', type: ' .. type(key) ..
                       '; expecting string or number.')
end

-------------------------------------------------------------------------------
--- Warnings
-------------------------------------------------------------------------------

M.warnChangedBackgroundBrf = 'Changed background'
function M:warnChangedBackground(actionName, changedDeps)
    local msg = 'Action "' .. actionName .. '" is in critical section, '
    msg = msg .. 'resulting in the background = false '
    msg = msg .. 'for the following dependent actions '
    msg = msg .. pl.pretty.write(changedDeps)
    self:warning(M.warnChangedBackgroundBrf, msg)
end

return M
