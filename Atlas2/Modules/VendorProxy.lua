local Log = require("Common/logging")
local comFunc = require("Common/Utilities")
local VENDOR_CODE_FOLDER = {
    INVT = string.gsub(Atlas.assetsPath, "Assets", "Modules/INVT")
}

local Identifier = nil
local VendorProxy = {}

--! @brief Loading vendor module
local function loadingVendorModule()
    local vendorPath = VENDOR_CODE_FOLDER
    local no_vendor_detected = true
    for name, path in  pairs(vendorPath) do
        if comFunc.fileExists(path .. "/init.lua") then
            local vendor = require(path)
            if vendor.isCompatible() == true then
                Identifier = name
                VendorProxy = vendor
                no_vendor_detected = false
                Log.LogInfo(name .. " is the compatible vendor for this station")
                break
            else
                Log.LogInfo(name .. " is not the compatible vendor, check next ...")
            end
        end
    end
    if no_vendor_detected then
        Log.LogError("No compatible vendor detected, error out")
        error("Failed to detect station setup to be compatible with any supported vendor")
    end
end
loadingVendorModule()

--! @brief Get vendor modules
function VendorProxy.require(moduleName)
    local modulePath = string.format("%s/Modules/%s", Identifier, moduleName)
    return require(modulePath)
end

--! @brief Get vendor schooner CVS APIs
function VendorProxy.getCSVAPIs()
    return VendorProxy.CSVAPIs()
end

--! @brief Get vendor fixture control APIs
function VendorProxy.getFixtureControl()
    return VendorProxy.FixtureControl
end

--! @brief Get vendor station constants
function VendorProxy.getConstants()
    return VendorProxy.Constants
end

return VendorProxy
