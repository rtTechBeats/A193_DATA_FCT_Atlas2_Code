local errors = require("Schooner.Compiler.Errors")
local helper = require('Schooner.SchoonerHelpers')
local dump = helper.dump
local C = require('Schooner.Compiler.CompilerHelpers')
local common = require('Schooner.SchoonerCommon')

local BaseParser = {}
BaseParser.__index = BaseParser

function BaseParser.new(condition)
    local self = setmetatable({}, BaseParser)
    self.condition = condition
    return self
end

function BaseParser.validateReservedName(name)
    for _, value in pairs(common.RESERVED_CONDITIONS) do
        if string.lower(name) == string.lower(value) and name ~= value then
            errors:invalidReservedConditionName(name, value)
        end
    end
end

function BaseParser.validateDuplicateName(name, names)
    if names[name] ~= nil then
        errors:duplicatedConditionName(name)
    end
    names[name] = true
    C.checkFieldFormat(name, common.CONDITION_NAME, 'badSpecFieldFormat')
end

function BaseParser:validateName(names)
    local condition = self.condition
    local name = condition.Name

    BaseParser.validateReservedName(name)
    BaseParser.validateDuplicateName(name, names)
end

function BaseParser:validateWhen()
    local condition = self.condition
    local name = condition.Name
    local when = condition.When

    if helper.hasVal(common.CONDITION_WHEN, when) == false then
        errors:invalidConditionWhen(name, when, dump(common.CONDITION_WHEN))
    end
end

function BaseParser:parseAndValidateGenerator()
    local condition = self.condition
    local name = condition.Name
    local when = condition.When
    local generator = condition.Generator

    if when == 'Test' and generator ~= "" then
        errors:testConditionHasGenerator(name, generator)
    end

    if when == 'Group' or when == 'Init' then
        if generator == '' then
            errors:conditionMissingGenerator(name)
        end
        -- Module path can start with dash/underscore, but not dot/slash
        local patternModule = '([a-zA-Z_%-][0-9a-zA-Z/_%.%-]*)'
        local patternFunction = '([a-zA-Z_][0-9a-zA-Z_]*)'
        local pattern = '^' .. patternModule .. ':' .. patternFunction .. '$'
        local module, func = generator:match(pattern)
        if module == nil or func == nil then
            errors:invalidConditionGeneratorFormat(name, generator, pattern)
        end

        -- update generator to parsed value
        condition.generator = { module = module, func = func }
    end
end

function BaseParser:parseAndValidateValidator()
    local condition = self.condition
    local name = condition.Name
    local validator = condition.Validator

    errors:pushLocation('Condition CSV row ' .. name)

    if validator == '' then
        errors:conditionMissingValidator(name)
    end

    -- support format:
    -- 1. modulePath:function
    -- 2. IN(commaSeparatedArray)
    -- 3. RANGE(min, max)
    -- Module path can start with dash/underscore, but not dot/slash
    local patternModule = '([a-zA-Z_%-][0-9a-zA-Z/_%.%-]*)'
    local patternFunction = '([a-zA-Z_][0-9a-zA-Z_]*)'
    local patternModuleFunction =
    '^' .. patternModule .. ':' .. patternFunction .. '$'
    local patternIN = '^IN%((.+)%)$'
    local patternCommaSeparatedArray = '([^,]+),'

    local patternRANGE = '^RANGE%(%s*([^,]-)%s*,%s*([^,]-)%s*%)$'

    if validator:match(patternModuleFunction) ~= nil then
        local module, func = validator:match(patternModuleFunction)
        condition.validator = {
            type = 'moduleFunction',
            module = module,
            func = func
        }
    elseif validator:match(patternIN) ~= nil then
        local strArray = validator:match(patternIN)
        local array = {}
        -- strArray is like "1", "1, 2" or "1, 2, 3".
        -- strip the ending spaces
        -- append "," so every item in the array match patternCommaSeparatedArray
        strArray = strArray:gsub('[ \t]$', '') .. ','
        for k in strArray:gmatch(patternCommaSeparatedArray) do
            -- strip heading and tailing spaces
            k = k:gsub('[ \t]$', '')
            k = k:gsub('^[ \t]', '')
            -- k should be
            -- 1. number string as number, like 1
            -- 2. or boolean string true or false
            -- 3. or a double/single quoted string, as string, like "1"
            if tonumber(k) then
                table.insert(array, tonumber(k))
            elseif k == 'true' or k == 'false' then
                table.insert(array, k == 'true')
            else
                local patternSingleQuoted = "^'([^']+)'$"
                local patternDoubleQuoted = '^"([^"]+)"$'
                local strWithoutQuote = k:match(patternSingleQuoted) or
                                        k:match(patternDoubleQuoted)
                if (strWithoutQuote) then
                    table.insert(array, strWithoutQuote)
                else
                    errors:invalidConditionValidatorFormat(name, validator)
                end
            end
        end

        if next(array) == nil then
            -- no allowed value, not supported.
            errors:conditionValidatorEmptyIN(name)
        end

        -- At first allowedList is converted to key-value dict for quicker "in" check later
        -- for example {"a", "b"} --> {"a"=true, "b"=true}
        -- But later found that this doesn't work for number:
        -- {0, 5} --> {[0]=true, [5]=true}: Atlas cannot convert number-key table into OC
        -- and Atlas will exception on this, with exception number being the 1st number; 0 in this case.
        -- so just keep it as an array
        local allowedList = array

        condition.validator = { type = 'IN', allowedList = allowedList }
    elseif validator:match(patternRANGE) ~= nil then
        local min, max = validator:match(patternRANGE)
        local numMin = tonumber(min)
        if numMin == nil then
            errors:conditionValidatorInvalidMinInRANGE(name, validator, min)
        end
        local numMax = tonumber(max)
        if numMax == nil then
            errors:conditionValidatorInvalidMaxInRANGE(name, validator, max)
        end

        condition.validator = { type = 'RANGE', min = numMin, max = numMax }
    else
        errors:invalidConditionValidatorFormat(name, validator)
    end
    errors:popLocation()
end

-- override functions
-- Normal condition doesn't need this so BaseParser does not implement them
-- for certain condition like Mode or NoCl, they can update
-- user's expected input "" to a predefined value
-- function BaseParser:overrideWhen() end
-- function BaseParser:overrideGenerator() end
-- function BaseParser:overrideValidator() end

function BaseParser:run(names)
    self:validateName(names)
    self:validateWhen()
    if self.overrideWhen then
        self:overrideWhen()
    end
    self:parseAndValidateGenerator()
    if self.overrideGenerator then
        self:overrideGenerator()
    end
    self:parseAndValidateValidator()
    if self.overrideValidator then
        self:overrideValidator()
    end
end

return BaseParser
