--[[
--! @defgroup tableutils Table Utilities
--! @{
--!
--! @brief Table manipulation and utility functions for Lua data structures
--!
--! @details This module provides a set of utilities for working with Lua tables,
--! including formatting, merging, searching, validation, and conversion operations.
--! It supports both array-like tables (with numeric indices) and dictionary-like tables
--! (with string keys), as well as nested table structures.
--!
--! **Common Usage Patterns:**
--!
--! ```lua
--! local TableUtils = require "ALE.TableUtils"
--!
--! -- Table formatting and debugging
--! local data = {name = "test", config = {port = 8080, host = "localhost"}}
--! print(TableUtils.stringifyTable(data))  -- Pretty formatted output
--! TableUtils.prettyPrintTable(data)       -- Direct print
--!
--! -- Table merging operations
--! local defaults = {timeout = 30, retries = 3, config = {debug = false}}
--! local overrides = {timeout = 60, config = {debug = true, verbose = true}}
--! local merged = TableUtils.deepMergeTables(defaults, overrides)
--! -- Result: {timeout = 60, retries = 3, config = {debug = true, verbose = true}}
--!
--! -- Array operations
--! local arr1 = {"apple", "banana"}
--! local arr2 = {"cherry", "date"}
--! local combined = TableUtils.mergeArrays(arr1, arr2)
--! -- Result: {"apple", "banana", "cherry", "date"}
--!
--! -- Table validation and searching
--! local hasKey = TableUtils.tableHasKey(data, "name")        -- true
--! local hasValue = TableUtils.arrayHasValue(arr1, "apple")   -- true
--! local isEmpty = TableUtils.isEmpty({})                     -- true
--!
--! -- Key/value extraction
--! local keys = TableUtils.allKeys(data)      -- {"name", "config"}
--! local values = TableUtils.allValues(arr1)  -- {"apple", "banana"}
--!
--! -- Nested table searching
--! local nested = {user = {profile = {name = "John"}}}
--! local name = TableUtils.findFirstValueForKey(nested, "name")  -- "John"
--! ```
--!
--]] local TypeUtils = require "ALE.TypeUtils"

local TableUtils = {version = "1.2.18"}

--[[
--! @brief Convert a table to a formatted string representation
--! @param tab Table to convert (can be nested)
--! @returns String containing formatted table representation
--!
--! @details Creates a human-readable string representation of a table with proper
--! indentation for nested structures. Handles circular references safely and
--! formats different value types appropriately (strings are quoted, etc.).
--!
--! ```lua
--! local data = {name = "test", items = {1, 2, 3}, config = {debug = true}}
--! local str = TableUtils.stringifyTable(data)
--! -- Output includes proper indentation and formatting
--! ```
--]]
function TableUtils.stringifyTable(tab)
    local printTable_cache = {}
    local string_table = {}

    local function sub_printTable(subtab, indent)

        if (printTable_cache[tostring(subtab)]) then
            table.insert(string_table, (indent .. "*" .. tostring(subtab) .. "\n"))
        else
            printTable_cache[tostring(subtab)] = true
            if (type(subtab) == "table") then
                for pos, val in pairs(subtab) do
                    if (type(val) == "table") then
                        table.insert(string_table, indent .. "[" .. pos .. "] => " .. tostring(val) .. " {\n")
                        sub_printTable(val, indent .. string.rep(" ", string.len(pos) + 8))
                        table.insert(string_table, indent .. string.rep(" ", string.len(pos) + 6) .. "}\n")
                    elseif (type(val) == "string") then
                        table.insert(string_table, indent .. "[" .. pos .. '] => "' .. val .. '"' .. "\n")
                    else
                        table.insert(string_table, indent .. "[" .. pos .. '] => ' .. tostring(val) .. "\n")
                    end
                end
            else
                table.insert(string_table, tostring(subtab) .. "\n")
            end
        end
    end

    if (type(tab) == "table") then
        table.insert(string_table, tostring(tab) .. " {\n")
        sub_printTable(tab, "  ")
        table.insert(string_table, "}\n")
    else
        sub_printTable(tab, "  ")
    end

    return table.concat(string_table)
end

--[[
--! @brief Print a table with formatted output to console
--! @param tab Table to print (can be nested)
--!
--! @details Convenience function that prints the formatted table representation
--! directly to the console using the stringifyTable function.
--!
--! ```lua
--! local data = {users = {"alice", "bob"}, count = 2}
--! TableUtils.prettyPrintTable(data)  -- Prints formatted table to console
--! ```
--]]
function TableUtils.prettyPrintTable(tab)
    print(TableUtils.stringifyTable(tab))
end

--[[
--! @brief Check if an array contains a specific value
--! @param tab Array-like table to search
--! @param val Value to search for
--! @returns Boolean indicating whether the value was found
--!
--! @details Performs a linear search through array elements using ipairs.
--! Only checks first-level values, not nested structures.
--!
--! ```lua
--! local fruits = {"apple", "banana", "cherry"}
--! local hasApple = TableUtils.arrayHasValue(fruits, "apple")    -- true
--! local hasGrape = TableUtils.arrayHasValue(fruits, "grape")    -- false
--! ```
--]]
function TableUtils.arrayHasValue(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

--[[
--! @brief Check if a table contains a specific key
--! @param tab Table to search
--! @param val Key to search for
--! @returns Boolean indicating whether the key exists
--!
--! @details Checks for key existence at the first level only.
--! More efficient than iterating through all keys.
--!
--! ```lua
--! local config = {host = "localhost", port = 8080, debug = true}
--! local hasHost = TableUtils.tableHasKey(config, "host")     -- true
--! local hasAuth = TableUtils.tableHasKey(config, "auth")     -- false
--! ```
--]]
function TableUtils.tableHasKey(tab, val)
    return tab[val] ~= nil
end

--[[
--! @brief Merge two array-like tables into a new array
--! @param t1 First array table
--! @param t2 Second array table
--! @returns New table containing all elements from both arrays
--! @throws Error if either parameter is not a table
--!
--! @details Creates a deep copy of the first array and appends all elements
--! from the second array. Original tables are not modified.
--!
--! ```lua
--! local colors1 = {"red", "green"}
--! local colors2 = {"blue", "yellow"}
--! local allColors = TableUtils.mergeArrays(colors1, colors2)
--! -- Result: {"red", "green", "blue", "yellow"}
--! ```
--]]
function TableUtils.mergeArrays(t1, t2)

    TypeUtils.assertType(t1, "table")
    TypeUtils.assertType(t2, "table")

    local t = TypeUtils.DeepCopy(t1)
    for _, v in pairs(t2) do
        table.insert(t, v)
    end

    return t
end

--[[
--! @brief Merge two tables into a new table (shallow merge)
--! @param t1 First table (base)
--! @param t2 Second table (override)
--! @returns New table with keys from both tables, t2 values take precedence
--! @throws Error if either parameter is not a table
--!
--! @details Creates a deep copy of the first table and adds/overwrites keys
--! from the second table. For conflicting keys, values from t2 take precedence.
--! This is a shallow merge - nested tables are not recursively merged.
--!
--! ```lua
--! local defaults = {timeout = 30, host = "localhost", debug = false}
--! local overrides = {timeout = 60, port = 8080}
--! local config = TableUtils.mergeTables(defaults, overrides)
--! -- Result: {timeout = 60, host = "localhost", debug = false, port = 8080}
--! ```
--]]
function TableUtils.mergeTables(t1, t2)

    TypeUtils.assertType(t1, "table")
    TypeUtils.assertType(t2, "table")

    local t = TypeUtils.DeepCopy(t1)
    for k, v in pairs(t2) do
        t[k] = v
    end

    return t
end

--[[
--! @brief Recursively merges two tables (dictionaries) into a new table.
--!
--! @param t1 The base table. Its keys/values form the initial content,
--!             potentially being overwritten by `t2`.
--! @param t2 The table to merge into the base. Its keys/values take
--!             precedence in case of conflicts or trigger recursive merges
--!             for sub-tables.
--! @details Creates a new table containing all keys from the first table (`t1`) and
--!         the second table (`t2`). If a key exists in both tables:
--!         * If both corresponding values are tables, the function recursively merges
--!             the sub-tables. The result of this recursive merge becomes the value
--!             for that key in the final merged table.
--!         * Otherwise (if one or both values are not tables), the value from the
--!             second table (`t2`) overwrites the value from the first table (`t1`)
--!             for that key in the final merged table.
--! <br>
--! Keys unique to `t1` are preserved. Keys unique to `t2` are added.
--! The original input tables (`t1` and `t2`) are not modified.
--!
--! @return table A new table representing the deep merge of `t1` and `t2`.
--!
--! ```lua
--! local defaults = {
--!     config = { host = "localhost", port = 80, retries = 3 },
--!     user = "admin"
--! }
--! local overrides = {
--!     config = { port = 8080, timeout = 5000 },
--!     theme = "dark"
--! }
--!
--! local merged = TableUtils.deepMergeTables(defaults, overrides)
--! -- merged will be:
--! -- {
--! --   config = {
--! --     host = "localhost", -- from defaults
--! --     port = 8080,       -- from overrides (overwritten)
--! --     retries = 3,       -- from defaults
--! --     timeout = 5000     -- from overrides (added)
--! --   },
--! --   user = "admin",      -- from defaults
--! --   theme = "dark"       -- from overrides
--! -- }
--! ```
--]]
function TableUtils.deepMergeTables(t1, t2)
    local result = TypeUtils.deepCopy(t1)
    for k, v2 in pairs(t2) do
        local v1 = result[k]
        if type(v1) == 'table' and type(v2) == 'table' then
            result[k] = TableUtils.deepMergeTables(v1, v2) -- Recurse for tables
        else
            result[k] = v2 -- Otherwise, value from t2 overwrites
        end
    end
    return result
end

--[[
--! @brief Recursively search for the first occurrence of a key in nested tables
--! @param t Table to search (can be nested)
--! @param key Key to search for
--! @returns First value found for the key, or nil if not found
--!
--! @details Performs a depth-first search through the table structure.
--! Returns the first matching value encountered during traversal.
--!
--! ```lua
--! local data = {
--!     user = {profile = {name = "John", age = 30}},
--!     settings = {name = "AppSettings"}
--! }
--! local name = TableUtils.findFirstValueForKey(data, "name")  -- "John"
--! local age = TableUtils.findFirstValueForKey(data, "age")    -- 30
--! local missing = TableUtils.findFirstValueForKey(data, "email")  -- nil
--! ```
--]]
function TableUtils.findFirstValueForKey(t, key)

    if (type(t) == "table") then
        for k, v in pairs(t) do
            if (k == key) then
                return v
            else
                local t_aux = TableUtils.findFirstValueForKey(v, key)
                if t_aux then
                    return t_aux
                end
            end
        end
    end
end

--[[
--! @brief Extract all keys from a table into a new array
--! @param t Table to extract keys from
--! @returns Array containing all keys from the table
--! @throws Error if parameter is not a table
--!
--! @details Creates a new array containing all keys from the input table.
--! Order of keys in the result is not guaranteed.
--!
--! ```lua
--! local config = {host = "localhost", port = 8080, debug = true}
--! local keys = TableUtils.allKeys(config)  -- {"host", "port", "debug"} (order may vary)
--! ```
--]]
function TableUtils.allKeys(t)
    TypeUtils.assertTable(t)

    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

--[[
--! @brief Extract all values from a table into a new array
--! @param t Table to extract values from
--! @returns Array containing all values from the table
--! @throws Error if parameter is not a table
--!
--! @details Creates a new array containing all values from the input table.
--! Order of values in the result is not guaranteed.
--!
--! ```lua
--! local config = {host = "localhost", port = 8080, debug = true}
--! local values = TableUtils.allValues(config)  -- {"localhost", 8080, true} (order may vary)
--! ```
--]]
function TableUtils.allValues(t)
    TypeUtils.assertTable(t)

    local values = {}
    for _, v in pairs(t) do
        table.insert(values, v)
    end
    return values
end

--[[
--! @brief Check if a table is empty (contains no key-value pairs)
--! @param t Table to check
--! @returns Boolean indicating whether the table is empty
--!
--! @details Uses the next() function for efficient empty table detection.
--! Works for both array-like and dictionary-like tables.
--!
--! ```lua
--! local empty = {}
--! local notEmpty = {a = 1}
--! local emptyArray = {}
--! local notEmptyArray = {"item"}
--!
--! TableUtils.isEmpty(empty)         -- true
--! TableUtils.isEmpty(notEmpty)      -- false
--! TableUtils.isEmpty(emptyArray)    -- true
--! TableUtils.isEmpty(notEmptyArray) -- false
--! ```
--]]
function TableUtils.isEmpty(t)
    return next(t) == nil
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

createPascalCaseAliases(TableUtils)
return TableUtils

--[[
--! @}
--]]
