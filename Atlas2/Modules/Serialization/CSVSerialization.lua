local CSVSerialization = {}

if Atlas ~= nil then 
	CSVSerialization.csvPlugin = Atlas.loadPlugin("CSVSerializationPlugin")
else
 	CSVSerialization.csvPlugin= require("CSVSerializationPlugin")
end

--! @brief Load array of arrays from CSV file
--! @param fileName Input file name
--! @returns Array of Arrays of strings
function CSVSerialization.LoadFromFile(fileName)
	return CSVSerialization.csvPlugin.loadFromFile(fileName)
end

--! @brief Load array of arrays from NSData object
--! @param data Input data
--! @returns Array of Arrays of strings
function CSVSerialization.LoadFromData(data)
	return CSVSerialization.csvPlugin.loadFromData(data)
end

--! @brief Save array of arrays to CSV file
--! @details Creates a new CSV file with content defined by data.
--! @param data Data to save. Data is expected to be an array of arrays where the first line is column Headers
--! @param fileName target file name
function CSVSerialization.SaveToFile(fileName, data)
	return CSVSerialization.csvPlugin.saveToFile(fileName, data)
end

--! @brief Save array of arrays to NSData object
--! @param rows Rows to save. Rows is expected to be an array of arrays where the first line is column Headers
--! @param fileName target file name
function CSVSerialization.SaveToData(rows)
	return CSVSerialization.csvPlugin.saveToData(rows)
end

--! @brief Adds a single record to an existing CSV file or creates a new CSV file with single record
--! @details The function allows merging a new record to the existing CSV. This is useful when records with different Headers
--!			 need to be merged in a single CSV. Merge function adds empty values for missing columns (headers) in both old data and new record
--! @param fileName target file name
--! @param headers Headers for the new record as array of strings. Can be Nil 
--! @param data Data for the new record as array of values
--! @param append Bool value defining whether the records is to be appended to an existing file (True) or a new file is to be created (False)
--! @param merge If record merge is needed
function CSVSerialization.AddRecordToFile(fileName, headers, data, append, merge)
	return CSVSerialization.csvPlugin.appendToFile(fileName, headers, data, append, merge)
end

return CSVSerialization
