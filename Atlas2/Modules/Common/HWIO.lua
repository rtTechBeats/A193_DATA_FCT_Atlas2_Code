local HWIO = {}
local constant = require("StationConfig")
local commonFunc = require("Common/Utilities")

HWIO["ioTable"] = nil

local function filterVendor(vendorName)
    assert(vendorName ~= nil, "Empty vendorName parameter input.")
    local allVendor = constant.VENDOR_CODE_FOLDER
    if not commonFunc.hasKey(allVendor, vendorName) then
        error("vendorName: " .. vendorName .. "not define in vendor table: " .. commonFunc.dump(allVendor))
    end
    return commonFunc.removeTabValue(allVendor, vendorName)
end

function HWIO.parseHWIO(vendorName)
    local hwioPath = Atlas.assetsPath .. "/hwio/hwio.json"
    local io_string = commonFunc.fileRead(hwioPath)
    local io_table = commonFunc.parseParameter(io_string)
    local vendorExceptSelf = filterVendor(vendorName)

    local function findOtherVendor(netName)
        for _, otherVendor in pairs(vendorExceptSelf) do
            if string.find(netName, "^" .. otherVendor .. "_") then
                return true
            end
        end
        return false
    end

    local function removeOtherVendorNet(tableData)
        for _, nets in pairs(tableData) do
            for i = #nets, 1, -1 do
                if findOtherVendor(nets[i]['io']) then
                    -- filter other vendor nets
                    table.remove(nets, i)
                end
            end
        end
    end

    local getHWIOData = function(ioType)
        local filterIo = {}
        local ioTypeData = io_table[ioType]
        local vendorPattern = "^" .. vendorName .. "_"

        for netName, netData in pairs(ioTypeData) do
            if next(vendorExceptSelf) == nil then
                filterIo[netName] = netData -- not find other vendor
            else
                if not findOtherVendor(netName) then
                    filterIo[netName] = netData
                    if string.find(netName, vendorPattern) then
                        -- e.g. "CYG_XXXX" -> "VENDOR_XXXX". Unified the same net name for tp calls
                        -- "VENDOR_XXXX" and "CYG_XXXX" are both valid after this step.
                        netName = string.gsub(netName, vendorPattern, "VENDOR_")
                        filterIo[netName] = netData
                    end
                end
                if ioType == "iomux" then
                    -- remove other vendor nets in iomux source level
                    -- "iomux":{"UART_SWITCH_EN":{"ENABLE":[{"io":"CYG_XXXX","value": 0},{"io":"PRM_XXXX","value": 0}]}} ->>>
                    -- {"UART_SWITCH_EN":{"ENABLE":[{"io":"CYG_XXXX","value": 0}]}}
                    removeOtherVendorNet(filterIo[netName])
                end
            end
        end
        return filterIo
    end
    if io_table and next(io_table) ~= nil then
        -- handle hwio action group
        removeOtherVendorNet(io_table['action'])

        -- handle hwio io/iomux group
        io_table.io = getHWIOData("io")
        io_table.iomux = getHWIOData("iomux")
    else
        error("load hwio.json fail")
    end
    HWIO["ioTable"] = io_table
    return io_table
end

-- group level hwio data getting:
-- 1.Internal/Vendor/initCore: Should call "HWIO.parseHWIO" to obtain it.
-- 2.Other module at group level should call "HWIO.ioTable" to obtain it.
if Device then
    local variableTable = Device.getPlugin("VariableTable")
    HWIO["ioTable"] = variableTable.getVar("HWIOData") or
                          error(
                              "Failed to get 'HWIOData', please check if 'HWIOData' was saved in the VariableTable before.")
end

HWIO.DEFINITION_SECTION = {
    ACTION = "action",
    FPGAIO = "fpgaio",
    FPGAIO_ALIAS = "fpgaio_alias",
    IO = "io",
    IOMUX = "iomux",
    POWER = "power",
    POWER_ALIAS = "power_alias",
    SIGNAL = "signal",
    SIGNAL_ALIAS = "signal_alias",
    I2C_DEVICE = "i2c_device",
    IO_CONSTRAINT = "io_constraint"
}

HWIO.IO_SETTING_FIELD = {
    DIRECTION = "config",
    DEFAULT = "default",
    INDEX = "index",
    FACTOR = "factor",
    SERVER = "rpcServer",
    CONSTRAINT = "constraint"
}

-- rename to HWIO.getIOByIndex to get_io_by_name
-- function HWIO.getIOByIndex(net)
function HWIO.get_io_by_name(net_name)
    assert(net_name ~= nil, "net_name parameter is empty.")
    local io_name = HWIO["ioTable"][HWIO.DEFINITION_SECTION.IO][net_name]
    return io_name or error('undefined ' .. net_name .. ' in HWIO.io')
end

function HWIO.get_io_server_name(net_name)
    assert(net_name ~= nil, "net_name parameter is empty.")
    local serverName = HWIO["ioTable"][HWIO.DEFINITION_SECTION.IO][net_name][HWIO.IO_SETTING_FIELD.SERVER]
    return serverName or nil
end

function HWIO.get_io_constraint(net_name)
    assert(net_name ~= nil, "net_name parameter is empty.")
    local constraint = HWIO["ioTable"][HWIO.DEFINITION_SECTION.IO][net_name][HWIO.IO_SETTING_FIELD.CONSTRAINT]
    assert(constraint ~= nil, "constraint is not defined in " .. net_name)
    local io_constraint = HWIO["ioTable"][HWIO.DEFINITION_SECTION.IO_CONSTRAINT] or {}
    if not commonFunc.hasKey(io_constraint, constraint) then
        error(constraint .. " is not defined in hwio -> io_constraint: " .. commonFunc.dump(io_constraint))
    end
    return io_constraint[constraint]
end

function HWIO.get_iomux_by_name(testpoint, source)
    assert(testpoint ~= nil, "testpoint parameter is empty.")
    assert(source ~= nil, "source parameter is empty.")

    local iomux_name = HWIO["ioTable"][HWIO.DEFINITION_SECTION.IOMUX][testpoint][source]
    return iomux_name or error("testpoint: " .. tostring(testpoint) .. ' is not defined in HWIO.iomux.')
end

function HWIO.get_signal_by_name(net_name)
    assert(net_name ~= nil, "net_name parameter is empty.")
    local net, signal
    if HWIO["ioTable"][HWIO.DEFINITION_SECTION.SIGNAL_ALIAS][net_name] then
        net = HWIO["ioTable"][HWIO.DEFINITION_SECTION.SIGNAL_ALIAS][net_name]
        signal = HWIO["ioTable"][HWIO.DEFINITION_SECTION.SIGNAL][net]
    elseif HWIO["ioTable"][HWIO.DEFINITION_SECTION.SIGNAL][net_name] then
        signal = HWIO["ioTable"][HWIO.DEFINITION_SECTION.SIGNAL][net_name]
    else
        error("Fail, signal " .. net_name .. "is not defined in hwio.json")
    end
    return signal
end

function HWIO.get_power_by_name(net_name)
    assert(net_name ~= nil, "net_name parameter is empty.")
    local net, power
    if HWIO["ioTable"][HWIO.DEFINITION_SECTION.POWER_ALIAS][net_name] then
        net = HWIO["ioTable"][HWIO.DEFINITION_SECTION.POWER_ALIAS][net_name]
        power = HWIO["ioTable"][HWIO.DEFINITION_SECTION.POWER][net]
    elseif HWIO["ioTable"][HWIO.DEFINITION_SECTION.POWER][net_name] then
        power = HWIO["ioTable"][HWIO.DEFINITION_SECTION.POWER][net_name]
    else
        error("Fail, power node " .. net_name .. "is not defined in hwio.json")
    end
    return power
end

function HWIO.get_fpgaio_by_name(net_name)
    assert(net_name ~= nil, "net_name parameter is empty.")
    local net, fpgaio
    if HWIO["ioTable"][HWIO.DEFINITION_SECTION.FPGAIO_ALIAS][net_name] then
        net = HWIO["ioTable"][HWIO.DEFINITION_SECTION.FPGAIO_ALIAS][net_name]
        fpgaio = HWIO["ioTable"][HWIO.DEFINITION_SECTION.FPGAIO][net]
    elseif HWIO["ioTable"][HWIO.DEFINITION_SECTION.FPGAIO][net_name] then
        fpgaio = HWIO["ioTable"][HWIO.DEFINITION_SECTION.FPGAIO][net_name]
    else
        error("Fail, power node " .. net_name .. "is not defined in hwio.json")
    end
    return fpgaio
end

function HWIO.get_i2c_device_info(device)
    assert(device ~= nil, "device parameter is empty.")
    local i2cDevice = HWIO["ioTable"][HWIO.DEFINITION_SECTION.I2C_DEVICE][device]
    assert(i2cDevice ~= nil, "Fail, i2c_device: " .. device .. "is not defined in hwio.json")

    local bus = i2cDevice.bus
    local deviceAddress = i2cDevice.deviceAddress
    local registerAddressSize = i2cDevice.registerAddressSize
    local registerDataSize = i2cDevice.registerDataSize
    if not (bus and registerAddressSize and registerDataSize) then
        error(
            "Fail to get i2c device info. Please check the bus/registerAddressSize/registerDataSize info for i2c_device group in hwio.json " ..
                commonFunc.dump(i2cDevice))
    end
    return bus, deviceAddress, registerAddressSize, registerDataSize
end

return HWIO
