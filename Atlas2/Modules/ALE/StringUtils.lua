--[[
--! @defgroup stringutils String Utilities
--! @{
--!
--! @brief String manipulation and processing utilities for text operations
--!
--! @details This module provides a complete set of utilities for working with strings,
--! including tokenization, pattern matching, trimming, interpolation, validation, and
--! formatting operations. It handles common string processing tasks with robust
--! error handling and special character support.
--!
--! **Common Usage Patterns:**
--!
--! ```lua
--! local StringUtils = require "ALE.StringUtils"
--!
--! -- String tokenization and splitting
--! local csv = "apple,banana,cherry"
--! local fruits = StringUtils.tokenize(csv, ",")
--! -- Result: {"apple", "banana", "cherry"}
--!
--! -- Text extraction between tags
--! local xml = "<name>John Doe</name>"
--! local name = StringUtils.getStringBetweenTags(xml, "<name>", "</name>")
--! -- Result: "John Doe"
--!
--! -- String interpolation with parameters
--! local template = "Hello ${name}, you have ${count} messages"
--! local params = {name = "Alice", count = 5}
--! local message = StringUtils.interpolateString(template, params)
--! -- Result: "Hello Alice, you have 5 messages"
--!
--! -- String validation and testing
--! local filename = "document.pdf"
--! local isPdf = StringUtils.endsWith(filename, ".pdf")     -- true
--! local isDoc = StringUtils.startsWith(filename, "doc")    -- true
--!
--! -- Text cleaning and formatting
--! local messy = "  \n  Hello World  \t  "
--! local clean = StringUtils.trimWhitespace(messy)          -- "Hello World"
--! local compact = StringUtils.removeAllWhiteSpaces(messy)  -- "HelloWorld"
--!
--! -- Text abbreviation for display
--! local longText = "This is a very long string that needs shortening"
--! local short = StringUtils.abbreviateMiddle(longText, 20)
--! -- Result: "This is...ortening"
--!
--! -- Safe pattern replacement
--! local text = "Price: $19.99 (special chars: []*+?)"
--! local safe = StringUtils.escapeSpecialChars("$19.99")
--! local replaced = StringUtils.replaceSubstring(text, safe, "$29.99")
--! ```
--!
--]] local TypeUtils = require "ALE.TypeUtils"
local TableUtils = require "ALE.TableUtils"

local StringUtils = {version = "1.2.18"}

--[[
--! @brief Create an iterator for splitting a string on a delimiter
--! @param str String to split
--! @param delimiter Delimiter to split on
--! @returns Iterator function for string parts
--!
--! @details Internal utility function that creates an iterator for string splitting.
--! Handles delimiter escaping and ensures proper string termination.
--]]
local function gsplit(str, delimiter)
    assert(delimiter)
    if str:sub(-#delimiter) ~= delimiter then
        str = str .. delimiter
    end

    return string.gmatch(str, '(.-)' .. StringUtils.escapeSpecialChars(delimiter))
end

--[[
--! @brief Escape special pattern characters in string for safe use in Lua patterns
--! @param s String containing characters to escape
--! @returns String with special pattern characters escaped
--!
--! @details Escapes Lua pattern special characters: ( ) % . [ ^ $ * + - ?
--! This is essential when using user input in string.gsub or string.find operations
--! to prevent pattern interpretation errors.
--!
--! ```lua
--! local userInput = "Price: $19.99 (special)"
--! local escaped = StringUtils.escapeSpecialChars(userInput)
--! -- Can now safely use 'escaped' in pattern operations
--! ```
--]]
function StringUtils.escapeSpecialChars(s)
    assert(s)
    local MAGIC_CHARS = '[()%%.[^$%]*+%-?]'
    return (s:gsub(MAGIC_CHARS, '%%%1'))
end

--[[
--! @brief Split a string into tokens using a specified delimiter
--! @param str String to tokenize
--! @param delimiter Delimiter to split on
--! @returns Array of string tokens
--!
--! @details Splits the input string at each occurrence of the delimiter.
--! Empty tokens are preserved. Uses safe pattern escaping for the delimiter.
--!
--! ```lua
--! local csv = "apple,banana,cherry"
--! local items = StringUtils.tokenize(csv, ",")
--! -- Result: {"apple", "banana", "cherry"}
--!
--! local path = "/usr/local/bin"
--! local parts = StringUtils.tokenize(path, "/")
--! -- Result: {"", "usr", "local", "bin"}
--! ```
--]]
function StringUtils.tokenize(str, delimiter)
    local ans = {}

    for item in gsplit(str, delimiter) do
        ans[#ans + 1] = item
    end

    return ans
end

--[[
--! @brief Check if a string starts with a specified prefix
--! @param str String to check
--! @param start Prefix to look for
--! @returns Boolean indicating whether string starts with prefix
--!
--! @details Performs exact character matching from the beginning of the string.
--! Case-sensitive comparison.
--!
--! ```lua
--! local filename = "document.pdf"
--! local isDoc = StringUtils.startsWith(filename, "doc")     -- true
--! local isImage = StringUtils.startsWith(filename, "img")   -- false
--! ```
--]]
function StringUtils.startsWith(str, start)
    return str:sub(1, #start) == start
end

--[[
--! @brief Check if a string ends with a specified suffix
--! @param str String to check
--! @param ending Suffix to look for
--! @returns Boolean indicating whether string ends with suffix
--!
--! @details Performs exact character matching from the end of the string.
--! Case-sensitive comparison. Empty suffix always returns true.
--!
--! ```lua
--! local filename = "document.pdf"
--! local isPdf = StringUtils.endsWith(filename, ".pdf")      -- true
--! local isTxt = StringUtils.endsWith(filename, ".txt")      -- false
--! local hasExt = StringUtils.endsWith(filename, "")         -- true
--! ```
--]]
function StringUtils.endsWith(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

--[[
--! @brief Extract text content between two specified tags
--! @param str String to search in
--! @param start_tag Opening tag to find
--! @param end_tag Closing tag to find
--! @returns String content between the tags
--! @throws Error if either tag is not found or no content exists between tags
--!
--! @details Finds the first occurrence of start_tag, then searches for end_tag
--! after that position. Returns the content between them. Tags are escaped
--! for safe pattern matching.
--!
--! ```lua
--! local xml = "<name>John Doe</name>"
--! local name = StringUtils.getStringBetweenTags(xml, "<name>", "</name>")
--! -- Result: "John Doe"
--!
--! local config = "[section]value=123[/section]"
--! local value = StringUtils.getStringBetweenTags(config, "[section]", "[/section]")
--! -- Result: "value=123"
--! ```
--]]
function StringUtils.getStringBetweenTags(str, start_tag, end_tag)
    start_tag = StringUtils.escapeSpecialChars(start_tag)
    end_tag = StringUtils.escapeSpecialChars(end_tag)
    local start_s, start_e = string.find(str, start_tag)
    assert(start_s, "Cannot find start_tag: " .. start_tag .. " from string: " .. str)
    assert(start_e)
    local end_s, end_e = string.find(str, end_tag, start_e + 1)
    assert(end_s, "Cannot find end_tag: " .. end_tag .. " from string: " .. str)
    assert(end_e)
    local ret = str:sub(start_e + 1, end_s - 1)
    assert(ret and (ret ~= ""),
           string.format("Cannot find any characters between tags '%s' and '%s' in '%s'", start_tag, end_tag, str))
    return ret
end

--[[
--! @brief Remove leading and trailing whitespace from a string
--! @param str String to trim
--! @returns String with whitespace removed from both ends
--!
--! @details Removes spaces, tabs, newlines, and other whitespace characters
--! from the beginning and end of the string. Internal whitespace is preserved.
--!
--! ```lua
--! local messy = "  \n  Hello World  \t  "
--! local clean = StringUtils.trimWhitespace(messy)  -- "Hello World"
--! ```
--]]
function StringUtils.trimWhitespace(str)
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end

--[[
--! @brief Remove all whitespace characters from a string
--! @param str String to process
--! @returns String with all whitespace removed
--!
--! @details Removes all whitespace characters (spaces, tabs, newlines, etc.)
--! from anywhere in the string, creating a compact version.
--!
--! ```lua
--! local spaced = " a    b c   "
--! local compact = StringUtils.removeAllWhiteSpaces(spaced)  -- "abc"
--! ```
--]]
function StringUtils.removeAllWhiteSpaces(str)
    return str:gsub("%s+", "")
end

--[[
--! @brief Remove leading and trailing control characters from a string
--! @param str String to trim
--! @returns String with control characters removed from both ends
--!
--! @details Removes non-printable control characters (ASCII 0-31 and 127)
--! from the beginning and end of the string. Internal control characters are preserved.
--!
--! ```lua
--! local withControls = "\na b c\n"
--! local clean = StringUtils.trimControlChars(withControls)  -- "a b c"
--! ```
--]]
function StringUtils.trimControlChars(str)
    return (str:gsub("^%c*(.-)%c*$", "%1"))
end

--[[
--! @brief Abbreviate a string by replacing middle characters with ellipsis
--! @param str String to abbreviate (can be nil)
--! @param maxLength Maximum desired length of result
--! @returns Abbreviated string or original if shorter than maxLength
--!
--! @details If string is longer than maxLength, replaces middle characters
--! with "..." to fit within the specified length. Preserves beginning and end.
--! Returns nil if input is nil.
--!
--! ```lua
--! local long = "This is a very long string"
--! local short = StringUtils.abbreviateMiddle(long, 15)
--! -- Result: "This i...string"
--!
--! local short = "Short"
--! local same = StringUtils.abbreviateMiddle(short, 10)
--! -- Result: "Short" (unchanged)
--! ```
--]]
function StringUtils.abbreviateMiddle(str, maxLength)
    if not str then
        return str
    end

    local middle = "..."

    local strlen = str:len()
    if strlen <= maxLength then
        return str
    end

    if strlen <= maxLength + middle:len() then
        return str:sub(1, maxLength)
    end

    local pos1 = math.floor((maxLength - 3) / 2)
    local pos2 = strlen - pos1
    return str:sub(1, pos1) .. middle .. str:sub(pos2, strlen)
end

--[[
--! @brief Replace all occurrences of a substring with a replacement string
--! @param string Source string where replacement will be performed
--! @param substring Substring to find and replace
--! @param replacement String to replace the substring with
--! @returns String with all occurrences replaced
--! @throws Error if any parameter is not a string
--!
--! @details Performs global replacement of all occurrences of the substring.
--! Uses Lua's string.gsub for pattern-based replacement.
--!
--! ```lua
--! local text = "Hello world, world is great"
--! local result = StringUtils.replaceSubstring(text, "world", "universe")
--! -- Result: "Hello universe, universe is great"
--! ```
--]]
function StringUtils.replaceSubstring(string, substring, replacement)
    TypeUtils.assertString(string)
    TypeUtils.assertString(substring)
    TypeUtils.assertString(replacement)
    return (string:gsub(substring, replacement))
end

--[[
--! @brief Interpolate string by replacing parameter placeholders with actual values
--! @param str Input string containing ${param_name} placeholders
--! @param params Table with key-value pairs for parameter substitution
--! @returns String with placeholders replaced by parameter values
--! @throws Error if a placeholder parameter is not found in params table
--!
--! @details Replaces all occurrences of ${param_name} with corresponding values
--! from the params table. Placeholder names must match table keys exactly.
--! All placeholders must have corresponding parameters.
--!
--! ```lua
--! local template = "Hello ${name}, you have ${count} messages"
--! local params = {name = "Alice", count = 5}
--! local message = StringUtils.interpolateString(template, params)
--! -- Result: "Hello Alice, you have 5 messages"
--!
--! local sql = "SELECT * FROM ${table} WHERE id = ${id}"
--! local query = StringUtils.interpolateString(sql, {table = "users", id = 123})
--! -- Result: "SELECT * FROM users WHERE id = 123"
--! ```
--]]
function StringUtils.interpolateString(str, params)
    local function interpolate(paramCapture)
        local paramName = paramCapture:sub(2, -2)
        local param = params[paramName]
        if next(params) ~= nil then
            local errorMsg = ('param "%s" not found for string %s in %s'):format(paramName, str,
                                                                                 TableUtils.stringifyTable(params))
            assert(param ~= nil, errorMsg)
        end
        return param
    end
    return str:gsub("$(%b{})", interpolate)
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

createPascalCaseAliases(StringUtils)
return StringUtils

--[[
--! @}
--]]
