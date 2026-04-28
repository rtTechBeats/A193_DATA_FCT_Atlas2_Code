local Process = {}

local Helper = require("INVT/Modules/SMTLoggingHelper")
local DutCmd = require("INVT/Modules/DutCmdCore")
local PluginsLoader = require("INVT/Modules/PluginsLoader")
local dut = PluginsLoader.getPlugin("UART")
local Utilities = Device.getPlugin("Utilities")
local rtLib = require("INVT/Modules/RTCommonLib")


local myOverrideTable = {}
myOverrideTable.getSN = function()
    if dut.isOpened() ~= 1 then
        dut.open()
    end

    local expectedKeyWord = "syscfg:ok"
    local bRet, ret = xpcall(DutCmd.sendRead, debug.traceback,
                             "syscfg print MLB#", 3, expectedKeyWord, "\n]",
                             true)
    if not bRet or not ret then
        error('Error: Read MLB SN Fail! ' .. "Return value is:" .. tostring(ret))
    end
    Helper.LogFlowDebug("mlbSerialNumber:" .. ret)

    return ret
end

myOverrideTable.getNonce = function(_)
    -- local dut = Device.getPlugin("DutUart")
    if dut.isOpened() ~= 1 then
        dut.open()
    end

    local expectedKeyWord = "cb:ok"
    local bRet, ret = xpcall(DutCmd.sendRead, debug.traceback,
                             "cb nonce", 3, expectedKeyWord, "\n]")
    Helper.LogFlowDebug("get cb nonce result:" .. ret)
    if not bRet or not ret then
        error('Error: get cb nonce Fail! ' .. "Return value is:" ..
                  tostring(ret))
    end

    local pattern = "cb:ok (.*)\n"
    local cbNonceVal = string.match(ret, pattern)
    if cbNonceVal == nil then
        error('Error: get cb Nonce Value Fail! ' .. "Return value is:" ..
                  tostring(cbNonceVal))
    end

    Helper.LogFlowDebug("get cb nonce result:" .. cbNonceVal)
    Helper.LogFlowDebug("get cb nonce result type:" .. type(cbNonceVal))

    local retVal = Utilities.dataFromHexString(cbNonceVal)
    Helper.LogFlowDebug("get cb nonce result type:" .. type(retVal))

    return retVal
end

myOverrideTable.readCBStatus = function(offset)
    if dut.isOpened() ~= 1 then
        dut.open()
    end

    local expectedKeyWord = "cb:ok"
    local bRet, ret = xpcall(DutCmd.sendRead, debug.traceback,
                             "cb read " .. offset, 3, expectedKeyWord, "\n]")
    if not bRet or not ret then
        error('Error: read cb status Fail! ' .. "Return value is:" ..
                  tostring(ret))
    end

    local retCBStatus = {P = 0, I = 1, F = 2, U = 3}
    local pattern = "cb:ok %d+ %d+ %d+ %d+ %d+ (%S).*"
    local cbStatus = string.match(ret, pattern)
    if cbStatus == nil then
        error('Error: parser cb result status Fail! ' .. "Return value is:" ..
                  tostring(cbStatus))
    end
    Helper.LogFlowDebug("get cb reslut status:" .. cbStatus)

    return tonumber(retCBStatus[tostring(cbStatus)])
end

myOverrideTable.readCBFailCount = function(offset)
    if dut.isOpened() ~= 1 then
        dut.open()
    end

    local expectedKeyWord = "cb:ok"
    local bRet, ret = xpcall(DutCmd.sendRead, debug.traceback,
                             "cb read " .. offset, 3, expectedKeyWord, "\n]")
    if not bRet or not ret then
        error('Error: Read cb status fail! ' .. "Return value is:" ..
                  tostring(ret))
    end

    local pattern = "cb:ok %d+ %d+ %d+ %d+ (.*) %S+"
    local failCount = string.match(ret, pattern)
    if failCount == nil then
        error('Error: Parser cb failcount fail! ' .. "Return value is:" ..
                  tostring(failCount))
    end
    Helper.LogFlowDebug("read cb failcount:" .. failCount)

    return tonumber(failCount)
end

myOverrideTable.writeCB = function(offset, status, response, _)
    if dut.isOpened() ~= 1 then
        dut.open()
    end
    Helper.LogFlowDebug("get cb response result:" .. tostring(response))
    Helper.LogFlowDebug("get cb response result type:" .. type(response))

    -- 2022-01-19 00:00:26.651268: DUT_3: split:8 bytes, sendSplitCMD [send]: cb write 1 b37361f95e21488f303a8e8e674f4be2ac3bb606 1642518026 10151 P
    -- 2022-01-19 00:00:26.795021: DUT_3: read_until: cb write 1 b37361f95e21488f303a8e8e674f4be2ac3bb606 1642518026 10151 P
    -- > cb:ok
    -- ]
    local arrayCBStatus = {"P", "I", "F", "U"}
    local cbCmd
    if status == 0 then
        if tostring(response) == nil then
            error('Error: response fail! ' .. "Return value is:" ..
                      tostring(response))
        end
        Helper.LogFlowDebug("response value:" .. tostring(response))

        -- local keyResponse=nil
        -- for k,v in pairs(response) do
        --     if k == "bytes" then
        --         keyResponse = Utilities.dataToHexString(v)
        --         break
        --     end
        -- end
        -- local pattern = "0x(.*)"
        -- local keyVal = string.match(tostring(keyResponse), pattern)

        local passWordSource = tostring(response)
        local keyVal = string.sub(passWordSource, 25, 64) -- get the password from Atlas2 lib : {length = 20, bytes = 0x06f20f6c2de663dbc302af9da3f7260f71e132e5}
        if keyVal == nil then
            error('Error: parser password key value fail! ' ..
                      "Return value is:" .. tostring(keyVal))
        end
        Helper.LogFlowDebug("get cb keyVal result:" .. tostring(keyVal))

        cbCmd = "cb write " .. offset .. " " .. keyVal .. " 1646129906 0 " ..
                    arrayCBStatus[status + 1]
    else
        cbCmd = "cb write " .. offset ..
                    " 0000000000000000000000000000000000000000 1646129906 0 " ..
                    arrayCBStatus[status + 1]
    end

    Helper.LogFlowDebug("CB command :" .. tostring(cbCmd))

    local expectedKeyWord = "cb:ok"
    local bRet, ret = xpcall(DutCmd.sendRead, debug.traceback,
                             cbCmd, 3, expectedKeyWord)
    if not bRet or not ret then
        error('Error: Send write CB fail! ' .. "Return value is:" ..
                  tostring(ret))
    end

    return
end

-- Process Control Start
-- Read SN
-- Call getControlBitsToCheck to check CB and fail count
-- Write incomplete CB
function Process.startCB(paraTab)
    if dut == nil then
        local failureMsg = 'dut plugin ' .. tostring(dut) .. ' not found.'
        Helper.createBinaryRecord(false, paraTab.Technology,
                                  paraTab.TestName .. paraTab.testNameSuffix,
                                  paraTab.AdditionalParameters.subsubtestname,
                                  failureMsg, rtLib.trimValueStr(dut))
        Matchbox.reportFailure(failureMsg)
    end

    local category = paraTab.AdditionalParameters.category
    Helper.LogFlowDebug('Starting process control')
    if dut.isOpened() ~= 1 then
        dut.open()
    end
    if category ~= nil and category ~= '' then
        ProcessControl.start(dut, category)
    else
        ProcessControl.start(dut, myOverrideTable)
        -- ProcessControl.start(dut)
    end
end

-- Process Control finish
-- Read SN and compare SN
-- Write CB pass or fail
function Process.finishCB(paraTab)
    -- do not finish CB if not started.
    local inProgress = ProcessControl.inProgress()
    -- 1: started; 0: not started or finished.
    if inProgress == 0 then
        Helper.LogFlowDebug(
            'Process control finished or not started; skip finishCB.')
        return
    end

    if dut.isOpened() ~= 1 then
        dut.open()
    end
    -- if dut == nil then error('DUT plugin '..tostring(paraTab.Input)..' not found.') end
    if dut == nil then
        local failureMsg = 'DUT plugin ' .. tostring(dut) .. ' not found.'
        Helper.createBinaryRecord(false, paraTab.Technology,
                                  paraTab.TestName .. paraTab.testNameSuffix,
                                  paraTab.AdditionalParameters.subsubtestname,
                                  failureMsg, rtLib.trimValueStr(dut))
        Matchbox.reportFailure(failureMsg)
    end
    Helper.LogFlowDebug('Finishing process control')

    -- read Poison flag from Input
    local Poison = paraTab.Input
    if Poison == 'TRUE' then
        Helper.LogFlowDebug('Poison requested; poisoning CB.')
        ProcessControl.poison(dut, myOverrideTable)
        -- ProcessControl.poison(dut)
    end
    Helper.LogFlowDebug('Finishing process control', myOverrideTable)
    ProcessControl.finish(dut, myOverrideTable)
    -- ProcessControl.finish(dut)
end

return Process
