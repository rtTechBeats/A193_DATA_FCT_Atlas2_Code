---@diagnostic disable: duplicate-set-field
local errors = require("Schooner.Compiler.Errors")
local helper = require('Schooner.SchoonerHelpers')
local baseParser = require('Schooner.Compiler.Condition.Parsers.BaseParser')

local NoCLParser = setmetatable({}, { __index = baseParser })
NoCLParser.__index = NoCLParser

function NoCLParser.new(condition)
    return setmetatable(baseParser.new(condition), NoCLParser)
end

function NoCLParser:validateWhen()
    if helper.isNonEmptyString(self.condition.When) then
        errors:conditionHasNonEmptyWhen(self.condition.Name, self.condition.When)
    end
end

function NoCLParser:overrideWhen() self.condition.When = 'Init' end

function NoCLParser:parseAndValidateGenerator()
    if helper.isNonEmptyString(self.condition.Generator) then
        errors:NoClConditionHasGenerator(self.condition.Name,
                                         self.condition.Generator)
    end
end

function NoCLParser:parseAndValidateValidator()
    if helper.isNonEmptyString(self.condition.Validator) then
        errors:NoClConditionHasValidator(self.condition.Name,
                                         self.condition.Validator)
    end
end

function NoCLParser:overrideValidator()
    self.condition.validator = {
        ["type"] = "moduleFunction",
        ["module"] = "Schooner/DefaultConditionGeneratorAndValidator",
        ["func"] = "noClValidator"
    }
end

function NoCLParser:overrideGenerator()
    self.condition.generator = {
        ["func"] = "noCl",
        ["module"] = "Schooner/DefaultConditionGeneratorAndValidator"
    }
end

return NoCLParser
