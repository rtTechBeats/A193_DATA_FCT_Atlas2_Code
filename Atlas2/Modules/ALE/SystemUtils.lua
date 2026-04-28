--[[
--! @defgroup systemutils System Utilities
--! @{
--]] local SystemUtils = {version = "1.2.18"}

local function getProcessPlugin()
    SystemUtils.processPlugin = SystemUtils.processPlugin or
                                    (Atlas and Atlas.loadPlugin("ALE/Process") or require("ALE/Process"))
    return SystemUtils.processPlugin
end

local function getTimePlugin()
    SystemUtils.timePlugin = SystemUtils.timePlugin or (Atlas and Atlas.loadPlugin("ALE/Time") or require("ALE/Time"))
    return SystemUtils.timePlugin
end

--[[
--! @brief Get the current time formatted as a string
--!
--! @param format       optional `NSDateFormatter` string which specifies format. default is "yyyy:MM:dd HH:mm:ss.SSS"
--!
--! @return             (string) formatted date string
--]]
function SystemUtils.timeNow(format)
    return getTimePlugin().now(format)
end

--[[
--! @brief Sleep for specified amount of seconds
--]]
function SystemUtils.sleepSeconds(seconds)
    getTimePlugin().sleep(seconds)
end

--[[
--! @brief Run specified system command
--! @returns exit_code, stdout, stderr, exit_status, success
--]]
function SystemUtils.runCommand(cmd)
    local status, stdout, stderr, reason = getProcessPlugin().executeShellCommand(cmd)
    return status, stdout, stderr, reason, true
end

--[[
--! @brief Similar to function above, but additionally asserts that exit_code is 0 and fails automatically otherwise
--! @todo Think of a better name for this function
--]]
function SystemUtils.runCommandAndCheck(cmd)
    local exit_code, stdout, stderr, exit_status, success = SystemUtils.runCommand(cmd)
    local err_msg = string.format("Failed command: %s, exit code: %s, stdout: %s, stderr: %s", tostring(cmd),
                                  tostring(exit_code), stdout, stderr)
    assert(exit_code == 0, err_msg)
    return exit_code, stdout, stderr, exit_status, success
end

--[[
--! @brief              Build a shell command string separated by spaces using input var args.
--!
--! @param ...          arguments to be used to build the command string
--!
--! @return             (string) built sh command
--]]
function SystemUtils.buildShellCommand(...)
    local cmdstr = ""
    local args = {...}
    for i = 0, #args do
        if args[i] then
            cmdstr = cmdstr .. " " .. args[i]
        end
    end
    return string.sub(cmdstr, 2)
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

createPascalCaseAliases(SystemUtils)
return SystemUtils

--[[
--! @}
--]]
