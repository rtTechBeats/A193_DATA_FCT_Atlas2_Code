--[[
--! @defgroup detectionutils Detection Utils
--! @{
--]] local DetectionUtils = {version = "1.2.18"}

--[[
--! @brief Sets up Atlas2 detection system to immediately detect a dummy device
--!        for each group/slot.
--! @param deviceURLPrefix Optional string prefix of the dummy device URL
--! @details The function is useful when test sequence needs to start immediately
--!          without waiting for an actual DUT to be connected (e.g. for Audit sequence)
]]
function DetectionUtils.setupDummyDeviceDetection(deviceURLPrefix)
    deviceURLPrefix = deviceURLPrefix or 'uart://fake-path-'

    for _, group in ipairs(Detection.groups()) do
        for _, device in ipairs(Detection.slots()) do
            Detection.addDevice(deviceURLPrefix .. group .. '-' .. device)
        end
    end

    local routingCallback = function(url)
        local pattern = '([0-9]+)%-(.+)$'
        -- Cut off deviceURLPrefix from the URL, and parse the rest of it
        local group_index, slot = string.match(string.sub(url, #deviceURLPrefix), pattern)
        group_index = tonumber(group_index)
        return slot, group_index
    end
    Detection.setDeviceRoutingCallback(routingCallback)
end

--[[
--! @brief Sets up Atlas2 detection system to immediately detect a dummy resource for each group.
--! @details The function is useful when station is not using any resources.
--! @note This function needs to be used as a workaround until this radar is not addressed:
--!       rdar://71906180 (Update/document getResources() edge case behavior)
]]
function DetectionUtils.setupDummyResourceDetection()
    for _, group in ipairs(Detection.groups()) do
        local resource = group .. '-dummyresource'
        Detection.addResource(resource)
    end

    -- Map the resource to group.
    local resourceRoutingCallback = function(resource)
        local pattern = '([0-9]+)%-(.+)$'
        local group, sth = string.match(resource, pattern)
        return sth, tonumber(group)
    end

    Detection.setExpectedResources({"dummyresource"})
    Detection.setResourceRoutingCallback(resourceRoutingCallback)
end

--[[
    Dispatch map file layout:
    * One line per device
    * Each line is <deviceURL>,<slotIndex>,<groupIndex>

    Example:

    usb://0x14110000,1,1
    usb://0x14410000,2,1
]]
local function loadDispatchMap(filePath)
    local stringUtils = require("ALE.StringUtils")
    local fileUtils = require("ALE.FileUtils")

    local content = fileUtils.readFileAsString(filePath)
    if content == "" then
        -- file is empty
        return {}
    end

    local result = {}
    local lines = stringUtils.Tokenize(content, "\n")
    for _, line in ipairs(lines) do
        local items = stringUtils.Tokenize(stringUtils.TrimWhitespace(line), ",")
        assert(#items == 3, string.format("Can't parse dispatch map file %s line: '%s'", filePath, line))
        local url = items[1]
        assert(result[url] == nil, string.format("Duplicated URL '%s' in dispatch map file %s", url, filePath))
        result[url] = {slot = tonumber(items[2]), group = tonumber(items[3])}
    end
    return result
end

local function saveDispatchMap(dispatchMap, filePath)
    local fileUtils = require("ALE.FileUtils")

    local content = ""
    for url, mapping in pairs(dispatchMap) do
        content = content .. string.format("%s,%d,%d\n", url, mapping.slot, mapping.group)
    end
    fileUtils.writeStringToFile(filePath, content)
end

--[[
--! @brief Sets up Atlas2 device routing callback which will dispatch detected devices according to
--!        persistent dispatch map.
--! @param dispatchMapFilePath Optional path to dispatch mapping file. If not provided, a default path is used.
--! @param staticDetection (optional) Enable static detection, which will manually add all devices using
--!        `Detection.addDevice`
--! @details The function will try to read the dispatch map from a file at either a specified path,
--!     or from the default path.
--!     The following use-cases are then handled for a newly detected device URL:
--!     * URL is mentioned in mapping file: device is routed to group and slot according to the mapping
--!     * URL is not mentioned in mapping file: device is routed to the next available slot.
--!     If dispatch map file does not exist, all detected devices will be assigned groups/slots
--!     in order they are connected. E.g. first device will go to group 1 slot 1, next one to
--!     group 1 slot 2, and so on. Once a device is assigned a new slot, the updated mapping is saved
--!     back to the original mapping file provided, so that at the next run, the same
--!     device will be assigned the same slot again.
--!     Note: The function won't setup any device detectors and will only add devices directly if `staticDetection`
--!           argument is `true`.
--!     Make sure to setup any device detectors prior to calling this function. See example below:
--! @code
--!    local detectionUtils = require ("ALE.DetectionUtils")
--!    local eventDetectors = Atlas.loadPlugin("EventDetectors")
--!    Detection.addDeviceDetector(eventDetectors.createADCDUTDetector())
--!    detectionUtils.setupCachingDeviceDispatch()
--! @endcode
]]
function DetectionUtils.setupCachingDeviceDispatch(dispatchMapFilePath, staticDetection)
    dispatchMapFilePath = dispatchMapFilePath or "/vault/device_dispatch_map.csv"
    local dispatchMap = {}

    local fileUtils = require("ALE.FileUtils")
    -- Make sure the target map file directory is writable
    local folderPath = fileUtils.getDirectoryName(dispatchMapFilePath)
    assert(fileUtils.testFileAccess(folderPath, "w"),
           string.format("'%s' dir is not writable or does not exist", folderPath))

    if fileUtils.fileExists(dispatchMapFilePath) then
        dispatchMap = loadDispatchMap(dispatchMapFilePath)
    end

    -- Build map of available slots - array of [groupIndex][slotIndex]
    -- {{bool, bool, bool}, {bool, bool, bool}}
    local availableSlots = {}
    -- Mark all slots as available
    for _ in ipairs(Detection.groups()) do
        local slots = {}
        for _ in ipairs(Detection.slots()) do
            table.insert(slots, true)
        end
        table.insert(availableSlots, slots)
    end

    -- Mark allocated slots as not available
    for url, mapping in pairs(dispatchMap) do
        assert(mapping.group <= #availableSlots,
               string.format("URL '%s' is mapped to invalid group %d", url, mapping.group))
        assert(mapping.slot <= #availableSlots[mapping.group],
               string.format("URL '%s' is mapped to invalid slot %d", url, mapping.slot))
        assert(availableSlots[mapping.group][mapping.slot] == true,
               string.format("Duplicated mapping for URL '%s' in dispatch mapping", url))
        availableSlots[mapping.group][mapping.slot] = false
        if staticDetection == true then
            Detection.addDevice(url)
        end
    end

    local deviceRoutingCallback = function(device)
        print(string.format("Detected new device '%s'", device))

        local groupIndex = nil
        local slotIndex = nil

        -- Try to find the device in the persistent dispatch map
        if dispatchMap[device] ~= nil then
            groupIndex = dispatchMap[device].group
            slotIndex = dispatchMap[device].slot
            print(string.format("Dispatching device '%s' to group %d slot %d per dispatch mapping", device, groupIndex,
                                slotIndex))
            return Detection.slots()[slotIndex], groupIndex
        end

        -- There's no existing mapping for this device - assign the first available slot
        for i in ipairs(availableSlots) do
            for j in ipairs(availableSlots[i]) do
                if availableSlots[i][j] == true then
                    availableSlots[i][j] = false
                    groupIndex = i
                    slotIndex = j
                    break
                end
            end
            if groupIndex ~= nil then
                break
            end
        end

        assert(groupIndex ~= nil,
               string.format("Unable to find available slot for device '%s'. All slots are already taken", device))

        print(string.format("Dispatching device '%s' group %d slot %d", device, groupIndex, slotIndex))
        dispatchMap[device] = {group = groupIndex, slot = slotIndex}

        saveDispatchMap(dispatchMap, dispatchMapFilePath)
        return Detection.slots()[slotIndex], groupIndex
    end
    Detection.setDeviceRoutingCallback(deviceRoutingCallback)
end

--[[
--! @brief Enumerates available UART devices under `/dev/cu.*` and returns the array of names matching
--!        the name patterns provided.
--! @param uartPatterns Array of strings representing required name matching patterns: e.g. {"usbserial-MLB"}
--! @note The function wont setup any device detectors and not add any devices directly.
--!       It needs to be used along with device detection or statically added devices.
]]
function DetectionUtils.enumerateAvailableUartDevices(uartPatterns)
    local stdoutPath = os.tmpname()
    local cmd = "ls /dev/cu.*"
    local success, _, exitCode = os.execute(cmd .. ' > ' .. stdoutPath)
    assert(success == true,
           string.format("Unable to list UART devices. Command %s failed with status %d", cmd, exitCode))
    local stdoutFile = io.open(stdoutPath)
    local uarts = stdoutFile:read("*all"):gmatch("([^\n]*)\n")
    stdoutFile:close()

    local outputUarts = {}
    for uart in uarts do
        for _, va in ipairs(uartPatterns) do
            if uart:find(va) then
                print(string.format("Found UART device '%s' matching pattern '%s'", uart, va))
                table.insert(outputUarts, "uart://" .. uart)
            end
        end
    end
    return outputUarts
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

createPascalCaseAliases(DetectionUtils)
return DetectionUtils

--[[
--! @}
--]]
