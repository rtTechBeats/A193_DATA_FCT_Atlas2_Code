local plist2lua = {}

function trim(s)
    return s:gsub('^%s*(.-)%s*$', "%1")
end

function plist2lua.read(filename)
    local output = {}
    output.stack = {} -- use to keep trace of where we are
    table.insert(output.stack, output)
    local current_table = output.stack[#output.stack] -- shortcut to avoid a[#a]
    local key = nil
    local callbacks = {}

    -- FUNCTION DEFINITION
    local function StartArrayOrDict()
        if key then
            current_table[key] = {}
            current_table = current_table[key]
            table.insert(output.stack, current_table)
            key = nil
        else
            table.insert(current_table, {})
            current_table = current_table[#current_table]
            table.insert(output.stack, current_table)
        end
    end

    local function EndArrayOrDict()
        table.remove(output.stack)
        current_table = output.stack[#output.stack]
    end

    local function StartKey()
        callbacks.CharacterData = function(string)
            key = string
        end
    end

    local function StartStringOrInteger(string)
        callbacks.CharacterData = function(string)
            if key then
                current_table[key] = string
                key = nil
            else
                table.insert(current_table, string)
            end
        end
    end

    -- CALLBACKS FUNCTIONS
    local StartCallbacks = {
        array = StartArrayOrDict,
        dict = StartArrayOrDict,
        string = StartStringOrInteger,
        integer = StartStringOrInteger,
        key = StartKey
    }

    local EndCallbacks = {
        array = EndArrayOrDict,
        dict = EndArrayOrDict,
        string = function()
            callbacks.CharacterData = false
        end,
        integer = function()
            callbacks.CharacterData = false
        end,
        key = function()
            callbacks.CharacterData = false
        end
    }

    -- CALLBACKS used by the parser
    callbacks = {
        StartElement = function(name) -- what to do with <element>
            if StartCallbacks[name] ~= nil then
                StartCallbacks[name]()
            end
        end,

        EndElement = function(name) -- what to do with </element>
            if EndCallbacks[name] ~= nil then
                EndCallbacks[name]()
            end
        end,

        CharacterData = false -- what do with input, place holder
    }

    -- Actual Parsing
    for line in assert(io.lines(filename)) do -- iterate lines
        line = trim(line)
        for word in line:gmatch("%<?/?[^%<%>]*%>?") do
            if word:match('%</.-%>') then
                callbacks.EndElement(word:sub(3, #word - 1))
            elseif word:match('%<.-%>') then
                callbacks.StartElement(word:sub(2, #word - 1))
            elseif word:match('%w+') then
                callbacks.CharacterData(word)
            end
        end
    end

    return output[1]
end

function plist2lua.printTable(input, level)
    for k, v in pairs(input) do
        if type(v) == "table" then
            if type(k) ~= 'number' then
                io.write(string.rep("\t", level) .. k .. ":" .. "\n")
            end
            plist2lua.printTable(v, level + 1)
        else
            if type(k) ~= 'number' then
                io.write(string.rep("\t", level) .. k .. ": " .. v .. "\n")
            else
                io.write(string.rep("\t", level) .. v .. "\n")
            end
        end
    end
end

return plist2lua
