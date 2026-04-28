local common = require("Schooner.SchoonerCommon")
local helpers = require("Schooner.SchoonerHelpers")
m = {}

function m.mode()
    local groupArgs = GSM.groupArguments
    if groupArgs == nil then
        error("group args does not exist in station configuration plist")
    end
    if type(groupArgs) ~= "table" then
        error("group args in station plist must be an array")
    end

    local mode = groupArgs[#groupArgs]
    local msg = 'mode (last group arg in station configuration plist) '
    msg = msg .. 'should be a non-empty string'
    assert(helpers.isNonEmptyString(mode), msg)
    return mode
end

function m.product()
    local p = Atlas.loadPlugin('StationInfo')
    return p.product()
end

function m.stationType()
    local p = Atlas.loadPlugin('StationInfo')
    return p.station_type()
end

-- hex_str should be little endian
local function hex_to_int(hex_str)
    local result = 0
    for i = 1, #hex_str, 2 do
        local byte_value = tonumber(hex_str:sub(i, i + 1), 16)
        result = result + (byte_value * (256 ^ ((i - 1) // 2)))
    end
    return result
end

function m.noCl()
    local dut = Device.getPlugin(common.DUT)
    local readDataOk, noClData = pcall(Syscfg.readData, dut,
                                       common.NOCL_FLAG_DUT, 10)
    if not readDataOk then
        helpers.debugPrint("Failed to read NoCl: %s ", noClData)
        return
    end

    local nsdata = Atlas.loadPlugin("Utilities")
    local ok, digestHex = pcall(nsdata.dataToHexString, noClData)
    if not ok then
        helpers.debugPrint("Failed to run dataToHexString for NoCl: %s",
                           digestHex)
        return
    end

    local noCl = hex_to_int(digestHex)
    print("NoCl: " .. noCl)
    return noCl
end

function m.returnTrue()
    print('Debug: return True for condition validator')
    return true
end

function m.noClValidator(noCl) return noCl >= 0 end

return m
