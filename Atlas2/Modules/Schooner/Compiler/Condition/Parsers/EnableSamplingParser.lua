---@diagnostic disable: duplicate-set-field
local errors = require("Schooner.Compiler.Errors")
local helper = require('Schooner.SchoonerHelpers')
local baseParser = require('Schooner.Compiler.Condition.Parsers.BaseParser')

local EnableSamplingParser = setmetatable({}, { __index = baseParser })
EnableSamplingParser.__index = EnableSamplingParser

function EnableSamplingParser.new(condition)
    return setmetatable(baseParser.new(condition), EnableSamplingParser)
end

function EnableSamplingParser:validateWhen()
    if self.condition.When == 'Group' then
        errors:invalidSamplingConditionType()
    end
    baseParser.validateWhen(self)
end

function EnableSamplingParser:parseAndValidateValidator()
    if helper.isNonEmptyString(self.condition.Validator) then
        errors:enableSamplingConditionHasValidator(self.condition.Name,
                                                   self.condition.Validator)
    end
end

return EnableSamplingParser
