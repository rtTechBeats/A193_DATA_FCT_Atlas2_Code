--[[
--! @defgroup errorutils Error Handling Utilities
--! @{
--]] local ErrorUtils = {version = "1.2.18"}

local function errorMsgWithTraceback(err)
    local retErr = {}
    retErr.message = err
    retErr.stacktrace = debug.traceback(nil, nil, 0)
    return retErr
end

--[[
--! @brief Similar to standard pcall() function, but the exception object produced will have a full error stack trace
--]]
function ErrorUtils.pCallWithTraceback(func, ...)
    return xpcall(func, errorMsgWithTraceback, ...)
end

--[[
--! @brief Try/Catch block helper
--! @code
--! ErrorUtils.Try(
--! 	function ()
--! 		results.get(device_name)
--! 		print(action.." for "..device_name .. " ran without issues")
--! 	end,
--! 	function (erawr)
--! 		TestGroup.failTestableDevice(device_name, "SW ran into trouble")
--! 		unit.teardown(pluginStore[device_name]["dut"], device_name)
--! 		pluginStore[device_name] = nil
--!
--! 		error(action.." for "..device_name .. " failed with error :" .. erawr)
--! 	end
--! @endcode
--]]
function ErrorUtils.try(f, catch_f)
    local status, exception = ErrorUtils.PCallWithTraceback(f)
    if not status then
        catch_f(exception)
    end
end

--[[
--! @brief Raise error with specified error message
--]]
function ErrorUtils.raiseError(message)
    error(message, 0)
end

-- ! Temporary function to create PascalCase aliases for all functions
-- ! to keep backward compatibility
local function createPascalCaseAliases(module)
    local camelCaseNames = {}
    for k, v in pairs(module) do
        if type(v) == "function" and k:match("^[a-z]") then
            table.insert(camelCaseNames, k)
        end
    end
    for _, name in ipairs(camelCaseNames) do
        local pascalCaseName = name:sub(1, 1):upper() .. name:sub(2)
        module[pascalCaseName] = module[name]
    end
end

createPascalCaseAliases(ErrorUtils)
return ErrorUtils

--[[
--! @}
--]]
