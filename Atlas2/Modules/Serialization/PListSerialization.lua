local PListSerialization = {}

if Atlas ~= nil then 
    PListSerialization.PListPlugin = Atlas.loadPlugin("PListSerializationPlugin")
else
    PListSerialization.PListPlugin= require("PListSerializationPlugin")
end

--! @brief Load dictionary from PList file
--! @param PListFileName PList file name
--! @returns Dictionary object
function PListSerialization.LoadFromFile(PListFileName)
	
	local status, dict = pcall(PListSerialization.PListPlugin.decodeFile, PListFileName)
	if(status == true) then
		return dict
	else
		print("Failed to decode file: '" .. PListFileName .."'")
		return nil
	end
end

--! @brief Load dictionary from NSData
--! @param data NSData object
--! @returns Dictionary object
function PListSerialization.LoadFromData(data)
	return PListSerialization.PListPlugin.decodeData(data)
end

--! @brief Save dictionary to PList file
--! @param data Dictionary to save
--! @param PListFileName PList file name
function PListSerialization.SaveToFile(data, PListFileName)
	-- encodeToFile: true for binary format, false for XML format
	PListSerialization.PListPlugin.encodeToFile(data, PListFileName, false)
end

--! @brief Save dictionary to Binary PList file
--! @param data Dictionary to save
--! @param PListFileName PList file name
function PListSerialization.SaveToBinaryFile(data, PListFileName)
	-- encodeToFile: true for binary format, false for XML format
	PListSerialization.PListPlugin.encodeToFile(data, PListFileName, true)
end

--! @brief Save dictionary to NSData encoded as an XML PList
--! @param data Dictionary to save
function PListSerialization.SaveToData(data)
	-- encodeToFile: true for binary format, false for XML format
	return PListSerialization.PListPlugin.encodeToData(data, false)
end

--! @brief Save dictionary to NSData encoded as a binary PList
--! @param data Dictionary to save
function PListSerialization.SaveToBinaryData(data)
	-- encodeToFile: true for binary format, false for XML format
	return PListSerialization.PListPlugin.encodeToData(data, true)
end

return PListSerialization
