--[[
--! @defgroup fdcdututils FDCDUT Plugin Utilities
--! @{
--]] local StringUtils = require "ALE.StringUtils"
local SystemUtils = require "ALE.SystemUtils"

local FDCDUT = {version = "1.2.18"}

--[[
--! @brief Initialize FDCDUT wrapper
--! @param fdc_plugin FDCDUT plugin instance
--]]
function FDCDUT.initialize(fdc_plugin)
    FDCDUT.FDC = fdc_plugin
end

--[[
--! @brief Sets the URL used to connect to the DUT
--! @param url Device URL (e.g."usb://0x12310000")
--]]
function FDCDUT.setUrl(url)
    print("DUT URL: " .. url)

    FDCDUT.FDC.setURL(url)
end

--[[
--! @brief Sets the URL used to connect to the DUT
--! @param deviceName Name of DUT in Atlas System.
--]]
function FDCDUT.setUrlByName(deviceName)
    print("Device Name: " .. deviceName)

    local transport = Group.getDeviceTransport(deviceName)
    print("DUT URL: " .. transport)

    FDCDUT.FDC.setURL(transport)
end

--[[
--! @brief Start a new task.
--! @param command Full path to the command to run (use e.g. /bin/ls instead of ls).
--! @param arguments Array of string arguments that are passed to the task.
--! @return Dictionary of: {"taskKey": 140515582423744}.
--]]
function FDCDUT.startTask(command, arguments)
    local task = FDCDUT.FDC.createRemoteTask(command, arguments)
    task.launch()

    -- TODO: check status
    -- There is no way of checking if the task started succesfully,
    -- because there is always a taksKey returned even on bad commands
    return task
end

--[[
--! @brief Write to stdin of a task.
--! @param task Task to write to.
--! @param str String to be written.
--]]
function FDCDUT.writeToStdIn(task, str)
    assert(type(str) == "string", "str must be a string")

    local commBuilder

    if Atlas ~= nil then
        commBuilder = Atlas.loadPlugin("CommBuilder")
    else
        commBuilder = require "CommBuilder"
    end

    local stdioChan = commBuilder.createCommPlugin(task.stdioChannel())

    -- Need to append delimeter to str following the request of remote side
    stdioChan.write(str)
end

--[[
--! @brief Keep reading from stdout of a task until the contents match the string in waitfor param.
--! @param task Task to read from.
--! @param waitfor string to match in output. If nil, this is skipped.
--! @param waitfor_timeout How many seconds to keep waiting for the waitfor match.
--]]
function FDCDUT.readFromStdOut(task, waitfor, waitfor_timeout)
    local commBuilder

    if Atlas ~= nil then
        commBuilder = Atlas.loadPlugin("CommBuilder")
    else
        commBuilder = require "CommBuilder"
    end

    local stdioChan = commBuilder.createCommPlugin(task.stdioChannel())
    local resp
    local status

    -- "waitfor" here means expected delimiter send from remote side
    if (waitfor == nil) then
        status, resp = pcall(stdioChan.read)

        if not status then
            print("Failed to read stdio for task " .. task)
            resp = ""
        end
    else
        stdioChan.setDelimiter(waitfor)
        status, resp = pcall(stdioChan.read, waitfor_timeout)

        -- FDC Plugin fails when waitfor match fails
        -- Try to get the whole output from stdout if waitfor match failed
        if not status then
            print("FDCDUT- Failed to match: " .. waitfor)
            -- res here maybe only some debug info
            -- maybe we can drop this "print"
            print("Error: " .. resp)
            status, resp = pcall(stdioChan.read, waitfor_timeout, "")
            if status then
                local errString =
                    "Wait for [" .. waitfor .. "] failed for task [" .. task .. "] with output '" .. resp .. "'"
                error(errString)
            end

            local errString = "Wait for [" .. waitfor .. "] failed for task [" .. task .. "]"
            error(errString)
        end
    end

    return resp
end

--[[
--! @brief Keep reading from stderr of a task until the contents match string in waitfor param.
--! @param task Task to read from.
--! @param waitfor Regular expression string to search for. If nil, this is skipped.
--! @param waitfor_timeout How many seconds to keep waiting for the waitfor match.
--! @return Stderr contents as a string. Throws exception if waitfor match is not found by timeout.
--]]
function FDCDUT.readFromStdErr(task, waitfor, waitfor_timeout)
    local commBuilder

    if Atlas ~= nil then
        commBuilder = Atlas.loadPlugin("CommBuilder")
    else
        commBuilder = require "CommBuilder"
    end

    local stderrChan = commBuilder.createCommPlugin(task.stderrChannel())
    local resp

    if (waitfor == nil) then
        resp = stderrChan.read(waitfor_timeout)
    else
        stderrChan.setDelimiter(waitfor)
        resp = stderrChan.read(waitfor_timeout)

        -- Currently FDC Plugin returns an empty string if waitfor match fails
        assert(resp ~= "", "Failed to match waitfor: " .. waitfor)
    end

    return resp
end

--[[
--! @brief Terminate a task by sending SIGTERM.
--! @param task Task to terminate.
--]]
function FDCDUT.terminateTask(task)
    task.terminate()
end

--[[
--! @brief Execute a sequence of shell commands
--! @details The sequence is an array of command definitions where
--! each command definition is an array of the following elements:
--! [1]: string representing command to be executed including all arguments space separated
--! [2]: regex to extract the individual fields from the response or nil to return the entire response
--! [3]: timeout value for this command in seconds
--! [4]: string key name for this command output in the resulting sequence execution output
--!
--! Commands might contain a placeholder in the following format: ${placeholder_name}
--! The parameters arg of this function must contain dictionary entries to resolve
--! all placeholders mentioned in all commands.
--!
--! The output of the function is a dictionary where each entry represents individual command
--! output. If key name for the result is not provided - the individual command result won't be included into the output
--!
--! Example:
--!	sequence = {
--!		{"/usr/local/bin/diagstool lcdmura --p3 ${r},${g},${b}", "", 5, ""},
--!		{"/usr/local/bin/OSDToolbox version 2>&1", "", 5, "SWBundleVersion"},
--!	}
--!	result = dut.executeSequence(sequence, {["r"] = 1023, ["g"] = 0, ["b"] = 0})
--!
--! result is: {["SWBundleVersion"] = { [1] = "BuildVersion	FFFFF"} }
--!
--! @param sequence Array of command definitions
--! @param parameters Dictionary with parameters to be interpolated into the commands
--!
--! @returns Dictionary with individual command responses
--]]
function FDCDUT.executeSequence(sequence, parameters)

    local sequence_result = {}

    for _, item in ipairs(sequence) do
        local command = StringUtils.interpolateString(item[1], parameters)
        local expected_resp = item[2]
        local timeout = item[3]
        local name = item[4]

        -- For debugging
        print("Run cmd " .. command)

        local result = FDCDUT.executeTask("/bin/sh", {"-c", command}, timeout)

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

--[[
--! @brief Start a new task, and wait for it to finish.
--! @param command Full path to the command to run (use e.g. /bin/ls instead of ls).
--! @param arguments Array of string arguments that are passed to the task.
--! @param timeout How many seconds to wait for the task to finish
--! @return Dictionary of: {"stderr": "", "stdout": "", "exitcode": 0}.
--]]
function FDCDUT.executeTask(command, arguments, timeout)
    assert(type(command) == "string", "Command must be a string")
    assert(type(timeout) == "number", "Timeout must be a number")
    -- assert(type(arguments) == "table", "Arguments must be a table")
    assert((type(arguments) == "table") or (type(arguments) == "string"), "Arguments must be a table or string")

    local task = FDCDUT.FDC.createRemoteTask(command, arguments)

    local commBuilder
    if Atlas ~= nil then
        commBuilder = Atlas.loadPlugin("CommBuilder")
    else
        commBuilder = require "CommBuilder"
    end

    local stdioChan = commBuilder.createCommPlugin(task.stdioChannel())
    local stderrChan = commBuilder.createCommPlugin(task.stderrChannel())

    task.launch()
    task.waitUntilLaunched()

    local status, retVal = pcall(task.waitUntilExitWithTimeout, timeout)
    local statusStdOut, stdout = pcall(stdioChan.read, 0)
    local statusStdErr, stderr = pcall(stderrChan.read, 0)

    -- If timeout was triggered, status will be false

    local function printErrorMessage(errMsg)
        print("")
        print(errMsg)

        print("Arguments:")
        if (type(arguments) == "table") then
            for _, v in pairs(arguments) do
                print(tostring(v))
            end
        elseif (type(arguments) == "string") then
            print(arguments)
        end

        print("Command status:    " .. tostring(status))
        print("Command Exit Code: " .. tostring(retVal))
        if statusStdOut == true then
            print("Command stdout:    " .. tostring(stdout))
        end

        if statusStdErr == true then
            print("Command stderr:    " .. tostring(stderr))
        end
    end

    if not status then
        FDCDUT.terminateTask(task)
        printErrorMessage("Error: Failed to execute command " .. tostring(command) .. " by timeout: " ..
                              tostring(timeout))

        error("TIMEOUT executing command " .. tostring(command))
    elseif retVal ~= 0 then
        -- Some command has non-zero exit code as expected.
        -- Like "ls" with a nonexistent DIR or FILE. Then we can't call error here.
        printErrorMessage("Execute command " .. tostring(command) .. " with exitcode: " .. tostring(retVal))
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
--! @brief Read DUT's serial number.
--! @return DUT serial number as a string.
--]]
function FDCDUT.readDUTSN()
    return FDCDUT.FDC.readSN()
end

--[[
--! @brief Read the device's model.
--! @return DUT's device model as a string.
--]]
function FDCDUT.readDUTModel()
    return FDCDUT.FDC.readDeviceModel()
end

--[[
--! @brief Read DUT's ECID
--! @return DUT's ECID as a number
--]]
function FDCDUT.readDUTECID()
    return FDCDUT.FDC.readECID()
end

--[[
--! @brief Read value under a key in sysconfig.
--! @param key Key to read.
--! @return Value as a string.
--]]
function FDCDUT.readSysconfigKey(key)
    assert(type(key) == "string", "key must be a string")

    local stat, ret = pcall(FDCDUT.FDC.readSysConfigAsString, key)
    if stat then
        return ret
    elseif string.find(ret, "stored as __NSCFData") ~= nil then
        stat, ret = pcall(FDCDUT.FDC.readSysConfigAsData, key)
        if stat then
            local valstr = tostring(ret)
            -- Need to make sure 2 to -2 is the correct range
            valstr = string.sub(valstr, 2, -2)
            return valstr
        end
    end

    error("Failed read SysConfig key with the KEY: " .. key)
end

function FDCDUT.readSysconfigKeyAsData(key)
    assert(type(key) == "string", "key must be a string")

    return FDCDUT.FDC.readSysConfigAsData(key)
end

--[[
--! @brief Write key, value pair into sysconfig.
--! @param key Key to write/update.
--! @param value Value for the key. Can be a string or an NSData object
--]]
function FDCDUT.writeSysconfigKeyValue(key, value)
    assert(type(key) == "string", "key must be a string")

    return FDCDUT.FDC.writeSysConfig(key, value)
end

--[[
--! @brief Delete key, value pair from sysconfig.
--! @param key Key to delete.
--]]
function FDCDUT.deleteSysConfigKey(key)
    assert(type(key) == "string", "key must be a string")

    return FDCDUT.FDC.deleteSysConfigKey(key)
end

--[[
--! This routine expects that it will be used after the DUT is detected with FDCDUTDetection
--]]
local function getCurrentDeviceUSBLocation()
    local usb_addr

    if Device.transport["USB"] ~= nil then
        usb_addr = string.match(Device.transport["USB"], "usb://(.*)")
    else
        usb_addr = string.match(Device.transport, "usb://(.*)")
    end

    print("DUT USB ADDR: " .. usb_addr)

    return usb_addr
end

-- - - - - - -
-- Copy files
-- - - - - - -
-- For copying to and from DUT, we have to depend on tool copyUnrestricted as Copy functionality
-- is not supported in FDCDUT plugin yet.
-- Although FDC framework (used by the plugin) supports it.

--[[
--! @brief Copy a file or directory to DUT.
--! @param src Path to source file or directory in Mac.
--! @param dst Path to destination directory in DUT.
--]]
function FDCDUT.copyToDUT(src, dst)
    local cmd = "/usr/local/bin/copyUnrestricted -w -u " .. getCurrentDeviceUSBLocation() .. " -s " .. src .. " -t " ..
                    dst
    print("copyToDUT: " .. cmd)

    -- TODO: it seems that copyUnrestricted always returns 0 (even if it fails)
    SystemUtils.RunCommandAndCheck(cmd)
end

--[[
--! @brief Copy a file or directory from DUT.
--! @param src Path to source file or directory in DUT.
--! @param dst Path to destination directory in Mac.
--]]
function FDCDUT.copyFromDUT(src, dst)
    local cmd = "/usr/local/bin/copyUnrestricted -u " .. getCurrentDeviceUSBLocation() .. " -s " .. src .. " -t " .. dst
    print("copyFromDUT: " .. cmd)

    -- TODO: it seems that copyUnrestricted always returns 0 (even if it fails)
    -- If input incorrect USB address, copyUnrestricted will return with exit code as 1
    SystemUtils.RunCommandAndCheck(cmd)
end

-- - - - - - -
-- Create/remove dirs / file
-- - - - - - -

--[[
--! @brief Create a directory in DUT (also create sub-directories if needed).
--! @param path Path to the directory to create in DUT.
--! @return Dictionary of: {"stderr": "", "stdout": "", "exitcode": 0}
--]]
function FDCDUT.createDir(path)
    return FDCDUT.executeTask("/bin/mkdir", {"-p", path}, 1)
end

--[[
--! @brief Remove a directory in DUT.
--! @param path Path to the directory to remove in DUT.
--! @return Dictionary of: {"stderr": "", "stdout": "", "exitcode": 0}
--]]
function FDCDUT.removeDir(path)
    return FDCDUT.executeTask("/bin/rm", {"-rf", path}, 1)
end

--[[
--! @brief Remove a file in DUT.
--! @param path Path to the file to remove in DUT.
--! @return Dictionary of: {"stderr": "", "stdout": "", "exitcode": 0}
--]]
function FDCDUT.removeFile(path)
    return FDCDUT.executeTask("/bin/rm", {"-f", path}, 1)
end

function FDCDUT.listDir(path)
    return FDCDUT.executeTask("/bin/ls", {"-l", path}, 1)
end

function FDCDUT.getDutTime()
    return FDCDUT.executeTask("/bin/date", "", 1)
end

--[[
--! @brief Read DUT's unique chip ID (ECID).
--! @return DUT's Chip ID (ECID) as a string.
--]]
function FDCDUT.readUniqueChipID()
    local uid = FDCDUT.FDC.gestaltQuery("UniqueChipID")
    local uidStr = string.format("0x%X", uid)
    return uidStr
end

--[[
--! @brief Read DUT's serial number (SN).
--! @return DUT's serial number (SN) as a string.
--]]
function FDCDUT.readSerialNumber()
    local snStr = FDCDUT.FDC.gestaltQuery("SerialNumber")

    return snStr
end

--[[
--! @brief Read DUT's HW model.
--! @return DUT's HW model as a string.
--]]
function FDCDUT.readHWModel()
    local modelStr = FDCDUT.FDC.gestaltQuery("HWModelStr")

    return modelStr
end

--[[
--! @brief Runs a MobileGestalt query with the DUT for the specified key.
--! @param key The key to query from Gestalt, e.g. "SerialNumber".
--! @return The result for the queried key.
--!         The type of the result is dynamic, based on the queried key.
--]]
function FDCDUT.runGestalQuery(key)
    assert(type(key) == "string", "key must be a string")
    local result

    print("")
    print("Run Gestalt Query with the Key: " .. key)

    result = FDCDUT.FDC.gestaltQuery(key)

    return result
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

createPascalCaseAliases(FDCDUT)
return FDCDUT

--[[
--! @}
--]]
