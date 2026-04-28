---@diagnostic disable: duplicate-set-field
local errors = require("Schooner.Compiler.Errors")
local helper = require('Schooner.SchoonerHelpers')
local baseParser = require('Schooner.Compiler.Condition.Parsers.BaseParser')
local C = require('Schooner.Compiler.CompilerHelpers')
local common = require('Schooner.SchoonerCommon')

local filterParser = setmetatable({}, { __index = baseParser })
filterParser.__index = filterParser

function filterParser.new(condition)
    return setmetatable(baseParser.new(condition), filterParser)
end

function filterParser:validateWhen()
    if self.condition.When == 'Test' then
        errors:invalidFilterWhen(self.condition.Name, self.condition.When)
    end
    baseParser.validateWhen(self)
end

function filterParser:parseAndValidateGenerator()
    local name = self.condition.Name
    local lowerCaseName = common.ALL_FILTERS[name]
    assert(lowerCaseName ~= nil,
           ('[Internal]: unsupported filter %s'):format(name))
    local generator = self.condition.Generator

    if helper.isNonEmptyString(generator) then
        -- Module path can start with dash/underscore, but not dot/slash
        local patternModule = '([a-zA-Z_%-][0-9a-zA-Z/_%.%-]*)'
        local patternFunction = '([a-zA-Z_][0-9a-zA-Z_]*)'
        local pattern = '^' .. patternModule .. ':' .. patternFunction .. '$'
        local module, func = generator:match(pattern)
        if module == nil or func == nil then
            errors:invalidConditionGeneratorFormat(name, generator, pattern)
        end

        -- update generator to parsed value
        self.condition.generator = { module = module, func = func }
    end
end

function filterParser:overrideGenerator()
    local generator = self.condition.Generator
    local name = self.condition.Name
    local lowerCaseName = common.ALL_FILTERS[name]
    if generator == nil or generator == "" then
        self.condition.generator = {
            module = "Schooner/DefaultConditionGeneratorAndValidator",
            func = lowerCaseName
        }
    end
    self.condition.Generator = nil
end

-- Filters only support IN validator (items must be quoted)
function filterParser:parseAndValidateValidator()
    local name = self.condition.Name
    local lowerCaseName = common.ALL_FILTERS[name]
    assert(lowerCaseName ~= nil,
           ('[Internal]: unsupported filter %s'):format(name))
    local validator = self.condition.Validator

    local patternIN = '^IN%((.*)%)$'
    local captureIN = validator:match(patternIN)
    if captureIN == nil then
        -- validator isn't IN(), error
        errors:invalidFilterValidator(name, validator)
    end
    if captureIN == '' then
        -- validator is IN() with empty content, error
        errors:conditionValidatorEmptyIN(name)
    end

    local preProcessedList = C.stringToArray(captureIN)
    local allowedList = {}
    -- Expose to Main/Limit csv parsing
    local expectedFilterValues = {}

    for _, value in ipairs(preProcessedList) do
        value = C.stripAndUnquote(value)
        C.checkFieldFormat(value, lowerCaseName, 'badSpecFieldFormat')
        table.insert(allowedList, value)
        expectedFilterValues[value] = true
    end

    -- All values treated as strings, no conversion to BOOL or number
    self.condition.validator = { type = 'IN', allowedList = allowedList }
    self.condition.expectedFilterValues = expectedFilterValues
end

return filterParser
