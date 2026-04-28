-------------------------------------------------------------------
----***************************************************************
---- IO Table
----***************************************************************
-------------------------------------------------------------------
local Helper = require("INVT/Modules/SMTLoggingHelper")
local comFunc = require("Common/Utilities")
local Json = require("Serialization/JSONSerialization")
local rootPath = Atlas.assetsPath:gsub("Assets", "Modules").."/INVT/Modules/IOTable"
local IOMapPath = rootPath .. "/io_map.json"
local uploadSH = rootPath .. "/uploadIOMap.sh"
local M = {}

M.IOTab = Json.LoadFromFile(IOMapPath)
M.IOMapPath = IOMapPath
M.UploadSH = uploadSH

--！@brief: get io list with net name
--！@param: net: string type
--！@param: net: string type
--！@return string type of io list
function M.getByNetName(net, subNet)
    local ioList = M.IOTab["HWIO_Relay_Table"][net][subNet]["IO"]
    Helper.LogFlowDebug(string.format("[IO Set] %s-%s: %s", net, subNet, M.ioListToStr(ioList)))
    return ioList
end

--！@brief: convert io list to string
--！@param: ioList: Table type
--！@return string of io list
function M.ioListToStr(ioList)
    local ioString = "["
    for _, v in pairs(ioList) do
        ioString = ioString .. "["
        for _, v1 in pairs(v) do
            ioString = ioString .. v1
            ioString = ioString .. ","
        end
        ioString = ioString .. "],"
    end
    ioString = ioString .. "]"
    ioString = string.gsub(ioString, ",]", "]")
    return ioString
end

--！@brief: MD5 check sum
function M.checkSum()
    local p = io.popen(string.format("md5 %s", IOMapPath))
    local md5String = p:read("*a")
    local md5 = string.match(md5String, "= (%w+)")
    return md5
end


return M
