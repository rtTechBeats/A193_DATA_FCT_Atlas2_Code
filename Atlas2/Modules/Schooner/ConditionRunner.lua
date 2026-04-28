local m = {}
local dump = require('Schooner.SchoonerHelpers').dump

function m.runConditionGenerator(name, generator, ...)
    assert(generator.module,
           'Condition variable ' .. name .. ' generator does not have module')
    assert(generator.func,
           'Condition variable ' .. name .. ' generator does not have func')
    local module = require(generator.module)
    assert(module ~= nil,
           'Condition ' .. name .. ': generator function module ' ..
           tostring(generator.module) .. ' does not exist or fail to require')

    local f = module[generator.func]
    assert(f ~= nil,
           'Condition ' .. name .. ': generator function ' ..
           tostring(generator.module) .. ':' .. tostring(generator.func) ..
           ' does not exist')
    local r = f(...)
    return r
end

function m.runConditionValidator(name, validator, value)
    assert(validator.type,
           'Condition variable ' .. name .. ' validator does not have type')
    if validator.type == 'IN' then
        m.runConditionValidatorIN(name, validator.allowedList, value)
    elseif validator.type == 'RANGE' then
        m.runConditionValidatorRANGE(name, validator.min, validator.max, value)
    elseif validator.type == 'moduleFunction' then
        m.runConditionValidatorModuleFunction(name, validator.module,
                                              validator.func, value)
    else
        error('[Schooner Internal] Invalid validator type: ' ..
              tostring(validator.type) ..
              ', expecting [IN, RANGE or moduleFunction]')
    end
end

-- allowedList should be {value1=non-nil, value2=non-nil}
function m.runConditionValidatorIN(name, allowedList, value)
    assert(allowedList, 'Condition variable ' .. name ..
           ' IN validator does not have allowedList')
    for _, allowedValue in ipairs(allowedList) do
        if value == allowedValue then
            return
        end
    end
    error('Condition variable ' .. name .. ' value [' .. tostring(value) ..
          '] is not in allowed list ' .. dump(allowedList))
end

function m.runConditionValidatorRANGE(name, min, max, value)
    assert(min, 'Condition variable ' .. name ..
           ' RANGE validator does not have min value')
    assert(max, 'Condition variable ' .. name ..
           ' RANGE validator does not have max value')
    if value < min or value > max then
        error('Condition variable ' .. name .. ' value [' .. tostring(value) ..
              '] is out of allowed range [' .. min .. ', ' .. max .. ']')
    end
end

function m.runConditionValidatorModuleFunction(name, module, func, value)
    if value == nil then
        error('Condition variable ' .. name ..
              ' has nil value, which not support in schooner')
    end
    assert(module, 'Condition variable ' .. name ..
           ' module function validator does not have module')
    assert(func, 'Condition variable ' .. name ..
           ' module function validator does not have func')
    local r, requiredModule = pcall(require, module)
    assert(r == true,
           'Condition ' .. name .. ': validator function module ' ..
           tostring(module) .. ' does not exist or fail to require; error = ' ..
           tostring(requiredModule))

    local f = requiredModule[func]
    assert(f ~= nil,
           'Condition ' .. name .. ': validator function ' .. tostring(module) ..
           ':' .. tostring(func) .. ' does not exist')

    local ifComplete, result = xpcall(f, debug.traceback, value)
    if ifComplete == false then
        error('Condition variable ' .. name .. ' module function validator ' ..
              tostring(module) .. ':' .. tostring(func) .. '(' ..
              tostring(value) .. ') error out')
    end

    if type(result) ~= 'boolean' then
        error('Condition variable ' .. name .. ' module function validator ' ..
              tostring(module) .. ':' .. tostring(func) .. '(' ..
              tostring(value) .. ') return non-boolean value: ' ..
              tostring(result))
    end

    if result == false then
        error('Condition variable ' .. name .. ' has unallowed value; ' ..
              'module function validator ' .. tostring(module) .. ':' ..
              tostring(func) .. '(' .. tostring(value) .. ') return false')
    end
end

return m
