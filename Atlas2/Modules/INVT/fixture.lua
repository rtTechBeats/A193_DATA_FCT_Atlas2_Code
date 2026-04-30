-------------------------------------------------------------------
----***************************************************************
---- INVT Fixture Module
----***************************************************************
-------------------------------------------------------------------
local Log = require("Common/logging")
local comFunc = require("Common/Utilities")
local constants = require("INVT/constants")
local pluginsLoader = require("INVT/Modules/PluginsLoader")
local runShellCmd = pluginsLoader.getPlugin("RunShellCommand")
local commonUtil = pluginsLoader.getPlugin("SMTCommonPlugin")
local time = commonUtil.createTimeUtility()
local fileOperation = require("Common/FileOperation")
local launchTime = nil
local defaultUnits = nil
local isLaunchAtlas = false

Log.LogInfo(">>>>>> Require INVT Fixture <<<<<<")

local fixture = {}
--! @brief require INVT CSV APIs
fixture.CSVAPIs = function ()
    return require("INVT/API")
end
fixture.Constants = constants
fixture.FixtureControl = nil
fixture.InteractiveView = nil
fixture.globalRemoteProcessInstance = nil
--! @brief INVT Fixture constants
fixture.automationEnabled = false
fixture.overallResult = true
fixture.stateMachine = {}

--!@ Update Atlas2 Status UI
local stationInfoTab = {inputCount = 0, passCount = 0, failCount = 0}

--! @brief show platfrom alert
local function syncFixtureInfo(stateTab)
    assert(type(stateTab) == "table" or type(stateTab) == "nil", "Parameter must be table or empty!")
    local json = require("Serialization/JSONSerialization")
    local rtLib = require("INVT/Modules/RTCommonLib")
    local smPath = "/tmp/INVT_FixtureInfo.json"
    if not comFunc.fileExists(smPath) then
        local fd = io.open(smPath, "w+")
        fd:write("{}")
        fd:close()
    end
    if stateTab then
        local currTab = json.LoadFromFile(smPath)
        local mergeTab = rtLib.table_concat(currTab, stateTab)
        json.SaveToFile(mergeTab, smPath)
    end
    local currentSM = json.LoadFromFile(smPath)
    Log.LogInfo(comFunc.dump(currentSM))
    fixture.stateMachine = currentSM
    return currentSM
end

--! @brief Sync Xavier timestamp IOMap.json.
local function syncXavier()
    Log.LogInfo("Starting Sync Xavier RTC and IOMap")
    local rpcClient = Atlas.loadPlugin("MIXRPCClientPlugin")
    local xavierPort = 7800
    local IPTable = {}
    local ioLib = require("INVT/Modules/IOTable")
    local groupID = 1
    local slots = 4
    local atlasMD5 = ioLib.checkSum()

    for index=1, slots do
        local url = constants.StationURL["slot"..index].mixURL
        if url == nil then
            error("IP & Port is null!")
        end
        local IP, Port = table.unpack(comFunc.splitString(url, ":"))
        Log.LogInfo("IP: "..IP)
        Log.LogInfo("Port: "..Port)
        if comFunc.hasVal(IPTable, IP) ~= true then
            --!@ Xavier Sync Time
            runShellCmd.run("ping -c 1 -W 1 " .. IP)
            rpcClient.init(IP, xavierPort)
            local bRet, retVal = pcall(rpcClient.rpc, "xavier.set_rtc", {os.time()})
            Log.LogInfo("xavier set rtc res: ", retVal)
            if string.match(retVal, "(PASS)") then
                Log.LogInfo("Set Xavier RTC Pass: " .. IP)
            else
                error("Set Xavier RTC Fail: " .. IP)
            end
            rpcClient.shutdown()
            --!@ check and update ioMap
            -- rpcClient.init(IP, tonumber(Port))
            -- local bRet, xavierMD5 = pcall(rpcClient.rpc, "mixdevice.readChecksum")
            -- if xavierMD5 ~= atlasMD5 then
            --     local cmd = string.format("sh %s %s %s", ioLib.UploadSH, ioLib.IOMapPath, IP)
            --     runShellCmd.run(cmd)
            -- end
            -- rpcClient.shutdown()
        end
        -- rpcClient.init(IP, tonumber(Port))
        -- local bRet, xavierMD5 = pcall(rpcClient.rpc, "mixdevice.loadIOMap")
        -- rpcClient.shutdown()
        -- if xavierMD5 ~= atlasMD5 then
        --     error("Xavier compare Atlas2 IOMap MD5 check Fail: " .. IP)
        -- end
        -- Log.LogInfo(string.format("Check %s:%s IOMap MD5 %s PASS ", IP, Port, xavierMD5))
        table.insert(IPTable, IP)
    end
end

--! @brief to terminate remote process
--! @param a remote processe instance
--! @returns no return
local function terminateRemoteProcessWithRunningStatusCheck(remoteProcessInstance)
    if remoteProcessInstance then
        if remoteProcessInstance.isRunning() then
            Log.LogInfo("The remote process is running, terminate it")
            remoteProcessInstance.terminateRemoteProcess()
        else
            Log.LogInfo("The remote process is not running, do nothing")
        end
    else
        Log.LogInfo("No remote process instance created!")
    end
end

--! @brief to launch remote process
--! @param a remote processe instance
--! @returns remote plugin instance
local function launchRemoteProcess(pluginName)
    Log.LogInfo("Launch remote process for " .. pluginName)
    local remoteProcessInstance = Remote.launchRemoteProcess(pluginName)
    local url = remoteProcessInstance.remoteProcessUrl()
    Log.LogInfo("Loading remotePlugin with URL:" .. url)
    local remotePluginInstance = Remote.loadRemotePlugin(url)
    return remoteProcessInstance, remotePluginInstance
end

--! @brief check local Firmware MD5
local function checkFirmwarePackage()
    Log.LogInfo("Starting Check Firmware Package")
    local rtLib = require("INVT/Modules/RTCommonLib")
    local fwPath = "/Users/gdlocal/RestorePackage/Tools/FirmwarePackage"
    local fwMD5Dir = "/Users/gdlocal/RestorePackage/Tools/MD5Checksum"
    local fwMD5File = fwMD5Dir.."/MD5List_FirmwarePackage.txt"
    local fwMD5Cmd = "find %s -type f -print0 | xargs -0 md5 > %s"
    local slotsDir = {
        slot1 = "/Users/gdlocal/RestorePackage/Tools/slot1",
        slot2 = "/Users/gdlocal/RestorePackage/Tools/slot2",
        slot3 = "/Users/gdlocal/RestorePackage/Tools/slot3",
        slot4 = "/Users/gdlocal/RestorePackage/Tools/slot4"
    }
    --!@ check frimware is exists
    if not rtLib.path_isdir(fwPath) then
        Log.LogInfo("Firmware package is not exists, please check "..fwPath)
        error("Firmware package is not exists, please check "..fwPath)
    end
    --!@ check md5 dir is exists
    if not rtLib.path_isdir(fwMD5Dir) then
        rtLib.path_makedir(fwMD5Dir)
    end
    --!@ clear md5 list, generate new md5 list
    runShellCmd.run(string.format("rm -rf %s/*", fwMD5Dir))
    runShellCmd.run(string.format(fwMD5Cmd, fwPath, fwMD5File))
    --!@ check slot dir is exists
    for index, slotDir in pairs(slotsDir) do
        local slotFwDir = slotDir.."/FirmwarePackage"
        local slotMD5Cmd = "find %s -type f -print0 | xargs -0 md5 > %s/MD5List_%s.txt"
        if not rtLib.path_isdir(slotDir) then
            runShellCmd.run("mkdir "..slotDir)
            runShellCmd.run(string.format("cp -r -f %s %s", fwPath, slotFwDir))
        end
        runShellCmd.run(string.format(slotMD5Cmd, slotFwDir, fwMD5Dir, index))
    end
    --!@ check overall md5 list
    local checkFiles = {
        "/Users/gdlocal/RestorePackage/Tools/MD5Checksum/MD5List_FirmwarePackage.txt",
        "/Users/gdlocal/RestorePackage/Tools/MD5Checksum/MD5List_slot1.txt",
        "/Users/gdlocal/RestorePackage/Tools/MD5Checksum/MD5List_slot2.txt",
        "/Users/gdlocal/RestorePackage/Tools/MD5Checksum/MD5List_slot3.txt",
        "/Users/gdlocal/RestorePackage/Tools/MD5Checksum/MD5List_slot4.txt"
    }
    local checkTab = {{}, {}, {}, {}, {}}
    local pattern = "%/FirmwarePackage%/(.+)%)%s*%=%s*("..string.rep("%w", 32)..")"
    for index, checkFile in pairs(checkFiles) do
        for line in io.lines(checkFile) do 
            local key, value = line:match(pattern)
            if line:find("/tools/flashtool/log") or line:find("/tools/logtool/log") or line:find("/read_fusing") then
                goto continue
            elseif key:find("DS_Store") then
                goto continue
            end
            checkTab[index][key] = value
            ::continue::
        end
    end
    --!@ check file md5
    local bRet = comFunc.deepCompare(checkTab[1], checkTab[2])
    if not bRet then return false, "Check Slot1 Firmware Package Fail" end
    bRet = bRet and comFunc.deepCompare(checkTab[1], checkTab[3])
    if not bRet then return false, "Check Slot2 Firmware Package Fail" end
    bRet = bRet and comFunc.deepCompare(checkTab[1], checkTab[4])
    if not bRet then return false, "Check Slot3 Firmware Package Fail" end
    bRet = bRet and comFunc.deepCompare(checkTab[1], checkTab[5])
    if not bRet then return false, "Check Slot4 Firmware Package Fail" end
    
    local msg = bRet and "Check Firmware Package PASS" or "Check Firmware Package FAIL"
    Log.LogInfo(msg)
    return bRet
end

--! @brief Delete logs that are more than 7 days
local function removeAtlasTestLog()
    Log.LogInfo("Starting remove Atlas Test Log")
    local removeUnitLogCmd = "/usr/bin/find /Users/gdlocal/Library/Logs/Atlas/unit-archive -type f -mtime +7d -delete"
    local removeUnitEmptyCmd = "/usr/bin/find /Users/gdlocal/Library/Logs/Atlas/unit-archive -type d -empty -delete"
    local removeAtlasLogCmd = "/usr/bin/find /Users/gdlocal/Library/Logs/Atlas/atlas-archive -type f -mtime +7d -delete"
    local removeAtlasEmptyCmd = "/usr/bin/find /Users/gdlocal/Library/Logs/Atlas/atlas-archive -type d -empty -delete"

    local bRet
    local _, retTab = xpcall(runShellCmd.run, debug.traceback, removeUnitLogCmd)
    Log.LogInfo(comFunc.dump(retTab))
    bRet = retTab.returnCode == 0 and true or false

    local _, retTab = xpcall(runShellCmd.run, debug.traceback, removeUnitEmptyCmd)
    Log.LogInfo(comFunc.dump(retTab))
    bRet = bRet and retTab.returnCode == 0 and true or false

    local _, retTab = xpcall(runShellCmd.run, debug.traceback, removeAtlasLogCmd)
    Log.LogInfo(comFunc.dump(retTab))
    bRet = bRet and retTab.returnCode == 0 and true or false

    local _, retTab = xpcall(runShellCmd.run, debug.traceback, removeAtlasEmptyCmd)
    Log.LogInfo(comFunc.dump(retTab))
    bRet = bRet and retTab.returnCode == 0 and true or false

    Log.LogInfo(("Remove Atlas Test Log %s"):format(bRet and "Pass" or "Fail"))
    return bRet, retTab.returnCode
end

--! @brief kill virtualPort
local function killVirtualPort()
    local groupID = Group.index
    for _, unit in ipairs(Group.getSlots()) do
        local slotNumber = tonumber(string.match(unit, '([0-9]+)$'))
        local IPandPort = topology["groups"][groupID]["units"][slotNumber]["MixIP"]
        local cmd = "ps -x | grep -v grep | grep " .. tostring(IPandPort) .. " | awk '{print $1}' | xargs kill -9"
        Log.LogInfo("kill virtualPort command:", cmd)
        os.execute(cmd)
    end
    Log.LogInfo("Kill VirtualPort Finished")
    return true
end

--! @brief: load rpcClient plugIn and init rpcClient by slot
--! @param: deviceName for currently slot name
--! @return: object of rpcClient
local function createRPCClient(deviceName)
    local rpcClient = Atlas.loadPlugin("MIXRPCClientPlugin")
    local slotNum = tonumber(string.match(deviceName, "([0-9]+)$"))
    local slotID = "slot" .. slotNum
    local url = constants.StationURL[slotID].mixURL
    assert(url ~= nil, "Mix URL is nil!")
    local IP, Port = table.unpack(comFunc.splitString(url, ":"))
    local Port = tonumber(Port)
    Log.LogInfo("IP:", IP)
    Log.LogInfo("Port:", Port)
    rpcClient.init(IP, Port)
    return rpcClient
end

local function connectVisaInstr(name, port)
    local visa = Atlas.loadPlugin("VisaInstrument")
    -- local rsrc = "USB0::0x067B::0x23C3::DGCQb103Y23::RAW"
    local session = visa.open(port, {timeoutMs = 5000, readBytes = 9600, readUntil = "\n"})
    Log.LogInfo(string.format("Open Instrument %s successfully", name))
    local idn = session.sendCommand("*IDN?")
    Log.LogInfo("Query *IDN: " .. tostring(idn.output))
    return session
end

--! @brief: load rpcClient plugIn and init rpcClient by slot
--! @param: deviceName for currently slot name
--! @return: object of rpcClient
local function createMoroccoRPCClient(deviceName)
    local rpcClient = Atlas.loadPlugin("MIXRPCRelay")
    local slotNum = tonumber(string.match(deviceName, "([0-9]+)$"))
    local url = topology["groups"][Group.index]["units"][slotNum]["MixIP"]
    assert(url ~= nil, "Mix URL is nil!")

    rpcClient.init(IP, Port)

    return rpcClient
end

--! @brief: create CommBuilder object
local function createComm(device, commMuxURL)
    local commBuilder = Atlas.loadPlugin('CommBuilder')
    local deviceUserDir = Group.getDeviceUserDirectory(device)
    local activeChannelOn = 1
    local legacyLogModeOn = 1

    local commPlugin = nil
    local plugins = {}

    -- create commPlugins
    for channel, config in pairs(constants.COMM_MUX) do
        Log.LogInfo("create comm channel", channel)
        commBuilder.setDelimiter(config.setup_params.delimiter)
        Log.LogInfo("set delimiter: ", config.setup_params.delimiter)
        if not constants.DEBUGGING_LOG_DISABLED then
            local postLogFilePath = deviceUserDir .. config.setup_params.log.PostLogFile
            local preLogFilePath = deviceUserDir .. config.setup_params.log.PreLogFile
            commBuilder.setLogFilePath(postLogFilePath, preLogFilePath)
            -- create DutCommunication Log File Folder
            for _, file in ipairs({postLogFilePath, preLogFilePath}) do
                local dutCommLogFolder = string.match(file, "(%/.*)%/")
                if not comFunc.fileExists(dutCommLogFolder) then
                    fileOperation.createDirectory(dutCommLogFolder)
                end
            end
        end

        Log.LogInfo("set active channel: ", config.setup_params.active)
        if config.setup_params.active then
            commBuilder.setActiveChannelOnOff(activeChannelOn)
        end

        local baseChannel = commBuilder.createBaseChannel(commMuxURL[channel])

        -- create SMT Data Channel
        local SMTDataChannel = Atlas.loadPlugin("SMTDataChannel")
        local channelPlugin = SMTDataChannel.createChannelPlugin()

        -- creater SMT Log
        local smtLogFilePath = deviceUserDir .. config.setup_params.log.SMTLogFile
        channelPlugin.setLogFilePath(smtLogFilePath)
        local folder = string.match(smtLogFilePath, "(%/.*)%/")
        if not comFunc.fileExists(folder) then
            fileOperation.createDirectory(folder)
        end
        channelPlugin.setLegacyLogMode(legacyLogModeOn)

        local dataChannel = channelPlugin.createDataChannel(baseChannel)
        commPlugin = commBuilder.createEFIPlugin(dataChannel)
        -- BP fixture hub config apple vid/pid with tray board,
        -- kis dock channel 0 will disappear after resetStation setup
        if config.need_open then
            os.execute("sleep 0.5")
            commPlugin.open()
            Log.LogInfo("commPlugin is open: ", commPlugin.isOpened())
        end

        plugins[channel] = commPlugin

        -- init commPath
        if config.primary then
            runShellCmd.run("echo " .. channel .. " > /tmp/DUTCommPath_" .. device)
        end
    end

    return plugins
end

--! @brief: init the kisport with fix port name
local function createUSBComm(url, logFilePath)
    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    local SMTDataChannel = Atlas.loadPlugin("SMTDataChannel")

    -- @ initialize uart log file path
    local channelPlugin = SMTDataChannel.createChannelPlugin()
    -- Enable real-time logging of data chunk per read, without breaking output lines like default "pre-" log
    channelPlugin.setLogFilePath(logFilePath)
    local baseChannel = CommBuilder.createBaseChannel(url)
    -- Device URL or ATKDataChannel created by other plugins like CommBuilder can be passed in here.
    local dataChannel = channelPlugin.createDataChannel(baseChannel)
    -- @ delay 100us for each character
    -- channelPlugin.setInterCharDelay(0.001)
    -- Pass data channel to CommBuilder
    local usbComm = CommBuilder.createCommPlugin(dataChannel)

    return usbComm
end

--! @brief: init the kisport with fix port name
local function initKisPort(deviceName)
    local slotNum = string.match(deviceName, "S=%a*(%d+)")
    local slotID = "slot" .. slotNum
    Log.LogInfo("slotID:", slotID)
    -- local relativeLocation = _Utility.getKISDeviceURL({PID = 0x2514, VID = 0x0424, Slot = slotNumber})
    -- assert(relativeLocation ~= nil, "relativeLocation is nil")
    -- if slotNumber < 5 then
    --     relativeLocation = string.gsub(relativeLocation, "142", "144")
    -- else
    --     relativeLocation = string.gsub(relativeLocation, "144", "142")
    -- end
    local relativeLocation = constants.KISPort[slotID]
    Log.LogInfo("relativeLocation:", relativeLocation)
    local uartPath = "/dev/cu.kis-"..relativeLocation.."-ch-2"
    -- local uartPath = string.format('/dev/cu.kis-%s-ch-2', string.match(string.lower(relativeLocation), "0x(%w+)"))
    Log.LogInfo("device:", deviceName)
    Log.LogInfo("uartPath:", uartPath)

    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    local SMTDataChannel = Atlas.loadPlugin("SMTDataChannel")
    local workingDirectory = Group.getDeviceUserDirectory(deviceName)
    local baudRate = 921600
    local dataBit = 8
    local parity = 'N'
    local stopBit = 1
    local url = "uart://"..uartPath.."?baud="..tostring(baudRate).."&mode="..tostring(dataBit)..parity..tostring(stopBit)

    Log.LogInfo("uartOpen url: ", url)
    -- @ initialize uart log file path
    local channelPlugin = SMTDataChannel.createChannelPlugin()
    -- Enable real-time logging of data chunk per read, without breaking output lines like default "pre-" log
    channelPlugin.setLogFilePath(workingDirectory .. "/kis.log")
    local baseChannel = CommBuilder.createBaseChannel(url)
    -- Device URL or ATKDataChannel created by other plugins like CommBuilder can be passed in here.
    local dataChannel = channelPlugin.createDataChannel(baseChannel)
    -- @ delay 100us for each character
    channelPlugin.setInterCharDelay(0.001)
    -- Pass data channel to CommBuilder
    local kisUart = CommBuilder.createCommPlugin(dataChannel)

    return kisUart
end

--! @brief: create virtual port object
local function createVirtualPort(deviceName, typeKey)
    local virtualPort = Atlas.loadPlugin("VirtualPort")
    local slotNum = string.match(deviceName, "S=%a*(%d+)")
    local slotID = "slot" .. slotNum
    local groupID = "group" .. string.match(deviceName, "G=(%d):")
    local apUartUrl = constants.VirtualPort[slotID][typeKey]["apUartUrl"]
    local vtMetaUrl = constants.VirtualPort[slotID][typeKey]["vtMetaUrl"]
    local vpLogDir = Group.getDeviceUserDirectory(deviceName)
    local vpLogPath = vpLogDir.."/"..typeKey.."_VirtualPort.log"
    local cinfig = "{\"uart_baud\":921600}"
    local topology = {
        groups = {{
            identifier = groupID,
            units = {{
                identifier = slotNum, 
                unit_transports = {{
                    url = apUartUrl, 
                    metadata = {virtualport = vtMetaUrl, virtualportconfig = cinfig}}}
                }}
            }
        }
    }
    virtualPort.setup({
        group_id = groupID, unit_id = slotNum, topology = topology, 
        loggingfolder = vpLogDir
    })
    return virtualPort, apUartUrl, vpLogPath
end

--! @brief: load uart/kis/tcp object
--! @return: plugins Table
local function loadCommPlugins(deviceName)
    local plugins = {}
    local slotNum = tonumber(string.match(deviceName, "([0-9]+)$"))
    local slotID = "slot" .. slotNum
    local userDir = Group.getDeviceUserDirectory(deviceName)

    --!@ Create Virtual Port object
    -- plugins["VirtualPort"] = Atlas.loadPlugin("VirtualPort")
    -- local virtualPort, apUartUrl, vpLogPath = createVirtualPort(deviceName, 'Diags')
    -- plugins["VirtualPort1"] = virtualPort
    -- plugins["DutUart"] = createComm(apUartUrl, vpLogPath)

    --!@ Create Uart object
    local uartURL = constants.StationURL[slotID].dutUartURL
    local USBUartURL = constants.StationURL[slotID].dutUSBCURL
    local commMuxURL = {
        Uart = uartURL,
        USBUart = USBUartURL
    }
    Log.LogInfo("DUT uart url: ", uartURL)
    Log.LogInfo("DUT USB uart url: ", USBUartURL)
    plugins = createComm(deviceName, commMuxURL)

    --!@ Create USBC object
    -- local rtLib = require("INVT/Modules/RTCommonLib")
    -- local macMiniType = rtLib.getMacMiniType()
    -- local usbcLogPath = userDir .. "/USBC.log"
    -- local usbcURL = constants.StationURL[slotID].dutUSBCURL
    -- Log.LogInfo("DUT USBC url: ", usbcURL)
    -- Log.LogInfo("Create uart log : ", usbcLogPath)
    -- plugins["USBC"] = createUSBComm(usbcURL, usbcLogPath)

    --!@ Create RP2 object
    -- local rp2LogPath = userDir .. "/rp2.log"
    -- local rp2URL = constants.RP2Port[slotID]
    -- Log.LogInfo("RP2Board url: ", rp2URL)
    -- Log.LogInfo("Create RP2Board log : ", rp2LogPath)
    -- local rp2Porxy = Atlas.loadPlugin("MPBPorxyFactory")
    -- rp2Porxy.setupWithURL(rp2URL, rp2LogPath)
    -- rp2Porxy.reset()
    -- rp2Porxy.callWithRaw("from MixDevice import *")
    -- rp2Porxy.call("mixdevice.reset")
    -- plugins["RP2Proxy"] = rp2Porxy

    --!@ Create CoreBoard object
    -- local coreLogPath = userDir .. "/rpc.log"
    -- local coreURL = topology["groups"][Group.index]["units"][slotNum]["CoreBoard"]
    -- local IP = comFunc.splitString(coreURL, ":")[1]
    -- coreURL = "tcp://".. coreURL
    -- Log.LogInfo("CoreBoard url: ", coreURL)
    -- Log.LogInfo("Create CoreBoard log : ", coreLogPath)
    -- runShellCmd.run("ping -c 1 -W 1 " .. IP)
    -- plugins["CoreBoard"] = createComm(coreURL, coreLogPath)

    --!@ Create KIS object
    -- local kisLogPath = userDir .. "/kis.log"
    -- local kisTab = topology["groups"][Group.index]["units"][slotNum]["KIS_PORT"]
    -- local kisPath = kisTab["url"]
    -- assert(kisPath ~= nil, "kisPath is nil")
    -- local baudRate = tostring(kisTab["baudrate"] or 921600)
    -- local dataBit = tostring(kisTab["databit"] or 8)
    -- local parity = kisTab["parity"] or 'N'
    -- local stopBit = tostring(kisTab["stopbits"] or 1)
    -- local kisURL = "uart://"..kisPath.."?baud="..baudRate.."&mode="..dataBit..parity..stopBit
    -- Log.LogInfo("kisURL url: ", kisURL)
    -- Log.LogInfo("Create kis log : ", kisLogPath)
    -- plugins["KIS"] = createComm(kisURL, kisLogPath, false)

    return plugins
end

--! @brief show platfrom message
function fixture.showMsg(msg, fontColor)
    local groupIndex = tonumber(Group.index) - 1
    if not fixture.InteractiveView then
        Log.LogInfo(msg)
        return
    end
    Log.LogInfo(msg)
    fixture.InteractiveView.showGroupView(groupIndex, {
        ["message"] = msg,
        ["messageColor"] = fontColor or "blue",
        ["messageFont"] = 18,
        ["messageAlignment"] = 0
    })
end

--! @brief show platfrom error
function fixture.showErr(errMsg)
    local groupIndex = tonumber(Group.index) - 1
    if not fixture.InteractiveView then
        error(errMsg)
    end
    fixture.InteractiveView.showGroupView(groupIndex, {
        ["message"] = errMsg,
        ["messageColor"] = "red",
        ["messageFont"] = 18,
        ["messageAlignment"] = 0
    })
    time.delay(2)
    error(errMsg)
end

--! @brief show platfrom alert
function fixture.showAlert(deviceIndex, msg, msgColor)
    if not fixture.InteractiveView then
        error(msg)
    end
    fixture.InteractiveView.showView(deviceIndex, {
        ["message"] = msg, 
        ["messageColor"] = msgColor or "red", 
        ["button"] = {"OK"}
    })
    time.delay(3)
    error(msg)
end

--! @brief Get version information 
--! @from setting file and then show it on UI.
function fixture.updateVersionInfo()
    Log.LogInfo("--------read Version Name-------")
    local bRet, limitVersion = xpcall(fixture.getGoatOverlayVersion, debug.traceback)
    if not bRet and limitVersion == nil then
        fixture.showErr("check the Limit Version fail")
    end
    Log.LogInfo("limitVersion: ", limitVersion)
    local verNameStr = "Ver : " .. limitVersion
    stationInfoTab.versionName =  verNameStr
    Group.updateInfo(stationInfoTab)
end

--! @brief calculate the test result and then show it on UI.
function fixture.updateTestResults(deviceName)
    Log.LogInfo("--------get the test results-------")
    stationInfoTab.inputCount = 0
    stationInfoTab.passCount = 0
    stationInfoTab.failCount = 0
    local unitTestResult = Group.getDeviceCurrentResult(deviceName)

    if unitTestResult >= 0 then
        stationInfoTab.inputCount = stationInfoTab.inputCount + 1
        Log.LogInfo("stationInfoTab.inputCount: ", stationInfoTab.inputCount)
        if unitTestResult == Group.overallResult.pass then
            stationInfoTab.passCount = stationInfoTab.passCount + 1
            Log.LogInfo("stationInfoTab.passCount: ", stationInfoTab.passCount)
        elseif unitTestResult == Group.overallResult.fail then
            stationInfoTab.failCount = stationInfoTab.failCount + 1
            Log.LogInfo("stationInfoTab.failCount: ", stationInfoTab.failCount)
        else
            Log.LogInfo("unitTestResult: ", unitTestResult)
        end
    end
    Group.updateInfo(stationInfoTab)
end

--! @brief: get version infomation from setting file and then show it on UI.
--! @return: string type, limitVersion
function fixture.getGoatOverlayVersion()
    return fixture.Constants.StationInfo["stationOverlay"]
end

--! @brief: get INVT vendor id
function fixture.getVendorID()
    Log.LogDebug("*****getVendorID*****")
    return "0x01:Teseco"
end

--! @brief fixture launcher
function fixture.launcher()
    local _Simulator = constants.Fixture.FIXTURE_TYPE == "simulator"
    --!@ quick start
    if _Simulator then return syncFixtureInfo({LauncherStatus=true}) end

    --!@ remove fixture Log
    local fixtureLogPath = "/vault/StreamFixture.log"
    if comFunc.fileExists(fixtureLogPath) then
        local _, retTab = xpcall(runShellCmd.run, debug.traceback, "wc -c ".. fixtureLogPath)
        fixtureLogSize = retTab.output:match("(.*) /vault/StreamFixture.log"):gsub(" ","")
        if tonumber(fixtureLogSize) > 100000000 then --100M 104857600
            os.execute("rm -f "..fixtureLogPath)
        end
    end

    --!@ remove atlas log
    local _, retVal, code = xpcall(removeAtlasTestLog, debug.traceback)

    --!@ remove tmp file
    local smPath = "/tmp/INVT_StateMachine.json"
    if comFunc.fileExists(smPath) then
        os.execute("rm -f "..smPath)
    end

    --!@ kill zombie process with run-logging-console
    xpcall(runShellCmd.run, debug.traceback, "ps -x | grep -v grep | grep run-logging-console | awk '{print $1}' | xargs kill -9")

    --!@ sync xavier
    local _RetA, retVal = xpcall(syncXavier, debug.traceback)
    if not _RetA and not _Simulator then
        Log.LogInfo("syncXavier Fail: ", retVal)
        syncFixtureInfo({message="Error:Sync Xavier RTC and IOMap Fail, please check the station!"})
    end

    --!@ check dut FW package
    -- local _RetB, retVal = xpcall(checkFirmwarePackage, debug.traceback)
    -- if not _RetB and not _Simulator then
    --     syncFixtureInfo({message="Error:Check Firmware Package MD5 Fail, please check the station!"})
    -- end

    local bRet = _RetA and true or _Simulator
    syncFixtureInfo({LauncherStatus=bRet, NeedFixtureInit=true})
    return bRet
end

--! @brief connect fixture
function fixture.connectFixture()
    --!@ automation is enable then skip it
    if fixture.automationEnabled then
        return true
    end
    fixture.showMsg("Connect Fixture")
    local fixtureControl = require("INVT/Modules/FixtureControl")
    local smTab = syncFixtureInfo()
    fixture.FixtureControl = fixtureControl
    local groupID = Group.index
    local bRet, msg = fixtureControl.connect(groupID)
    if not bRet then
        msg = msg or "Connect Fixture Fail"
        fixture.showErr("Error: "..msg..", Please check Fixture is exists!")
    elseif smTab.LauncherStatus == true and smTab.NeedFixtureInit == true then
        syncFixtureInfo({NeedFixtureInit=false})
    end
    --!@ clear prompting tips on UI
    fixture.showMsg(" ")
    return bRet
end

--! @brief fixture start test
function fixture.startTest(activeUnits)
    --!@ update ui status
    local loopConfig = fixture.InteractiveView.getLoopConfig()
    Log.LogInfo("LoopConfig: "..comFunc.dump(loopConfig))
    local loopMax = loopConfig["LoopMax"] or 1
    local loopCount = loopConfig["LoopCount_" .. Group.index - 1] or 0
    local loopAction = loopConfig["LoopFixtureInOut"] == nil or loopConfig["LoopFixtureInOut"] == 1
    stationInfoTab.loopMax = loopMax
    stationInfoTab.loopCount = loopCount + 1

    local smTab = syncFixtureInfo()
    local isLoopFinished = smTab["isLoopFinished"]

    --!@ if AUTO_START is false, shut be press double start button
    --!@ before press double start button, setting LED status
    if not constants.Fixture.AUTO_START then
        local fixtureControl = fixture.FixtureControl
        --!@ control LED
        for i=1, 4, 1 do fixtureControl.unitLED(i, "OFF") end
        for unit, _ in pairs(activeUnits) do
            fixtureControl.unitLED(tonumber(string.match(unit, "([0-9]+)$")), "BLUE")
        end
        fixtureControl.statusLED("BLUE")
        if isLoopFinished == 1 or isLoopFinished == nil then
            return true
        end
    end

    --!@ automation is enable then skip it
    if fixture.automationEnabled then
        return true
    --!@ check loop count
    elseif (loopMax - loopCount >= 1) and (loopCount ~= 0) and (not loopAction) then
        return true
    end

    fixture.showMsg("Waiting for fixture engagement!(等待治具下压)...")
    local fixtureControl = fixture.FixtureControl
    local bRet, msg = fixtureControl.startTest(activeUnits)
    if not bRet then
        fixture.showErr(msg)
    end
    --!@ clear prompting tips on UI
    fixture.showMsg(" ")
    return bRet
end

--! @brief fixture detect fixture engagement
function fixture.detectFixtureEngagement(detectStr)
    --!@ automation is enable then skip it
    if fixture.automationEnabled then
        return true
    end
    local fixtureControl = fixture.FixtureControl
    return fixtureControl.detectFixtureEngagement(detectStr)
end

--! @brief fixture end test
function fixture.endTest()
    local fixtureControl = fixture.FixtureControl
    return fixtureControl.endTest()
end

--! @brief fixture detect fixture double start button
function fixture.detectStartButton()
    local fixtureControl = fixture.FixtureControl
    return fixtureControl.detectStartButton()
end

--! @brief fixture read FirmWareVersion
function fixture.readFirmWareVersion()
    local fixtureControl = fixture.FixtureControl
    return fixtureControl.readFirmWareVersion()
end

--! @brief create rpc connect
function fixture.createRPCConnect(groupPlugins)
    local rpcRelay = groupPlugins["MIXRPCRelay"]
    --!@ example connect dut0 to xavier 169.254.1.32:7801
    rpcRelay.commands("connect(dut0,tcp://169.254.1.32:7801)", 3000)
    return true
end

--! @brief set fixture unitLED
function fixture.unitLED(deviceName)
    local fixtureControl = fixture.FixtureControl
    local slotNum = tonumber(string.match(deviceName, "([0-9]+)$"))
    local unitTestResult = Group.getDeviceCurrentResult(deviceName)
    if unitTestResult == Group.overallResult.pass then
        fixtureControl.unitLED(slotNum, "GREEN")
    else
        fixtureControl.unitLED(slotNum, "RED")
        fixture.overallResult = false
    end
    return true
end

--! @brief set fixture unitLED
function fixture.statusLED()
    local fixtureControl = fixture.FixtureControl
    fixtureControl.statusLED(fixture.overallResult and "GREEN" or "RED")
    return true
end

--! @check station is looping
function fixture.checkLooping()
    local smTab = syncFixtureInfo()
    local isLoopFinished = smTab["isLoopFinished"]
    local loopDuration = tonumber(smTab["LoopDuration"])
    loopDuration = loopDuration ~= nil and loopDuration or constants.LoopDuration
    if isLoopFinished == 0 then 
        local msg = "Loop test delay "..tostring(loopDuration).."mS..."
        fixture.showMsg(msg)
        time.delay(loopDuration/1000)
        fixture.showMsg(" ")
    end
end

--! @brief query all unit sn from panel sn
function fixture.getSnBypanelSN(panelSN)
    return error("Not implement")
end

--! @brief calling from GroupFunctions.setup on step 1
function fixture.loadGroupPlugins(resources, InteractiveView)
    Log.LogInfo("Load Teseco GroupPlugins")
    if not launchTime then
        local smTab = syncFixtureInfo()
        local persistedLaunchTime = smTab and smTab["atlasLaunchTime"] or nil
        if persistedLaunchTime and tostring(persistedLaunchTime) ~= "" then
            launchTime = tostring(persistedLaunchTime)
            isLaunchAtlas = false
        else
            launchTime = os.date("%Y-%m-%d_%H_%M_%S")
            isLaunchAtlas = true
            syncFixtureInfo({atlasLaunchTime = launchTime})
        end
    end
    local plugins = {}
    fixture.InteractiveView = InteractiveView

    --!@ update station info on UI
    fixture.updateVersionInfo()

    --!@ make sure fixture launcher is ready
    while true do
        local smTab = syncFixtureInfo()
        local LauncherStatus = smTab.LauncherStatus
        local message = smTab.message
        local fontColor = "blue"
        if tostring(message):lower():find("fail") or tostring(message):lower():find("error") then
            fontColor = "red"
        end
        if LauncherStatus == true then
            break
        elseif LauncherStatus == false then
            fixture.showErr(smTab.message)
        elseif message then
            fixture.showMsg(message, fontColor)
        end
        time.delay(0.25)
    end

    --!@ check login, if necessary
    if constants.NEED_LOGIN then
        while InteractiveView.showLogin do
            if InteractiveView.showLogin() then break end
        end
    end

    --!@ kill virtual port
    -- killVirtualPort()

    --!@ fixture connect
    fixture.connectFixture()
    local fixtureControl = fixture.FixtureControl
    plugins["FixtureControl"] = fixtureControl.pluginObj

    -- !@ Loading Morocco RPC plugin
    -- -- terminate remote process in case it's not terminated normally, e.g. manually clicked the stop test in AtlasUI
    -- terminateRemoteProcessWithRunningStatusCheck(globalRemoteProcessInstance)
    -- !@ Run MIXRPC plugin as a remote process
    -- globalRemoteProcessInstance, plugins["MIXRPCRelay"] = launchRemoteProcess('MIXRPCRelay')

    return plugins
end

--! @brief calling from GroupFunctions.getSlots on step 2, when testMode == VendorMode
function fixture.getSlots(InteractiveView, groupIndex, viewConfig)
    local bRet, output, msg, fMsg
    local activeUnits = {}
    local fixtureType = fixture.Constants.Fixture.FIXTURE_TYPE
    local smTab = syncFixtureInfo()
    local isLoopFinished = smTab["isLoopFinished"]

    if isLoopFinished == 0 or fixtureType == "simulator" then
        bRet = true
        output = InteractiveView.showGroupView(groupIndex, viewConfig)
    else
        local startTestAction = constants.Fixture.AUTO_START and "AUTO_START" or "DoubleStart"
        Log.LogInfo("[Start Test Action]: " .. tostring(startTestAction))
        InteractiveView.showGroupView(groupIndex, viewConfig, 0)
        while true do
            bRet = fixture.detectFixtureEngagement("AUTO_DONE")
            Log.LogInfo("[detectFixtureEngagement]: " .. tostring(bRet))
            if bRet then break end
        end
        bRet, output = xpcall(InteractiveView.dismissGroupView, debug.traceback, groupIndex)
        Log.LogInfo("[output]: " .. comFunc.dump(output))
    end
    --!@ check output
    output = type(output) == "table" and output or false
    if not bRet or not output then
        fixture.endTest()
        fixture.showErr("Pleace check output table is correct:"..comFunc.dump(output))
    end
    --!@ return activeUnits

    local allSlots = viewConfig["switch"]
    Log.LogInfo('output -> ' .. comFunc.dump(output))

    for _, unit in ipairs(allSlots) do
        if output[unit] == 1 then
            activeUnits[unit] = ""
        end
    end
    Log.LogInfo('activeUnits -> ' .. comFunc.dump(activeUnits))
    defaultUnits = activeUnits
    return activeUnits
end

--! @brief calling from DeviceFunctions.setup on step 3
function fixture.loadDevicePlugins(deviceName, groupPlugins)
    Log.LogInfo("Load INVT DevicePlugins")
    local plugins = {}
    local slot = tonumber(string.match(deviceName, "([0-9]+)$"))

    plugins["MixRPC"] = createRPCClient(deviceName)
    plugins["RTCommonLib"] = Atlas.loadPlugin("RTCommonLib")

    local dutCommPlugins = loadCommPlugins(deviceName)
    for name, instance in pairs(dutCommPlugins) do
        Log.LogInfo(">>>>>>>>>>>>>>:"..name)
        -- Log.LogInfo(">>>>>>>>>>>>>>:"..instance)
        plugins[name] = instance
    end

    return plugins
end

--! @brief calling from GroupFunctions.start on step 4
function fixture.groupStart(groupPlugins)
    Log.LogInfo("INVT groupStart")
    return true
end

--! @brief calling from GroupFunctions.stop on step 5
function fixture.groupStop(groupPlugins)
    Log.LogInfo("INVT GroupStop")
    local groupIndex = tonumber(Group.index) - 1
    local InteractiveView = groupPlugins.InteractiveView
    local isLoopFinished = InteractiveView.isLoopFinished(groupIndex)
    local loopConfig = InteractiveView.getLoopConfig()
    local loopAction = loopConfig["LoopFixtureInOut"] == 1
    local LoopDuration = loopConfig["LoopDuration"]
    local smTab = {loopAction=loopAction, isLoopFinished=isLoopFinished, LoopDuration=LoopDuration}
    syncFixtureInfo(smTab)
    if isLoopFinished == 1 or loopAction then
        fixture.endTest()
        Log.LogInfo('Loop action in/out set or Loop finished.')
    end
    --!@ When constants.NEED_GROUP_EXIT == false, need manual shutdown the group plugins
    if not constants.NEED_GROUP_EXIT then
        Log.LogInfo('Exiting current group script')

        local mutexPlugin = groupPlugins["MutexPlugin"]
        mutexPlugin.reset()

        if groupPlugins["MIXRPCRelay"] then
            -- We should not error out here,make sure to run the terminateRemoteProcess flow next cycle
            local status, ret = xpcall(groupPlugins["MIXRPCRelay"].shutdown, debug.traceback)
            if not status then
                Log.LogError("groupPlugins MIXRPCRelay shutdown failed,", ret)
            end
            -- NOTE: very important to terminate the remote process!!!
            terminateRemoteProcessWithRunningStatusCheck(globalRemoteProcessInstance)
        end
    end
    local dayCsvLogger = require("INVT/Modules/dayCsvLogger")
    local defaultGroups = 1
    Log.LogInfo("defaultUnits, defaultGroups: ", defaultUnits, defaultGroups)
    dayCsvLogger.createLogsForGroup(defaultUnits, defaultGroups, isLaunchAtlas, launchTime)
    isLaunchAtlas = false
    return true
end

--! @brief calling from DeviceFunctions.teardown on step 6
function fixture.shutdownDevicePlugins(deviceName, plugins)
    Log.LogInfo("INVT Shutdown DevicePlugins")
    fixture.updateTestResults(deviceName)
    local DutUart = plugins["UART"]
    local DutUSBC = plugins["USBC"]
    local RPCClient = plugins["MixRPC"]
    local AttributeKeyTable = plugins["AttributeKeyTable"]
    -- local MutexPlugin = plugins["MutexPlugin"]
    -- local VirtualPort = plugins["VirtualPort"]
    -- local VirtualPort1 = plugins["VirtualPort1"]
    --!@ reset plugins
    local isExists = true
    isExists = DutUart and DutUart.isOpened() == 1 and DutUart.close()
    isExists = DutUSBC and DutUSBC.isOpened() == 1 and DutUSBC.close()
    isExists = RPCClient and RPCClient.shutdown()
    isExists = AttributeKeyTable and AttributeKeyTable.shutdown()
    -- isExists = MutexPlugin and MutexPlugin.reset()
    -- !@ control fixture LED status
    fixture.unitLED(deviceName)
    -- isExists = VirtualPort and VirtualPort.teardown()
    -- isExists = VirtualPort1 and VirtualPort1.teardown()
    Log.LogInfo("Shutdown Finish!")
end

--! @brief calling from GroupFunctions.teardown on step 7
--! @if constants.NEED_GROUP_EXIT == false this func not invoke
function fixture.shutdownGroupPlugins(groupPlugins)
    Log.LogInfo("INVT Shutdown GroupPlugins")
    fixture.statusLED()
end

return fixture
