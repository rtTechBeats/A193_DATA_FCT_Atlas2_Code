---------------------------------------------
----*****************************************
--   ____   _____  _      _  _
--  |  _ \ |_   _|| |    (_)| |__
--  | |_) |  | |  | |    | || '_ \
--  |  _ <   | |  | |___ | || |_) |
--  |_| \_\  |_|  |_____||_||_.__/
--
-- v1.0 - Zcnwei 2025/06/06
---------------------------------------------
----*****************************************

local RTCommonLib = {}

if Device ~= nil and Device.loadPlugin then
    RTCommonLib.plugin = Device.loadPlugin("RTCommonLib")
    RTCommonLib.utils = Device.loadPlugin("Utilities")
elseif Atlas ~= nil and Atlas.loadPlugin then
    RTCommonLib.plugin = Atlas.loadPlugin("RTCommonLib")
    RTCommonLib.utils = Atlas.loadPlugin("Utilities")
else
    error("It must be run in the Atlas platform or the AtlasGroupProcess coreless")
end

---------------------------------------------
--- @Time Wrapper Functions
---------------------------------------------

--- @brief Sleeps for a given duration in seconds
--- @param seconds a positive integer
function RTCommonLib.sleep(seconds)
    return RTCommonLib.plugin.sleep(tonumber(seconds))
end

--- @brief Sleeps for a given duration in microseconds
--- @param useconds Sleep duration in microsecond
function RTCommonLib.usleep(useconds)
    return RTCommonLib.plugin.usleep(tonumber(useconds))
end

--- @brief Gives an accurate value of the system clock in seconds
--- @return returns the timestemp with number type
function RTCommonLib.time()
    return RTCommonLib.plugin.time()
end

--- @brief Convert string time to timestamp since 1970
--- @param timeStr (e.g. "2025/08/26 11:33:31.037")
--- @param formatStr yyyy/MM/dd HH:mm:ss.SSS
--- @return returns the timestemp with number type
function RTCommonLib.timestampFromString(timeStr, formatStr)
    return RTCommonLib.plugin.timestampFromString(timeStr, formatStr or "yyyy/MM/dd HH:mm:ss.SSS")
end

--- @brief Start record timestemp with Identifier
--- @param identifier unique id with string type
function RTCommonLib.tickWithIdentifier(identifier)
    return RTCommonLib.plugin.tickWithIdentifier(identifier)
end

--- @brief Stop record timestemp with Identifier
--- @param identifier unique id with string type
--- @return returns the record time of the identifier
function RTCommonLib.tockWithIdentifier(identifier)
    return RTCommonLib.plugin.tockWithIdentifier(identifier)
end

---------------------------------------------
--- @RunShellCommand Wrapper Functions
---------------------------------------------

--- @brief Convert a hex string to a raw data string
--- @param cmd lua string with shell command
--- @param timeout lua number with timeout
--- @return returns a lua table e.g {output=..., error=..., returnCode=...}
function RTCommonLib.runShellCmd(cmd, timeout)
    local retTab
    if tonumber(timeout) ~= nil then
        retTab = RTCommonLib.plugin.runShellCmd(tostring(cmd), tonumber(timeout))
    else
        retTab = RTCommonLib.plugin.runShellCmd(tostring(cmd))
    end
    return retTab
end

---------------------------------------------
--- @PathOperation Wrapper Functions
---------------------------------------------

--- @brief Check if a path exists on the local filesystem
--- @param path directory/file path
--- @return returns true if there is a directory/file exists, otherwise false
function RTCommonLib.path_exists(path)
    return RTCommonLib.plugin.pathExists(path)
end

--- @brief Check if path is file on the local filesystem
--- @param path file path
--- @return returns true if there is a file at that path, otherwise false
function RTCommonLib.path_isfile(path)
    return RTCommonLib.plugin.pathIsFile(path)
end

--- @brief Check if a path is directory on the local filesystem
--- @param path directory path
--- @return returns true if there is a directory at that path, otherwise false
function RTCommonLib.path_isdir(path)
    return RTCommonLib.plugin.pathIsDir(path)
end

--- @brief Check file or directory size
--- @param path directory/file path
--- @return return file or directory size with number type
function RTCommonLib.path_size(path)
    return RTCommonLib.plugin.pathSize(path)
end

--- @brief Creates a path by joining the path elements with the local path delimiter
--- @param firstPath first path
--- @param ... variable arguments of path components
--- @return return the full path
function RTCommonLib.path_join(firstPath, ...)
    local comsTab = {}
    for _, value in ipairs({...}) do
        table.insert(comsTab, tostring(value))
    end
    return RTCommonLib.plugin.pathJoin(tostring(firstPath), comsTab)
end

--- @brief Gets the last path component in a given path
--- @param path Path to truncate
--- @return returns the last path component
function RTCommonLib.path_filename(path)
    return RTCommonLib.plugin.pathFileName(path)
end

--- @brief Gets the extension of the file in a path
--- @param path Path to truncate
--- @return returns the extension
function RTCommonLib.path_extension(path)
    return RTCommonLib.plugin.pathExtension(path)
end

--- @brief List the files in a given directory
--- @param path directory path
--- @return returns an array of paths relative to the input path
function RTCommonLib.path_listdir(path)
    return RTCommonLib.plugin.listDir(path)
end

--- @brief Creates a directory in the local filesystem
--- @param path Path of the directory to create
function RTCommonLib.path_makedir(path)
    return RTCommonLib.plugin.makeDir(path)
end

--- @brief Deletes the file at a given path
--- @param path directory/file path
function RTCommonLib.path_remove(path)
    return RTCommonLib.plugin.removePath(path)
end

--- @brief Copy a file or directory to a new location
--- @param src Path to copy
--- @param dst Destination path
function RTCommonLib.path_copy(src, dst)
    return RTCommonLib.plugin.copyPath(src, dst)
end

---------------------------------------------
--- @DataOperation Wrapper Functions
---------------------------------------------

--- @brief Convert a hex string to a raw data string
--- @param hex Hex-encoded data
--- @return returns a lua string containing the raw bytes
function RTCommonLib.hex2bytes(hex)
    local retval =  hex:gsub("(%w%w)", function(s) return string.char(tonumber(s,16)) end)
    if #hex ~= (2 * #retval) then error("Input was not a hex string") end
    return retval
end

--- @brief Convert a raw data string to hex
--- @param bytes Lua string containing binary data
--- @return returns hex-encoded data as a lua string
function RTCommonLib.bytes2hex(bytes)
    return bytes:gsub(".", function(c) return string.format("%02X", c:byte()) end)
end

--- @brief Convert a hex-encoded data to an NSData instance
--- @param hex Hex-encoded data string
--- @return returns data as an NSData instance
function RTCommonLib.hex2nsdata(hex)
    return RTCommonLib.utils.dataFromHexString(hex)
end

--- @brief Convert an NSData instance to a hex string
--- @param nsdata An NSData instance
--- @return returns hex-encoded data as a lua string
function RTCommonLib.nsdata2hex(nsdata)
    return RTCommonLib.utils.dataToHexString(nsdata)
end

--- @brief Convert a raw data string to an NSData instance
--- @param bytes Lua string containing binary data
--- @return returns data as an NSData instance
function RTCommonLib.bytes2nsdata(bytes)
    return RTCommonLib.hex2nsdata(RTCommonLib.bytes2hex(bytes))
end

--- @brief Convert an NSData instance to a raw data string
--- @param nsdata An NSData instance
--- @return returns a lua string containing the raw bytes
function RTCommonLib.nsdata2bytes(nsdata)
    return RTCommonLib.hex2bytes(RTCommonLib.nsdata2hex(nsdata))
end

--- @brief convert hex data to string
--- @param hexstring hex string
--- @return returns a lua string containing the hex to ascii
function RTCommonLib.hex2ascii(hexstring)
    -- check hexstring type
    if type(hexstring) ~= "string" then
        return false
    end
    -- format hex string
    hexstring = string.gsub(hexstring, " ", "")
    hexstring = string.gsub(hexstring, "<", "")
    hexstring = string.gsub(hexstring, ">", "")

    -- make sure hexstring is pair
    local retStr = ""
    if #hexstring % 2 ~= 0 then
        return false
    else
        for i = 1, #hexstring, 2 do
            local decVal = tonumber(string.sub(hexstring, i, i + 1), 16)
            -- filter invisible characters and convert hex to string
            if (decVal >= 32 and decVal <= 126) or decVal == 10 or decVal == 13 then
                local charVal = string.char(decVal)
                retStr = retStr .. tostring(charVal)
            end
        end
    end

    return retStr
end

--- @brief convert hex data to string
--- @param ascii ascii string
--- @param upper Optional boolean arguments, if ture return upper string
--- @return returns a lua string containing the ascii to hex
function RTCommonLib.ascii2hex(ascii, upper)
    -- check hexstring type
    if type(ascii) ~= "string" then
        return false
    end

    local hexString = ""
    local hex_patt = upper == true and "%02X" or "%02x"
    for i = 1, #ascii, 1 do
        local charVal = string.sub(ascii, i, i)
        local hexVal = string.format(hex_patt, string.byte(charVal))
        hexString = hexString .. hexVal
    end

    return hexString
end

--- @brief Calculates the hash digest for a given string or NSData instance
--- @param code string type to generate the hash from
--- @param algorithm The hash algorithm table to use (e.g MD5=>1, SHA1=>2, SHA224=>3, SHA256=>4, SHA384=>5, SHA512=>6)
--- @return returns the hash digest as a number
function RTCommonLib.hash(code, algorithm)
    -- make sure Security exists
    if not Security then
        error("It must be run in the Atlas platform or the AtlasGroupProcess coreless")
    end
    -- make sure algorithm in hash table
    hashTab = {
        MD5=1, SHA1=2, SHA224=3, SHA256=4, SHA384=5, SHA512=6
    }
    hashCode = hashTab[string.upper(algorithm)]
    if not hashCode then
        error(("%s not in Hash Table:MD5, SHA1, SHA224, SHA256, SHA384, SHA512"):format(string.upper(algorithm)))
    end
    -- convert to a hex string
    local hexstring = ""
    for _, c in utf8.codes(code) do
        hexstring = hexstring .. string.format("%02X", c)
    end
    -- generate the hex string
    local hexdata = RTCommonLib.utils.dataFromHexString(hexstring)
    local digest = Security.generateDigest(hexdata, hashCode)
    local hashStr = RTCommonLib.utils.dataToHexString(digest)
    return hashStr
end

--- @brief Encodes an lua string to NSData instance
--- @param str An lua string to encode
--- @return returns the NSData instance
function RTCommonLib.data_encode(str)
    return RTCommonLib.plugin.dataEncode(tostring(str))
end

--- @brief Encodes an NSData instance as a lua string
--- @param nsdata An NSData instance to encode
--- @return returns the lua string
function RTCommonLib.data_decode(nsdata)
    return RTCommonLib.plugin.dataDecode(nsdata)
end

--- @brief Encodes an NSData instance as a Base64 string
--- @param nsdata An NSData instance to encode
--- @return returns the Base64 string
function RTCommonLib.base64_encode(nsdata)
    return RTCommonLib.plugin.dataBase64Encode(nsdata)
end

--- @brief Decodes a Base64 string to an NSData instance
--- @param base64 The Base64 string
--- @return returns the deocded data as an NSData instance
function RTCommonLib.base64_decode(base64)
    return RTCommonLib.plugin.dataBase64Decode(base64)
end

---------------------------------------------
--- @UUID Wrapper Functions
---------------------------------------------

--- @brief generate UUID
--- @return returns a lua string e.g => 025501ED-4C63-476B-A162-CD5BC38499F7
function RTCommonLib.uuid()
    return RTCommonLib.plugin.generateUUID()
end

--- @brief generate UUID hex string
--- @return returns a lua string e.g => ee7253cea18740e9b135f908d9012e02
function RTCommonLib.uuid_hex()
    return RTCommonLib.plugin.generateUUIDHexString()
end

---------------------------------------------
--- @JSON Wrapper Functions
---------------------------------------------

--- @brief Converts a lua table to JSON data and writes it to a file
--- @param tab Lua table to encode nsdata
--- @param filePath Optional arguments, write data to file path
--- @return returns the json encode data as an NSData instance
function RTCommonLib.json_encode(tab, filePath)
    local data = RTCommonLib.plugin.jsonEncode(tab)
    if filePath ~= nil then
        RTCommonLib.utils.writeDataToFile(filePath, data)
    end
    return data
end

RTCommonLib.json_encodeToFile = RTCommonLib.json_encode

--- @brief Converts JSON data from a file or NSData instance into a lua table
--- @param path_or_data_or_string Path to JSON file or NSData instance or json string
--- @return returns a lua table with the JSON data
function RTCommonLib.json_decode(path_or_data_or_string)
    return RTCommonLib.plugin.jsonDecode(path_or_data_or_string)
end

RTCommonLib.json_decodeFromData = RTCommonLib.json_decode
RTCommonLib.json_decodeFromFile = RTCommonLib.json_decode
RTCommonLib.json_decodeFromString = RTCommonLib.json_decode

---------------------------------------------
--- @PLIST Wrapper Functions
---------------------------------------------

--- @brief Converts a lua table to Plist data and writes it to a file
--- @param tab Lua table to encode nsdata
--- @param filePath Optional arguments, write data to file path
--- @return returns the plist encode data as an NSData instance
function RTCommonLib.plist_encode(tab, filePath)
    local data = RTCommonLib.plugin.plistEncode(tab)
    if filePath ~= nil then
        RTCommonLib.utils.writeDataToFile(filePath, data)
    end
    return data
end

RTCommonLib.plist_encodeToFile = RTCommonLib.plist_encode

--- @brief Converts Plist data from a file or NSData instance into a lua table
--- @param path_or_data_or_string Path to Plist file or NSData instance or Plist string
--- @return returns a lua table with the Plist data
function RTCommonLib.plist_decode(path_or_data_or_string)
    return RTCommonLib.plugin.plistDecode(path_or_data_or_string)
end

RTCommonLib.plist_decodeFromData = RTCommonLib.plist_decode
RTCommonLib.plist_decodeFromFile = RTCommonLib.plist_decode
RTCommonLib.plist_decodeFromString = RTCommonLib.plist_decode

---------------------------------------------
--- @USB Utility Functions
---------------------------------------------

--- @brief get system USB device information
--- @return returns a lua table e.g => array<dictionary>
function RTCommonLib.getUSBDeviceTree()
    return RTCommonLib.plugin.getUSBDeviceTree()
end

--- @brief get USB device information from location id
--- @param locationID lua number type (e.g 0x12345678)
--- @return returns a lua table e.g => array<dictionary>
function RTCommonLib.getUSBDeviceFromLocationID(locationID)
    local retTab = RTCommonLib.plugin.getUSBDeviceTree()
    local targetTab = {}
    for _, subDevice in pairs(retTab) do
        if type(subDevice) == "table" and subDevice["locationID"] == locationID then
            targetTab = subDevice
        end
    end
    return targetTab
end

--- @brief get USB device information from SerialNumber
--- @param serialNumber lua string type (e.g ABCDEFGHIJK...)
--- @return returns a lua table e.g => array<dictionary>
function RTCommonLib.getUSBDeviceFromSerialNumber(serialNumber)
    local retTab = RTCommonLib.plugin.getUSBDeviceTree()
    local targetTab = {}
    for _, subDevice in pairs(retTab) do
        if type(subDevice) == "table" and subDevice["serialNumber"] == serialNumber then
            targetTab = subDevice
        end
    end
    return targetTab
end

--- @brief get USB device information from vendor id
--- @param vendorID lua number type (e.g 0x12345678)
--- @return returns a lua table e.g => array<dictionary>
function RTCommonLib.getUSBDeviceFromVendorID(vendorID)
    local retTab = RTCommonLib.plugin.getUSBDeviceTree()
    local targetTab = {}
    for _, subDevice in pairs(retTab) do
        if type(subDevice) == "table" and subDevice["vendorID"] == vendorID then
            targetTab = subDevice
        end
    end
    return targetTab
end

--- @brief get USB device information from vendor id
--- @param productID lua number type (e.g 0x12345678)
--- @return returns a lua table e.g => array<dictionary>
function RTCommonLib.getUSBDeviceFromProductID(productID)
    local retTab = RTCommonLib.plugin.getUSBDeviceTree()
    local targetTab = {}
    for _, subDevice in pairs(retTab) do
        if type(subDevice) == "table" and subDevice["productID"] == productID then
            targetTab = subDevice
        end
    end
    return targetTab
end

--- @brief get USB device information from vendor id
--- @param locationID lua number type (e.g 0x12345678)
--- @return returns a lua string e.g => /dev/cu.usbserial-xxxx
function RTCommonLib.getDevicePortFromLocationID(locationID)
    local retTab = RTCommonLib.plugin.getUSBDeviceTree()
    local targetPort = nil
    for _, subDevice in pairs(retTab) do
        if type(subDevice) == "table" and subDevice["locationID"] == locationID then
            targetPort = subDevice["devicePath"]
        end
    end
    return targetPort
end

---------------------------------------------
--- @NSTask Plugin Wrapper Functions
---------------------------------------------

--- @brief Creates an Atlas2 plugin instance that can be used to control an ongoing NSTask
--- @param launch_path The system command to run (e.g /bin/bash)
--- @param args Array of arguments to pass to the command
--- @param curdir The directory in which to launch the task
--- @return returns an Altas2 plugin, call runUntilExit() to execute
--- e.g:
--- => task = RTCommonLib.create_task("/bin/sh", {"-c", "ls /dev/cu.*"}, "~/")
--- => task.launch()                         -- run shell command
--- => task.isRunning()                      -- return task current status
--- => task.writeStdIn("echo Hello World!")  -- write string to standard input pipe
--- => task.readStdOut()                     -- read string from standard output pipe
--- => task.readStdErr()                     -- read string from standard error pipe
--- => task.runUntilExit(10)/runUntilExit()  -- run and wait task execute finish with 10 seconds or 3600 seconds
--- => task.terminate()                      -- manual terminate task
---
function RTCommonLib.create_task(launch_path, args, curdir)
    -- Convert all arguments to string
    local strArgs = {}
    if args then
        for _, arg in ipairs(args) do
            table.insert(strArgs, tostring(arg))
        end
    end

    if next(strArgs) ~= nil and curdir ~= nil then
        return RTCommonLib.plugin.createTask(launch_path, strArgs, curdir)
    elseif next(strArgs) ~= nil then
        return RTCommonLib.plugin.createTask(launch_path, strArgs)
    else
        return RTCommonLib.plugin.createTask(launch_path)
    end
end

---------------------------------------------
--- @PTY Plugin Wrapper Functions
---------------------------------------------

--- @brief Creates an Atlas2 plugin instance that can be used to control an ongoing Virtual PTY
--- @param shell_cmd The system command to run (e.g ls /dev/cu.*)
--- @return returns an Altas2 plugin, call runUntilExit() to execute
--- e.g:
--- => task = RTCommonLib.create_pty("/bin/bash")
--- => task.launch()                         -- run shell command
--- => task.write("echo Hello World!")       -- write string to standard input pipe
--- => task.read()/read(1)                   -- read string from standard output pipe immediate or 1 seconds
--- => task.runUntilExit(10)/runUntilExit()  -- run and wait task execute finish with 10 seconds or 3600 seconds
--- => task.terminate()                      -- manual terminate task
---
function RTCommonLib.create_pty(shell_cmd)
    return RTCommonLib.plugin.createPTY(shell_cmd)
end

---------------------------------------------
--- @UART Plugin Wrapper Functions
---------------------------------------------

--- @brief Creates an Atlas2 plugin instance that can be used to control an ongoing PTY
--- @param port uart port name (e.g /dev/cu.debug-console)
--- @param baud_rate uart baud rate (e.g 115200, 230400, 460800, 921600...)
--- @param log_path Optional (e.g ls /tmp/uart.log)
--- @return returns an Altas2 plugin
--- e.g:
--- => uart = RTCommonLib.create_uart("/dev/cu.debug-console", 115200, "/tmp/uart.log")
--- => uart.open()                                         -- open uart 
--- => uart.isOpen()                                       -- check uart is open
--- => uart.setLogFilePath("/tmp/fixture.log")             -- set log file path
--- => uart.setTerminator("\r\n")                          -- set default terminator string
--- => uart.send(str_cmd, timeout, terminator(optional))   -- send command to uart and read with timeout, terminator
--- => uart.write(str_cmd)                                 -- write String command to uart
--- => uart.writeData(nsdata_cmd)                          -- write NSData command to uart
--- => uart.read(timeout(optional), terminator(optional))  -- read with with timeout, terminator, return string
--- => uart.readData(timeout(optional))                    -- read with timeout, return NSData instance
--- => uart.close()                                        -- close uart
---
function RTCommonLib.create_uart(port, baud_rate, log_path)
    if log_path ~= nil then
        return RTCommonLib.plugin.createUART(port, tonumber(baud_rate), log_path)
    else
        return RTCommonLib.plugin.createUART(port, tonumber(baud_rate))
    end
end

---------------------------------------------
--- @Lua_Table Functions
---------------------------------------------

--- @brief Check if a key exists in a table
--- @param tab Table to check
--- @param key Key to find
--- @return returns true if that key is in the table
function RTCommonLib.table_haskey(tab, key)
  for tabkey, value in pairs(tab) do
      if tabkey == key then
          return true
      end
  end

  return false
end

--- @brief Check if a value exists in a table
--- @param tab Table to check
--- @param val Value to find
--- @return returns true if that value is in the table
function RTCommonLib.table_hasval(tab, val)
  for key, value in pairs(tab) do
      if value == val then
          return true
      end
  end

  return false
end

--- @brief Get all keys for a given table
--- @param tab Table to check
--- @return returns all the keys in the table as an array
function RTCommonLib.table_keys(tab)
    local keys = {}
    for k,v in pairs(tab) do
        table.insert(keys, k)
    end
    return keys
end

--- @brief Get all values for a given table
--- @param tab Table to check
--- @return returns all the keys in the table as an array
function RTCommonLib.table_values(tab)
    local values = {}
    for k,v in pairs(tab) do
        table.insert(values, k)
    end
    return values
end

--- @brief Calculates the sum of all numeric values in a table
--- @param tab Table to sum
--- @return returns the sum as a number
function RTCommonLib.table_sum(tab)
    local result = 0
    for _,v in pairs(tab) do
        result = result + tonumber(v)
    end
    return result
end

--- @brief method for calculate average of a array table
--- @return: number(if wrong return false)
function RTCommonLib.table_average(dataTable)
    local len = #dataTable
    if len == 0 then
        return false
    end

    local sum = 0
    for _, v in pairs(dataTable) do
        sum = sum + tonumber(v)
    end

    return sum / len
end

--- @brief method for calculate median of a array table
--- @return: number(if wrong return false)
function RTCommonLib.table_median(dataTable)
    local len = #dataTable
    if len == 0 then
        return false
    end

    table.sort(dataTable)
    local medianTab = RTCommonLib.table_slice(dataTable, math.ceil(#dataTable * 0.2), math.floor(#dataTable * 0.8))

    local sum = 0
    for _, v in pairs(medianTab) do
        sum = sum + tonumber(v)
    end

    return sum / #medianTab
end

-- !@brief method for calculate std of a array table
-- !@return number(if wrong return false)
function RTCommonLib.table_std(dataTable)
    local len = #dataTable
    if len == 0 then
        return false
    end
    local sum = 0
    for _, v in pairs(dataTable) do
        sum = sum + v
    end

    local avg = sum / len
    local sum2 = 0
    for _, v in pairs(dataTable) do
        sum2 = sum2 + (v - avg)^2
    end

    return math.sqrt(sum2 / len)
end

--- @brief Merges two tables
--- @param x first Table
--- @param y second Table
--- @return returns the combined tables as a new table
function RTCommonLib.table_merge(x, y)
    local newTab = x
    for k,v in pairs(y) do
        if newTab[k] == nil then
            newTab[k] = v
        end
    end
    return newTab
end

--- @brief Slice table from start index to end index
--- @param tab original table
--- @param start_index start index of slice table
--- @param end_index end index of slice table
--- @param step step of slice table
--- @returns sub table
function RTCommonLib.table_slice(tab, start_index, end_index, step)
    assert(type(tab) == "table", "tab is not a table")
    local newTab = {}
    for i = start_index or 1, end_index or #tab, step or 1 do
        newTab[#newTab + 1] = tab[i]
    end
    return newTab
end

--- @brief Reverse table
--- @param tab: need reverse table
--- @returns {"a","b","c"} => {"c","b","a"}
function RTCommonLib.table_reverse(tab)
    assert(type(tab) == "table", "tab is not a table")
    local newTab = {}
    for i = #tab, 1, -1 do
        newTab[#newTab + 1] = tab[i]
    end
    return newTab
end

--- @brief concatenate array table
--- @details concat two table as one table
--- @param table A and B are the source
--- @returns sum table
function RTCommonLib.array_concat(tableA, tableB)
    assert(type(tableA) == "table", "tableA is not a table")
    assert(type(tableB) == "table", "tableB is not a table")
    local newTable = tableA
    local length = #tableA
    for index, value in ipairs(tableB) do
        newTable[length+index] = value
    end
    return newTable
end

--- @brief concatenate dict table
--- @details concat two table as one table
--- @param table A and B are the source
--- @returns sum table
function RTCommonLib.table_concat(tableA, tableB)
    assert(type(tableA) == "table", "tableA is not a table")
    assert(type(tableB) == "table", "tableB is not a table")
    local newTable = tableA
    for key, value in pairs(tableB) do
        newTable[key] = value
    end
    return newTable
end

--- @brief if 2 object are the same, support table recursively value compare
--- @param t1: a table to compare
--- @param t2: a table to compare against t1.
--- @return boolean type, true if t1 == t2 else false
function RTCommonLib.table_compare(t1, t2)
    local type1 = type(t1)
    local type2 = type(t2)
    if type1 ~= type2 then return false end
    if type(t1) ~= 'table' and type(t2) ~= 'table' then return t1 == t2 end

    -- keys that has been compared
    local compared = {}
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not RTCommonLib.table_compare(v1, v2) then return false end
        compared[k1] = true
    end

    for k2 in pairs(t2) do
        if not compared[k2] then return false end
    end
    return true
end

--- @brief if 2 object are the same, support array table
--- @param t1: a table to compare
--- @param t2: a table to compare against t1.
--- @return boolean type, true if t1 == t2 else false
function RTCommonLib.array_compare(t1, t2)
    local i = 1
    while true do
        if t1[i] == nil and t2[i] == nil then
            return true
        end
        if t1[i] ~= t2[i] then
            return false, i
        end
        i = i + 1
    end
end

---------------------------------------------
--- @Lua_String Functions
---------------------------------------------

--- @brief Converts a given object to a string, expanding table values
--- @param x Value to convert
--- @param sep (Optional) Separator used between table values
--- @return returns a string represeting the object
function RTCommonLib.dump(x, sep)
    sep = sep or ","
    if type(x) == "table" then
        local s = '{ '
        for k,v in pairs(x) do
           if type(k) ~= 'number' then k = '"'..k..'"' end
           s = s .. '['..k..'] = ' .. RTCommonLib.dump(v) .. sep
        end
        return s .. '} '
     else
        return tostring(x)
     end
end

--- @brief Splits a string using a given delimieter
--- @param str String to split
--- @param delimiter Delimiter to split along
--- @return returns the split string as an array
function RTCommonLib.string_split(str, delimiter)
    local tokens = {}
    for x in string.gmatch(str, "[^" .. delimiter .. "]+") do
        table.insert(tokens, x)
    end

    return tokens
end

--- @brief trim str spaces at begin and end
--- @param str: input string
--- @return string after trimmed
--- e.g. trim(" a == b  ") => "a == b"
function RTCommonLib.string_trim(str)
    if not str then
        return nil
    else
        return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
    end
end

---------------------------------------------
--- @Lua_Specifical Functions
---------------------------------------------

--- @brief Copy a table, using values that are only in the top-level
--- @param orig Original table
--- @return returns a copy of the original table, but any child tables are the same instances
function RTCommonLib.shallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--- @brief Recursively copy a table ensuring all children tables are unqiue
--- @param orig Original table
--- @return returns a complete copy of the original table with no shared instances
function RTCommonLib.deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[RTCommonLib.deepCopy(orig_key)] = RTCommonLib.deepCopy(orig_value)
        end
        setmetatable(copy, RTCommonLib.deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--- @brief Convert value from one unit to another.
--- @param value [float] number to convert
--- @param from_units [string] units to convert from (e.g. mV).
--- @param to_units [string] units to convert to (e.g. V).
--- @return: float, number converted from from_units -> to_units.
--- @Examples: 3.23 A --> 3230 mA, value = Conmmon.convertUnits(3.23, "A", "mA")
function RTCommonLib.convertUnit(value, from_units, to_units)
    local unit_exponents = {
        LENGTH = {NM = -9, UM = -6, MM = -3, CM = -2, M = 0},
        VOLTAGE = {NV = -9, UV = -6, MV = -3, V = 0},
        CURRENT = {NA = -9, UA = -6, MA = -3, A = 0},
        POWER = {UW = -6, MW = -3, W = 0},
        FREQUENCY = {HZ = 0, KHZ = 3, MHZ = 6, GHZ = 9},
        RESISTANCE = {MOHM = -3, OHM = 0, KOHM = 3},
        TIME = {S = 0, MS = -3, US = -6, NS= -9},
        PEAK_VOLTAGE = {VPP = 0, MVPP = -3},
        BYTE = {B = 0, KB = 1, MB = 2, GB = 3, TB = 4}
    }
    if from_units == nil or to_units == nil or tonumber(value) == nil then
        error("Miss some arguments")
    end

    local from_u, to_u = nil, nil
    for _, v in pairs(unit_exponents) do
        from_u = v[string.upper(from_units)]
        to_u = v[string.upper(to_units)]
        if from_u and to_u then
            break
        end
    end

    if from_u == nil or to_u == nil then
        error("Invalid units!")
    end

    local delta_exponent = from_u - to_u
    return tonumber(value) * (10 ^ delta_exponent)
end

--- @brief dump data to csv
--- @param filePath: string type
--- @param dataTab: table type
--- @return boolean type, true/false
function RTCommonLib.dumpToCSV(filePath, dataTab, header)
    local bRet = true
    local contents = header or "Data"

    if type(dataTab) ~= "table" then
        return false
    end

    local csvFD = io.open(filePath, "a+")
    if csvFD ~= nil then
        csvFD:write(contents.."\r\n"..table.concat(dataTab, "\r\n"))
        csvFD:close()
    else
        csvFD = nil
        bRet = false
    end
    
    return bRet
end

--- @brief intercept the long string length at 512 char and replace '[\r\n,]'with' '
--- @param str input string
--- @return string after trimmed
function RTCommonLib.trimValueStr(str)
    local msg = ComFunc.dump(str)
    if (#msg > 512) then
        msg = string.sub(msg, 1, 509) .. '...'
    end
    return string.gsub(msg, '[\r\n,]', ' ')
end

--- @brief calculate expression with lua string e.g "10 * 10"
--- @param expression lua string expression
--- @return expression result with number
function RTCommonLib.calculate(expression)    
    return RTCommonLib.plugin.calculate(tostring(expression))
end

--- @brief Convert decimal number to binary string
--- @param data Decimal number to be converted to binary
--- @return Binary string representation of the decimal number
function RTCommonLib.dec2binary(data)
    local dst = ""
    local remainder, quotient

    if not data then
        return dst
    end
    if not tonumber(data) then
        return dst
    end

    if "string" == type(data) then
        data = tonumber(data)
    end

    while true do
        quotient = math.floor(data / 2)
        remainder = data % 2
        dst = dst .. remainder
        data = quotient
        if 0 == quotient then
            break
        end
    end

    dst = string.reverse(dst)

    if 8 > #dst then
        for _ = 1, 8 - #dst, 1 do
            dst = '0' .. dst
        end
    end
    return dst
end

--- @brief Convert binary string to decimal number
--- @param data Binary string to be converted to decimal
--- @return Decimal representation of the binary string
function RTCommonLib.binary2dec(data)
    local dst = 0
    if not data then
        return dst
    end
    if not tonumber(data) then
        return dst
    end

    if "string" == type(data) then
        data = tostring(tonumber(data))
    end

    if "number" == type(data) then
        data = tostring(data)
    end

    local tmp
    for i = #data, 1, -1 do
        tmp = tonumber(data:sub(-i, -i))
        if 0 ~= tmp then
            for _ = 1, i - 1, 1 do
                tmp = 2 * tmp
            end
        end
        dst = dst + tmp
    end
    return dst
end

--- @brief: dump hex table to binary file
--- @param hexTable: hex data table
--- @param binFilePath: binary file path
--- @return boolean type, true/false
function RTCommonLib.hexTableDumpToBin(hexTable, binFilePath)
    local strChar = ""
    for k,v in pairs(HexTable) do
        strChar = strChar..string.char(v)
    end        
    local file = io.open(binFilePath, "wb")
    file:write(strChar)
    file:close()
    return true
end

--- @brief check host macmini type
--- @return luat string with macmini type
function RTCommonLib.getMacMiniType()
    local retVal
    for i=1, 5, 1 do 
        local fd = io.popen("sysctl hw.model")
        local resp = fd:read("*a")
        fd:close()
        if string.find(resp, "Macmini6,2") then
            retVal = "J50"
        elseif string.find(resp, "Macmini7,1") then
            retVal = "J64"
        elseif string.find(resp, "Macmini8,1") then
            retVal = "J174"
        elseif string.find(resp, "Mac16,10") then
            retVal = "J773"
        else
            retVal = false
            print("resp:" .. tostring(resp))
        end
        if type(retVal) == "string" then
            break
        end
        os.execute("sleep 0.1")
    end
    return retVal
end

--- @brief specific for Beats firmware package check FW MD5 is correct
--- @return boolean type, true/false
function RTCommonLib.checkFirmwarePackage()
    local fwPath = "/Users/gdlocal/RestorePackage/Tools/FirmwarePackage"
    local fwMD5Dir = "/Users/gdlocal/RestorePackage/Tools/MD5Checksum"
    local fwMD5File = fwMD5Dir.."/MD5List_FirmwarePackage.txt"
    local fwMD5Cmd = "find %s -type f -print0 | xargs -0 md5 > %s"
    local slotsDir = {
        slot1 = "/Users/gdlocal/RestorePackage/Tools/slot1",
        slot2 = "/Users/gdlocal/RestorePackage/Tools/slot2",
        slot3 = "/Users/gdlocal/RestorePackage/Tools/slot3",
        slot4 = "/Users/gdlocal/RestorePackage/Tools/slot4"
    }
    --!@ check frimware is exists
    if not RTCommonLib.path_isdir(fwPath) then
        return false, "Firmware package is not exists!"
    end
    --!@ check md5 dir is exists
    if not RTCommonLib.path_isdir(fwMD5Dir) then
        RTCommonLib.path_makedir(fwMD5Dir)
    end
    --!@ clear md5 list, generate new md5 list
    RTCommonLib.path_remove(fwMD5Dir)
    RTCommonLib.runShellCmd(string.format(fwMD5Cmd, fwPath, fwMD5File))

    --!@ check slot dir is exists
    for index, slotDir in pairs(slotsDir) do
        local slotFwDir = slotDir.."/FirmwarePackage"
        local slotMD5Cmd = "find %s -type f -print0 | xargs -0 md5 > %s/MD5List_%s.txt"
        if not RTCommonLib.path_isdir(slotDir) then
            RTCommonLib.path_makedir(slotDir)
        end
        RTCommonLib.runShellCmd(string.format("cp -r -f %s %s", fwPath, slotFwDir))
        print(string.format("cp -r -f %s %s", fwPath, slotFwDir))
        RTCommonLib.runShellCmd(string.format(slotMD5Cmd, slotFwDir, fwMD5Dir, index))
        print(string.format(slotMD5Cmd, slotFwDir, fwMD5Dir, index))
    end
    -- !@ check overall md5 list
    local checkFiles = {
        "/Users/gdlocal/RestorePackage/Tools/MD5Checksum/MD5List_FirmwarePackage.txt",
        "/Users/gdlocal/RestorePackage/Tools/MD5Checksum/MD5List_slot1.txt",
        "/Users/gdlocal/RestorePackage/Tools/MD5Checksum/MD5List_slot2.txt",
        "/Users/gdlocal/RestorePackage/Tools/MD5Checksum/MD5List_slot3.txt",
        "/Users/gdlocal/RestorePackage/Tools/MD5Checksum/MD5List_slot4.txt"
    }
    local checkTab = {{}, {}, {}, {}, {}}
    local pattern = "%/FirmwarePackage%/(.+)%)%s*%=%s*("..string.rep("%w", 32)..")"
    for index, checkFile in pairs(checkFiles) do
        for line in io.lines(checkFile) do
            local key, value = line:match(pattern)
            if line:find("/tools/flashtool/log") or line:find("/tools/logtool/log") or line:find("/read_fusing") then
                goto continue
            elseif key:find("DS_Store") then
                goto continue
            end
            checkTab[index][key] = value
            ::continue::
        end
    end
    local bRet = RTCommonLib.table_compare(checkTab[1], checkTab[2])
    if not bRet then return false, "Check Slot1 Firmware Package Fail" end
    bRet = bRet and RTCommonLib.table_compare(checkTab[1], checkTab[3])
    if not bRet then return false, "Check Slot2 Firmware Package Fail" end
    bRet = bRet and RTCommonLib.table_compare(checkTab[1], checkTab[4])
    if not bRet then return false, "Check Slot3 Firmware Package Fail" end
    bRet = bRet and RTCommonLib.table_compare(checkTab[1], checkTab[5])
    if not bRet then return false, "Check Slot4 Firmware Package Fail" end
    return bRet, "Check Firmware Package Pass"
end


return RTCommonLib
