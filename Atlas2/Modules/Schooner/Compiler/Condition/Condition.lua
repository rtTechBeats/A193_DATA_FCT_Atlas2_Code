local errors = require("Schooner.Compiler.Errors")
local C = require('Schooner.Compiler.CompilerHelpers')
local common = require('Schooner.SchoonerCommon')
local parserFactory = require(
                      'Schooner.Compiler.Condition.Parsers.ParserFactory')
local pl = require('pl.import_into')()

local Condition = {}

function Condition.removeUnusedField(conditions)
    for _, condition in ipairs(conditions) do
        condition.Generator = nil
        condition.Validator = nil
        condition.expectedFilterValues = nil
    end
end

-- split condition defs into 3 types as conditions.group, conditions.init and conditions.test
-- also set condition.name from condition.Name to align with other keys like
-- generator and validator.
function Condition.categorize(conditions)
    local group = {}
    local init = {}
    local test = {}

    local mapping = { Group = group, Init = init, Test = test }
    local processFunction = function(condition)
        assert(mapping[condition.When],
               "[Internal] Undefined When: " .. condition.When)
        table.insert(mapping[condition.When], condition)
        condition.When = nil
        condition.name = condition.Name
        condition.Name = nil
    end

    -- imap: run function for every item in the list
    pl.tablex.imap(processFunction, conditions)

    -- if empty, do not output empty table
    return {
        group = next(group) and group,
        init = next(init) and init,
        test = next(test) and test
    }
end

function Condition.getTestConditionNames(conditionTable)
    local testConditions = {}
    for _, testConditionInfo in ipairs(conditionTable.test or {}) do
        testConditions[testConditionInfo.name] = true
    end
    return testConditions
end

local function isMode(condition)
    return condition.Name == common.SHARED_COLUMNS.Mode
end

-- parse Conditions CSV and return parsed condition table (group based on WHEN type)
-- to be used by runner
-- @param conditionCSV    string, path of conditionCSV file
-- @arg conditions      Lua table of Condition.csv content
function Condition.parse(conditions)
    local names = {}
    local expectedFilterValues = {}
    local seenMode = false

    for _, condition in ipairs(conditions) do
        seenMode = seenMode or isMode(condition)
        local parser = parserFactory.createParser(condition)
        parser:run(names)
        if parser.condition.expectedFilterValues then
            local lowerCase = common.ALL_FILTERS[condition.Name]
            expectedFilterValues[lowerCase] = parser.condition
                                              .expectedFilterValues
        end
    end

    if not seenMode then
        errors:missingMode()
    end

    return expectedFilterValues
end

-- @param       conditionCSV            string, path of conditionCSV file (assumed non-nil)
-- @returns     conditionsByWhen        table, dictionary of conditions grouped by WHEN
--              expectedFilterValues    table, dictionary of filter values from IN validator
function Condition.processConditions(conditionCSV)
    errors:pushLocation(conditionCSV)

    local header, conditions = C.loadCSV(conditionCSV, common.CONDITIONS)
    -- if path is given, it should have valid header.
    C.validateHeader(conditionCSV, header, common.CONDITIONS)
    local expectedFilterValues = Condition.parse(conditions)
    Condition.removeUnusedField(conditions)
    local conditionsByWhen = Condition.categorize(conditions)

    errors:popLocation()
    return conditionsByWhen, expectedFilterValues
end

return Condition
