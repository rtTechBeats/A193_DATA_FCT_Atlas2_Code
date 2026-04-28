local Relay = {}

local ErrorCode = require("INVT/Modules/ErrorCode")
local ErrorFunction = ErrorCode.init("RelayModule", 112)
local rpcClient = require("INVT/Modules/RPCClient")
local IOTable = require("INVT/Modules/IOTable")
local PluginsLoader = require("INVT/Modules/PluginsLoader")
local runShellCommand = PluginsLoader.getPlugin('RunShellCommand')
local expectScriptCode = [[#!/usr/bin/expect
set sourcePath "%s"
set purposePath "%s"
set password 123456
spawn scp -r $sourcePath $purposePath
expect {
	"(yes/no)?"
	{
		send "yes\n"
		expect "*assword" {send "$password\n"}
	}
	"*assword" {send "$password\n"}
}
expect "100%%"
expect eof
]]

--[[
Description:
    set bits by io_map.json net name.
Params:
    definition in json file
    "HWIO_Relay_Table":{
        "ANALOG_PMU_NTC_BAT_TO_RESISTANCE":{
            "NTC_28K":{
                "IO":[ [ 138, 1 ],[ 139, 0 ],[ 140, 0 ] ]},
            "NTC_10K":{
                "IO":[ [ 138, 0 ],[ 139, 1 ],[ 140, 0 ] ]},
            "NTC_2K":{
                "IO":[ [ 138, 0 ],[ 139, 0 ],[ 140, 1 ] ]},
            "Disconnect":{
                "IO":[ [ 138, 0 ],[ 139, 0 ],[ 140, 0 ] ]}
        },
    }
    netName<string>: ANALOG_PMU_NTC_BAT_TO_RESISTANCE.
    subNetName<string>: NTC_28K

Returns:
    <string>: "done".
Usage:
    Relay.switch("ANALOG_PMU_NTC_BAT_TO_RESISTANCE","Disconnect")

--]]
function Relay.switch(netName, subNetName)
    local ioList = IOTable.getByNetName(netName, subNetName)
    local retVal = rpcClient.callRPCFunc("relay.switch", ioList)
    if tostring(retVal):lower() ~= "done" then
        ErrorFunction(ErrorCode.ResourceResponseErr, retVal)
    end
    return ret
end

--[[
Description:
    reload Xavier map json file from macMini to Xavier.
Params:
    localPath<string>: json file path on macMini.
    mixDirPath<string>: Xavier json file path , can set nil, will used default path config in profile.json

Returns:
    <string>: map json file version after load.

Usage:

    Relay.reloadIOMap("/gdlocal/Desktop/io_map.json", "root@169.254.1.32:/mix/addon/config")

--]]
function Relay.reloadIOMap(localPath, mixDirPath)
    -- move io_map file from pc to Xavier
    local expectScriptPath = "/tmp/send_io_map.expect"
    local expectScriptFile = io.open(expectScriptPath, "w")
    expectScriptFile:write(string.format(expectScriptCode, tostring(localPath), tostring(mixDirPath)))
    expectScriptFile:close()
    runShellCommand.run("expect " .. expectScriptPath)
    local ret = rpcClient.callRPCFunc("relay.reload", {}, {}, 1000)
    if ret ~= "done" then
        ErrorFunction(ErrorCode.ResourceNoResponseErr, "reload map error, check json file content format.")
    end
    -- get version for check
    local version = rpcClient.callRPCFunc("relay.getMapInfo", {"VERSION"}, {}, 1000)
    if string.match(string.upper(version), "ERROR") then
        ErrorFunction(ErrorCode.ResourceResponseErr, version)
    end
    return version
end

--[[
Description:
    Initialization using information on reset table.
Params:
    groupName<string>: group name in Xavier json file.

Returns:
    <string>: "done".

Usage:
    "HWIO_RESET":{
        "TRANSLATION_BOARD":{
            "DRI":[ [ 81, 0 ],[ 82, 0 ],[ 83, 0 ],[ 84, 0 ],[ 85, 0 ],[ 86, 0 ],[ 87, 0 ] ]
            "IO":[ [ 81, 0 ],[ 82, 0 ],[ 83, 0 ],[ 84, 0 ],[ 85, 0 ],[ 86, 0 ],[ 87, 0 ],[ 88, 0 ] ]
        }
    }
    Relay.reset("TRANSLATION_BOARD")

--]]
function Relay.reset(groupName)
    local ret = rpcClient.callRPCFunc("relay.reset", {groupName}, {}, 1000)
    if ret ~= "done" then
        ErrorFunction(ErrorCode.ResourceResponseErr, ret)
    end
    return ret
end

--[[
Description:
    Read bits state.
Params:
    bitList<list>:  list of the bit read {1,2,6}.

Returns:
    <string>: bits number and state. bit1=0,bit2=0,bit6=1

Usage:
    Relay.getIOStates([1,2,6])

--]]
function Relay.getIOStates(bitList)
    local ret = rpcClient.callRPCFunc("io.read", {bitList}, {}, 1000)
    if string.match(string.upper(ret), "ERROR") then
        ErrorFunction(ErrorCode.ResourceResponseErr, ret)
    end
    return ret
end

--[[
Description:
    GPIO set pin level.

Params:
    mixRegisteredName<string>: class name registered in mix profile
    "gpio_2":{
        "class":"GPIO",
        "pin_id": 1000,
        "default_dir":"output"
    }
    level<int>:[0], 1 is high level, 0 is low level.

Returns:
    done/GPIOSetErr

Usage:

    Relay.setGPIOLevel("gpio_2",1)

--]]
function Relay.setGPIOLevel(mixRegisteredName, level)
    local currentDir = Relay.getGPIODir(mixRegisteredName)
    if currentDir == "input" then
        ErrorFunction(ErrorCode.GPIOSetErr, "reload map error, check json file content format.")
    end
    local cmd = mixRegisteredName .. ".set_level"
    local ret = rpcClient.callRPCFunc(cmd, {level}, {}, 1000)
    if string.match(string.upper(ret), "ERROR") then
        ErrorFunction(ErrorCode.ResourceResponseErr, ret)
    end
    return true
end

--[[
Description:
    GPIO get pin level.

Params:
    mixRegisteredName<string>: class name registered in mix profile
    "gpio_2":{
        "class":"GPIO",
        "pin_id": 1000,
        "default_dir":"output"
    }

Returns:
    <int>: pin level value.

Usage:
    Relay.setGPIOLevel("gpio_2")

--]]
function Relay.getGPIOLevel(mixRegisteredName)
    local cmd = mixRegisteredName .. ".get_level"
    local ret = rpcClient.callRPCFunc(cmd, {}, {}, 1000)
    if string.match(string.upper(ret), "ERROR") then
        ErrorFunction(ErrorCode.ResourceResponseErr, ret)
    end
    return ret
end

--[[
Description:
    GPIO set pin direction.

Params:
    mixRegisteredName<string>: class name registered in mix profile
    "gpio_2":{
        "class":"GPIO",
        "pin_id": 1000,
        "default_dir":"output"
    }
    pinDir<string>: ["input", "output"], Set the io direction.

Returns:
    None

Usage:
     Relay.setGPIODir("gpio_2","input")

--]]
function Relay.setGPIODir(mixRegisteredName, pinDir)
    local cmd = mixRegisteredName .. ".set_dir"
    local ret = rpcClient.callRPCFunc(cmd, {pinDir}, {}, 1000)
    if string.match(string.upper(ret), "ERROR") then
        ErrorFunction(ErrorCode.ResourceResponseErr, ret)
    end
    return true
end

--[[
Description:
    GPIO get pin direction.

Params:
    mixRegisteredName<string>: class name registered in mix profile
    "gpio_2":{
        "class":"GPIO",
        "pin_id": 1000,
        "default_dir":"output"
    }

Returns:
    <string>: 'input'/'output'.

Usage:
     Relay.getGPIODir("gpio_2")

--]]
function Relay.getGPIODir(mixRegisteredName)
    local cmd = mixRegisteredName .. ".get_dir"
    local ret = rpcClient.callRPCFunc(cmd, {}, {}, 1000)
    if string.match(string.upper(ret), "ERROR") then
        ErrorFunction(ErrorCode.ResourceResponseErr, ret)
    end
    return ret
end

return Relay
