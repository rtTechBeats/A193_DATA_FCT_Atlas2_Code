local fdrExportCore = require("Internal/FDRExportCore")
local Log = require("Common/logging")

local export = {}

--! export FDR keys to target sites
--! param requestList string, path of the plist file which specifies keys and target sites. 
--! param exportSpec string (optional), path of the plist file which defines export identifiers format for FDR keys
--! param identifiers dictionary, keyword pairs of identifiers to construct export uid
--! param resultCSV string(optional), path of export result log file
function export.exportFDR(params)
    local requestList = params.requestList
    local spec = params.exportSpec
    local logPath = params.resultCSV
    local variables = {}

    for k,v in pairs(params) do
        if k ~= "requestList" and k ~= "timeout" and k ~= "exportSpec" and k ~= "resultCSV" and k ~= "subsubtest" then
            variables[k] = v
        end
    end
    if fdrExportCore.exportFDRInternal(Device.getPlugin("FDRPlugin"), variables, requestList, spec, logPath) then
        return true
    else
        local msg = "FDR Export Failed, check export result csv for details"
        Log.LogError(msg)
        return false
    end
end

--! Submit data to FDR (PATCH)
function export.patchIntoFDR(params)
    local variables = {}

    for k,v in pairs(params) do
        if k ~= "timeout" and k ~= "subsubtest" then
            variables[k] = v
        end
    end

    local type = "Patch"
    if fdrExportCore.uploadFDR(Device.getPlugin("FDRPlugin"), variables, type) then
        return true
    else
        local msg = "Patch FDR failed, check result csv for details"
        Log.LogError(msg)
        return false
    end
end

--! Submit data to FDR (PUT)
function export.putIntoFDR(params)
    local variables = {}

    for k,v in pairs(params) do
        if k ~= "timeout" and k ~= "subsubtest" then
            variables[k] = v
        end
    end

    local type = "Put"
    if fdrExportCore.uploadFDR(Device.getPlugin("FDRPlugin"), variables, type) then
        return true
    else
        local msg = "Put FDR failed, check result csv for details"
        Log.LogError(msg)
        return false
    end
end

local ActionHelper = require("SMTActionHelper")

local CSVInterfaceTable = {
    delegate = export
}

setmetatable(CSVInterfaceTable, ActionHelper.MetaTableFlowLogging)

return CSVInterfaceTable