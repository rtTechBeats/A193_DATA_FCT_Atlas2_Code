local JSONSerialization = {}

if Atlas ~= nil then
    JSONSerialization.jsonPlugin = Atlas.loadPlugin("JSONSerializationPlugin")
else
    JSONSerialization.jsonPlugin = require("JSONSerializationPlugin")
end

--! @brief Load dictionary from JSON file
--! @param jsonFileName JSON file name
--! @returns Dictionary object
function JSONSerialization.LoadFromFile(jsonFileName)
    local file = io.open(jsonFileName, "rb")
    assert(file, ("Could not open file '%s' for read"):format(jsonFileName))

    local content = file:read("*a")
    file:close()

    local dict = {}
    if content then
        dict = JSONSerialization.jsonPlugin.decode(content)
    end

    return dict
end

--! @brief Save dictionary to JSON file
--! @param data Dictionary to save
--! @param jsonFileName JSON file name
function JSONSerialization.SaveToFile(data, jsonFileName)
    local dataStr = JSONSerialization.jsonPlugin.encode(data)
    local file = io.open(jsonFileName, "wb")
    assert(file, ("Could not open file '%s' for writing"):format(jsonFileName))

    file:write(dataStr)
    file:close()
end

function JSONSerialization.LoadFromData(data)
    return JSONSerialization.jsonPlugin.decode(data)
end

function JSONSerialization.SaveToData(data)
    return JSONSerialization.jsonPlugin.encodeToData(data)
end

return JSONSerialization
