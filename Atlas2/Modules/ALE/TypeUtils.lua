--[[
--! @defgroup typeutils Type Utilities
--! @{
--]] local TypeUtils = {version = "1.2.18"}

--[[
--! @brief          Check that argument type is of given type
--!
--! @param arg      argument to check type
--! @param arg_type type of the argument
--!
--! @returns        arg if type of arg is the same as arg_type. Otherwise error.
--]]
function TypeUtils.assertType(arg, arg_type)
    if type(arg) ~= arg_type then
        error(string.format("expected %s to be '%s' but is '%s'", arg, tostring(arg_type), type(arg)))
    end

    return arg
end

--[[
--! @brief          Check that argument type is of string type
--!
--! @param arg      argument to check
--!
--! @returns        arg if type of arg is of type string. Otherwise error.
--]]
function TypeUtils.assertString(arg)
    return TypeUtils.assertType(arg, 'string')
end

--[[
--! @brief          Check that argument type is of number type
--!
--! @param arg      argument to check
--!
--! @returns        arg if type of arg is of type number. Otherwise error.
--]]
function TypeUtils.assertNumber(arg)
    return TypeUtils.assertType(arg, 'number')
end

--[[
--! @brief          Check that argument type is of table type
--!
--! @param arg      argument to check
--!
--! @returns        arg if type of arg is of type table. Otherwise error.
--]]
function TypeUtils.assertTable(arg)
    return TypeUtils.assertType(arg, 'table')
end

--[[
--! @brief          Returns a deep copy of the input value.
--!
--! @param orig     the original input value
--!
--! @returns        the deep copy.
--]]
function TypeUtils.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[TypeUtils.DeepCopy(orig_key)] = TypeUtils.DeepCopy(orig_value)
        end
        setmetatable(copy, TypeUtils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function TypeUtils.DeepCopy(orig)
    return TypeUtils.deepCopy(orig)
end

return TypeUtils

--[[
--! @}
--]]
