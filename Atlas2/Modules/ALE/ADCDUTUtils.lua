--[[
--! @defgroup adcdututils ADCDUT Plugin Utilities
--! @{
--!
--! @brief Utility library for interacting with DUT through the ADCDUT plugin
--!
--! @details This module provides high-level utilities for remote device communication, task execution,
--! file operations, and device management. It simplifies common operations when working with DUTs
--! in the Atlas testing framework.
--!
--! **Key Features:**
--! - Remote task execution with timeout support
--! - Interactive command execution with stdin/stdout/stderr handling
--! - File and directory operations (copy, create, remove)
--! - Command sequence execution with parameter interpolation
--! - Device URL management and connection setup
--!
--! **Common Usage Patterns:**
--!
--! ```lua
--! local ADCDUT = require "ALE.ADCDUTUtils"
--!
--! -- Setup connection to DUT
--! local adcPlugin = Atlas.loadPlugin("ADCDUT")
--! ADCDUT.setUrlByName(adcPlugin, "MyDevice")
--!
--! -- Execute simple shell commands
--! local result = ADCDUT.executeShellCommand(adcPlugin, "ls -la /tmp", 10)
--! print("Exit code:", result.exitcode)
--! print("Output:", result.stdout)
--!
--! -- Execute tasks with arguments
--! local result = ADCDUT.executeTask(adcPlugin, "/bin/ls", {"-la", "/tmp"}, 5)
--! if result.exitcode == 0 then
--!     print("Directory listing:", result.stdout)
--! end
--!
--! -- Execute command sequences with parameter substitution
--! local sequence = {
--!     {"/usr/local/bin/diagstool lcdmura --p3 ${r},${g},${b}", "", 5, ""},
--!     {"/usr/local/bin/OSDToolbox version 2>&1", "BuildVersion\t([^\t\n]+)", 5, "BuildVersion"},
--! }
--! local params = {r = 1023, g = 0, b = 0}
--! local results = ADCDUT.executeSequence(adcPlugin, sequence, params)
--! print("Build version:", results.BuildVersion[1])
--!
--! -- Interactive task execution
--! local task = ADCDUT.startTask(adcPlugin, "/bin/sh", {})
--! ADCDUT.writeToStdIn(task.stdio, "echo 'Hello World'", "\n")
--! local output = ADCDUT.readFromStdOut(task.stdio, nil, 5)
--! ADCDUT.terminateTask(task.task, 3)
--!
--! -- File operations
--! ADCDUT.copyToDUT(adcPlugin, "/local/file.txt", "/remote/file.txt")
--! ADCDUT.createDir(adcPlugin, "/tmp/test_directory")
--! ADCDUT.copyFromDUT(adcPlugin, "/remote/result.log", "/local/result.log")
--! ADCDUT.removeFile(adcPlugin, "/tmp/temporary_file")
--! ```
--]] local StringUtils = require "ALE.StringUtils"
local TypeUtils = require "ALE.TypeUtils"

local ADCDUT = {version = "1.2.18"}

--[[
--! @brief Sets the URL used to connect to the DUT
--! @param adcPlugin The instance of ADCDUT plugin
--! @param deviceName Name of DUT in Atlas System.
--]]
function ADCDUT.setUrlByName(adcPlugin, deviceName)
    print("Device Name: " .. deviceName)

    local transport = Group.getDeviceTransport(deviceName)
    print("DUT URL: " .. transport)

    adcPlugin.setURL(transport)
    return transport
end

--[[
--! @brief Start a new task.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param command Full path to the command to run (use e.g. `/bin/ls` instead of ls).
--! @param arguments Array of string arguments that are passed to the task.
--! @return Dictionary with the following entries:
--!         * `task`: Instance of Remote Task plugin
--!         * `stdio`: Instance of CommPlugin that can be used to read/write to task stdio
--!         * `stderr`: Instance of CommPlugin that can be used to read/write to task stderr
--]]
function ADCDUT.startTask(adcPlugin, command, arguments)
    assert(type(command) == "string", "Command must be a string")
    assert(type(arguments) == "table", "Arguments must be a table")

    local commBuilder

    if Atlas ~= nil then
        commBuilder = Atlas.loadPlugin("CommBuilder")
    else
        commBuilder = require "CommBuilder"
    end

    local task = {}
    task["task"] = adcPlugin.createRemoteTask()
    task["task"].setExecutablePath(command)
    task["task"].setArguments(arguments)

    local stdio = commBuilder.createCommPlugin(task["task"].standardInputOutputChannel())
    task["stdio"] = stdio
    local stderr = commBuilder.createCommPlugin(task["task"].standardErrorChannel())
    task["stderr"] = stderr

    task["task"].launch()

    -- Call open() is mandatory in Atlas 2.33
    -- In Atlas less than 2.33, after remote task launch, stdio/stderr already opened.
    -- reopen stdio/stderr will cause error
    if (Atlas.compareVersionTo("2.33") ~= Atlas.versionComparisonResult.lessThan) then
        stdio.open()
        stderr.open()
    end

    -- TODO: check status
    -- There is no way of checking if the task started succesfully,
    -- because createRemoteTask always return a taskKey.
    -- And task.launch() returns nothing.

    return task
end

--[[
--! @brief Write to stdin of a task.
--! @param commPlugin the communication Plugin created in StartTask
--! @param str String to be written.
--! @param lineTerminator character appended to str, can be nil.
--]]
function ADCDUT.writeToStdIn(commPlugin, str, lineTerminator)
    assert(type(str) == "string", "str must be a string")

    -- Need to append line terminator to str following the request of remote side
    if (lineTerminator ~= nil) then
        commPlugin.setLineTerminator(lineTerminator)
    end

    commPlugin.write(str)
end

--[[
--! @brief Keep reading from stdout of a task until the contents match the string in waitfor param.
--! @param commPlugin the communication Plugin created in StartTask
--! @param waitfor string to match in output. If nil, this is skipped.
--! @param waitfor_timeout How many seconds to keep waiting for the waitfor match.
--]]
function ADCDUT.readFromStdOut(commPlugin, waitfor, waitfor_timeout)

    local timeout = waitfor_timeout or 1
    local resp
    local status

    -- "waitfor" here means expected delimiter send from remote side
    if (waitfor == nil) then
        status, resp = pcall(commPlugin.read, timeout)

        if not status then
            print("Failed to read stdio")
            resp = ""
        end
    else
        commPlugin.setDelimiter(waitfor)
        status, resp = pcall(commPlugin.read, timeout)

        -- ADC Plugin fails when waitfor match fails
        -- Try to get the whole output from stdout if waitfor match failed
        if not status then
            print("ADCDUT- Failed to match: " .. waitfor)
            -- resp here maybe only some debug info
            -- maybe we can drop this "print"
            print("Error: " .. resp)
            status, resp = pcall(commPlugin.read, timeout, "")
            if status then
                local errString = "Wait for [" .. waitfor .. "] failed with output '" .. resp .. "'"
                error(errString)
            end

            local errString = "Wait for [" .. waitfor .. "] failed"
            error(errString)
        end
    end

    return resp
end

--[[
--! @brief Keep reading from stderr of a task until the contents match string in waitfor param.
--! @param commPlugin the communication Plugin created in StartTask
--! @param waitfor Regular expression string to search for. If nil, this is skipped.
--! @param waitfor_timeout How many seconds to keep waiting for the waitfor match.
--! @return Stderr contents as a string. Throws exception if waitfor match is not found by timeout.
--]]
function ADCDUT.readFromStdErr(commPlugin, waitfor, waitfor_timeout)

    local resp
    local timeout = waitfor_timeout or 1

    if (waitfor == nil) then
        status, resp = pcall(commPlugin.read, timeout)
        if not status then
            print("Failed to read stderr")
            resp = ""
        end
    else
        commPlugin.setDelimiter(waitfor)
        resp = commPlugin.read(timeout)

        -- Currently ADC Plugin returns an empty string if waitfor match fails
        assert(resp ~= "", "Failed to match waitfor: " .. waitfor)
    end

    return resp
end

--[[
--! @brief Attempt to terminate a task by sending SIGTERM.
--! @param task Task to terminate.
--! @param timeout Optional timeout (in seconds) to wait for the task to exit
--! @return nil.
--! @throws Lua error if task has not ended by exitTimeout
--]]
function ADCDUT.terminateTask(task, timeout)
    local sigTerm = 15
    local exitTimeout = timeout or 3

    task.sendSignal(sigTerm)
    print(string.format("waitUntilExit(%.1f)...", exitTimeout))
    task.waitUntilExit(exitTimeout) -- will throw an error if task has not ended by exitTimeout
end

--[[
--! @brief Kill a remote task by sending SIGKILL.
--! @param task Task to kill.
--! @return nil.
--]]
function ADCDUT.killTask(task)
    local sigKill = 9
    task.sendSignal(sigKill)
end

--[[
--! @brief Execute a sequence of shell commands
--! @param adcPlugin The instance of ADCDUT plugin
--! @param sequence Array of command definitions
--! @param parameters Dictionary with parameters to be interpolated into the commands
--! @returns Dictionary with individual command responses
--!
--! @details The sequence is an array of command definitions where
--! each command definition is an array of the following elements:
--! * [1]: string representing command to be executed including all arguments space separated
--! * [2]: regex to extract the individual fields from the response or nil to return the entire response
--! * [3]: timeout value for this command in seconds
--! * [4]: string key name for this command output in the resulting sequence execution output
--! <br>
--! Commands might contain a placeholder in the following format: ${placeholder_name}
--! The parameters arg of this function must contain dictionary entries to resolve
--! all placeholders mentioned in all commands.
--!<br>
--! The output of the function is a dictionary where each entry represents individual command
--! output. If key name for the result is not provided - the individual command result won't be included into the output
--!
--! @code
--! sequence = {
--!     {"/usr/local/bin/diagstool lcdmura --p3 ${r},${g},${b}", "", 5, ""},
--!     {"/usr/local/bin/OSDToolbox version 2>&1", "", 5, "SWBundleVersion"},
--! }
--! result = dut.ExecuteSequence(sequence, {["r"] = 1023, ["g"] = 0, ["b"] = 0})
--! -- result is: {["SWBundleVersion"] = { [1] = "BuildVersion	FFFFF"} }
--! @endcode
--!
--]]
function ADCDUT.executeSequence(adcPlugin, sequence, parameters)

    local sequence_result = {}

    for _, item in ipairs(sequence) do
        local command = StringUtils.interpolateString(item[1], parameters)
        local expected_resp = item[2]
        local timeout = item[3]
        local name = item[4]

        -- For debugging
        print("Run cmd " .. command)

        local result = ADCDUT.executeTask(adcPlugin, "/bin/sh", {"-c", command}, timeout)

        -- Only store result if there's a name for the result provided
        if (name ~= "") and (name ~= nil) then
            -- Create an empty array for this command response items
            sequence_result[name] = {}

            local command_output = result["stdout"]
            if expected_resp ~= "" then
                if string.gmatch(command_output, expected_resp)() == nil then
                    print("CMD output: " .. command_output)
                    error(string.format("Didn't catch expected output: %s", expected_resp))
                end

                local match = string.gmatch(command_output, expected_resp)
                for m in match do
                    table.insert(sequence_result[name], m)
                end
            else
                table.insert(sequence_result[name], command_output)
            end
        end
    end

    return sequence_result
end

local function executeRemoteTask(task, timeout)

    task.launch()

    -- If timeout was triggered, status will be false
    local status, retVal = pcall(task.waitUntilExit, timeout)
    -- Looks like statusStdOut/statusStdErr is always true in Atlas2.33
    local statusStdOut, stdout = pcall(task.readStdoutBuffer)
    local statusStdErr, stderr = pcall(task.readStderrBuffer)

    if not status then
        ADCDUT.killTask(task)
        error("TIMEOUT executing command")
    end

    return {
        ["stderrSts"] = statusStdErr,
        ["stderr"] = stderr,
        ["stdoutSts"] = statusStdOut,
        ["stdout"] = stdout,
        ["exitcode"] = retVal
    }
end

--[[
--! @brief Executes a shell command, and waits for it to finish.
--! @note Exception will be thrown if the command exist code is not 0.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param command Full command string including the executable and arguments
--! @param timeout How many seconds to wait for the task to finish
--! @return See ADCDUT.ExecuteTask() return value
--]]
function ADCDUT.executeShellCommand(adcPlugin, command, timeout)
    -- Apply default values if needed
    timeout = timeout or -1 -- use the default timeout if needed

    assert(type(command) == "string", "Command must be a string")
    assert(type(timeout) == "number", "Timeout must be a number")

    local task = adcPlugin.createRemoteTask()
    task.setShellCommand(command)

    return executeRemoteTask(task, timeout)
end

--[[
--! @brief Start a new task, and wait for it to finish.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param command Full path to the command to run (use e.g. /bin/ls instead of ls).
--! @param arguments Array of string arguments that are passed to the task.
--! @param timeout How many seconds to wait for the task to finish
--! @return Dictionary with the following entries:
--!         * `exitcode`: Task exit code
--!         * `stdout`: Resulting task stdout string
--!         * `stderr`: Resulting task stderr string
--]]
function ADCDUT.executeTask(adcPlugin, command, arguments, timeout)
    -- Apply default values if needed
    timeout = timeout or -1 -- use the default timeout if needed

    assert(type(command) == "string", "Command must be a string")
    assert(type(arguments) == "table", "Arguments must be a table")
    assert(type(timeout) == "number", "Timeout must be a number")

    local task = adcPlugin.createRemoteTask()
    task.setExecutablePath(command)
    task.setArguments(arguments)

    return executeRemoteTask(task, timeout)
end

-- - - - - - -
-- Copy files
-- - - - - - -

--[[
--! @brief Copy a file or directory to DUT.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param src Path to source file or directory in Mac.
--! @param dst Path to destination directory in DUT.
--! @note The function might not work at the moment.
--! The issue is tracked with this [radar](rdar://76044612).
--! @note For copying a file, the destination path must end with the exact same
--! filename as the fileame in Mac.
--! src and dst must be absolute path.
--]]
function ADCDUT.copyToDUT(adcPlugin, src, dst)
    local paramTbl = {}

    print("Copy to DUT")
    print("HOST: " .. src)
    print(" DUT: " .. dst)

    paramTbl[src] = dst

    adcPlugin.copyToDevice(paramTbl)
end

--[[
--! @brief Copy a file or directory from DUT.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param src Path to source file or directory in DUT.
--! @param dst Path to destination directory in Mac.
--! For copying a file, the destination path must end with the exact same
--! filename as the fileame in DUT.
--! src and dst must be absolute path.
--]]
function ADCDUT.copyFromDUT(adcPlugin, src, dst)
    local paramTbl = {}

    print("Copy from DUT:")
    print(" DUT: " .. src)
    print("HOST: " .. dst)

    paramTbl[src] = dst

    adcPlugin.copyToHost(paramTbl)
end

-- - - - - - -
-- Create/remove dirs / file
-- - - - - - -

--[[
--! @brief Create a directory in DUT (also create sub-directories if needed).
--! @param adcPlugin The instance of ADCDUT plugin
--! @param path Path to the directory to create in DUT.
--! @return See ADCDUT.ExecuteTask return value
--]]
function ADCDUT.createDir(adcPlugin, path)
    assert(type(path) == "string", "path must be a string")
    return ADCDUT.executeTask(adcPlugin, "/bin/mkdir", {"-p", path}, 1)
end

--[[
--! @brief Remove a directory in DUT.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param path Path to the directory to remove in DUT.
--! @return See ADCDUT.ExecuteTask return value
--]]
function ADCDUT.removeDir(adcPlugin, path)
    assert(type(path) == "string", "path must be a string")
    return ADCDUT.executeTask(adcPlugin, "/bin/rm", {"-rf", path}, 1)
end

--[[
--! @brief Remove a file in DUT.
--! @param adcPlugin The instance of ADCDUT plugin
--! @param path Path to the file to remove in DUT.
--! @return See ADCDUT.ExecuteTask return value
--]]
function ADCDUT.removeFile(adcPlugin, path)
    assert(type(path) == "string", "path must be a string")
    return ADCDUT.executeTask(adcPlugin, "/bin/rm", {"-f", path}, 1)
end

function ADCDUT.listDir(adcPlugin, path)
    assert(type(path) == "string", "path must be a string")
    return ADCDUT.executeTask(adcPlugin, "/bin/ls", {"-l", path}, 1)
end

function ADCDUT.getDutTime(adcPlugin)
    return ADCDUT.executeTask(adcPlugin, "/bin/date", {}, 1)
end

function ADCDUT.pathExists(adcPlugin, path)
    TypeUtils.assertString(path)

    print("Search path: " .. path)

    local result = ADCDUT.executeTask(adcPlugin, "/usr/bin/find", {"-f", path}, 1)

    if result["exitcode"] == 0 then
        print(result["stdout"])
        return true
    end

    print(result["stderr"])
    return false
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

createPascalCaseAliases(ADCDUT)
return ADCDUT

--[[
--! @}
--]]
