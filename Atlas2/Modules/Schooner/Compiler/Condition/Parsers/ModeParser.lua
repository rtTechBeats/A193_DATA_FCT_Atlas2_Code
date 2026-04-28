---@diagnostic disable: duplicate-set-field
local errors = require("Schooner.Compiler.Errors")
local helper = require('Schooner.SchoonerHelpers')
local filterParser = require('Schooner.Compiler.Condition.Parsers.FilterParser')
local common = require('Schooner.SchoonerCommon')

local ModeParser = setmetatable({}, { __index = filterParser })
ModeParser.__index = ModeParser

function ModeParser.new(condition)
    return setmetatable(filterParser.new(condition), ModeParser)
end

function ModeParser:validateWhen()
    if helper.isNonEmptyString(self.condition.When) then
        errors:conditionHasNonEmptyWhen(self.condition.Name, self.condition.When)
    end
end

function ModeParser:overrideWhen() self.condition.When = 'Group' end

function ModeParser:parseAndValidateGenerator()
    if helper.isNonEmptyString(self.condition.Generator) then
        errors:ModeHasGenerator(self.condition.Generator)
    end
end

function ModeParser:overrideGenerator()
    self.condition.generator = {
        module = "Schooner/DefaultConditionGeneratorAndValidator",
        func = common.MODE
    }
end

return ModeParser
