local vendor = require(string.gsub(Atlas.assetsPath, "Assets", "Modules/INVT/fixture"))

function vendor.isCompatible()
    -- Todo: check if the device is compatible with the vendor.
    return true
    -- -- Example for USBDevice detection
    -- local usb_utility = params and params["usb"] and params["usb"] or
    --                         Atlas.loadPlugin("SMTCommonPlugin").createUSBUtility()
    -- local property = {}
    -- for _, usbVendorID in ipairs(vendor.USB_VENDOR_ID) do
    --     property[usb_utility.USB_VENDOR_ID] = usbVendorID
    --     local locID = usb_utility.usbLocationIDFromProperty(property)
    --     if locID then
    --         return true
    --     end
    -- end
    -- return false
end

return vendor