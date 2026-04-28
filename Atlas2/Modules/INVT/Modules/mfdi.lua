local helper = require('Common/logging')
local mfdiCore = require("Internal/MIXCore/mfdiCore")
local mfdi = {}

-----------------------mfdi-----------------------
function mfdi.mfdiI2CConnect(params)
    local scl = params.SCL
    local sda = params.SDA
    local ioVoltage = params.ioVoltage
    local mode = string.lower(params.mode)
    local slaveAddress = params.slaveAddress
    local slaveSpeed = params.slaveSpeed
    local status, result = xpcall(mfdiCore.mfdiI2CConnect, debug.traceback, mode, ioVoltage, slaveAddress, slaveSpeed,
                                  {scl, sda})
    if status and result then
        return result
    else
        helper.LogError("mfdiI2CConnect failed, :", result)
        return false
    end
end

function mfdi.mfdiPDMConnect(params)
    local clk = params.CLK
    local data = params.DATA
    local ioVoltage = params.ioVoltage
    local status, result = xpcall(mfdiCore.mfdiPDMConnect, debug.traceback, ioVoltage, {nil, nil, clk, data})
    if status and result then
        return result
    else
        helper.LogError("mfdiPDMConnect failed, :", result)
        return false
    end
end

function mfdi.mfdiDisconnect(params)
    local mode = string.upper(params.mode)
    local io = params.IO
    local nets = params.nets
    local tbl = {}
    for word in string.gmatch(nets, "'(.-)'") do
        table.insert(tbl, word)
    end
    local status, result = xpcall(mfdiCore.mfdiDisconnect, debug.traceback, mode, io, tbl)
    if status and result then
        return result
    else
        helper.LogError("mfdiDisconnect failed, :", result)
        return false
    end
end

function mfdi.mfdiI2CWrite(params)
    local slave = params.slave
    local address = params.address
    local data = params.data
    local status, result = xpcall(mfdiCore.i2cWrite, debug.traceback, slave, address, data)
    if status and result then
        return result
    else
        helper.LogError("mfdiI2CWrite failed, :", result)
        return false
    end
end

function mfdi.mfdiI2CRead(params)
    local slave = params.slave
    local address = params.address
    local length = params.length
    local format = params.format
    local status, result = xpcall(mfdiCore.i2cRead, debug.traceback, slave, address, length, format)
    if status and result then
        return result
    else
        helper.LogError("mfdiI2CRead failed, :", result)
        return false
    end
end

function mfdi.mfdiSPIConnect(params)
    local mosi = params.MOSI
    local miso = params.MISO
    local sclk = params.SCLK
    local cs = params.CS
    local ioVoltage = params.ioVoltage
    local mode = params.mode
    local spiMode = params.spiMode
    local speed = params.speed or 10000000
    local status, result
    if mode == "master" then
        status, result = xpcall(mfdiCore.mfdiSPIConnect, debug.traceback, mode, ioVoltage, spiMode,
                                  {mosi, cs, sclk, miso}, speed)
    elseif mode == "slave" then
        status, result = xpcall(mfdiCore.mfdiSPIConnect, debug.traceback, mode, ioVoltage, spiMode,
                                  {mosi, cs, sclk, miso}, speed)
    elseif mode == "slave_and_write" then
        status, result = xpcall(mfdiCore.mfdiSPIConnect, debug.traceback, mode, ioVoltage, spiMode,
                                  {mosi, cs, sclk, miso}, speed)
    elseif mode == "master_3wire" then
        status, result = xpcall(mfdiCore.mfdiSPIConnect, debug.traceback, mode, ioVoltage, spiMode,
                                  {nil, miso, sclk, cs}, speed)
    end
    if status and result then
        return result
    else
        helper.LogError("mfdiSPIConnect failed, ", result)
        return false
    end
end

function mfdi.mfdiSPIWrite(params)
    local data = params.data
    local mode = params.mode
    local status, result
    if mode == "master_3wire" then
        status, result = xpcall(mfdiCore.spiWrite_3wire, debug.traceback, data)
    else
        status, result = xpcall(mfdiCore.spiWrite, debug.traceback, data)
    end
    if status and result then
        return result
    else
        helper.LogError("mfdiSPIWrite failed, ", result)
        return false
    end
end

function mfdi.mfdiSPIRead(params)
    local data = params.data
    local length = params.len
    local status, result = xpcall(mfdiCore.spiRead, debug.traceback, data, length)
    if status and result then
        return result
    else
        helper.LogError("mfdiSPIRead failed, ", result)
        return false
    end
end

function mfdi.mfdiSPIWriteRead(params)
    local data = params.data
    local length = params.length
    local status, result = xpcall(mfdiCore.mfdiSPIWriteRead, debug.traceback, data, length)
    if status and result then
        return result
    else
        helper.LogError("mfdiSPIWriteRead failed, ", result)
        return false
    end
end

function mfdi.mfdiSWDConnect(params)
    local swclk = params.SWCLK
    local swdio = params.SWDIO
    local ioVoltage = params.ioVoltage
    local freq = params.freq or 100000
    local status, result = xpcall(mfdiCore.mfdiSWDConnect, debug.traceback, ioVoltage, freq, {swclk, swdio})
    if status and result then
        return result
    else
        helper.LogError("mfdiSWDConnect failed, ", result)
        return false
    end
end

function mfdi.mfdiSWDWrite(params)
    local port = params.port
    local apsel = params.apsel or 0
    local address = params.addr or 0
    local value = params.value
    local baseAddr = params.baseAddr or 0x40010000
    local mode = params.mode or "8bit"
    local csw = params.csw
    local status, result = xpcall(mfdiCore.swdWrite, debug.traceback, port, apsel, address, value, baseAddr, mode, csw)
    if status and result then
        return result
    else
        helper.LogError("mfdiSWDWrite failed, ", result)
        return false
    end
end

function mfdi.mfdiSWDRead(params)
    local port = params.port
    local apsel = params.apsel or 0
    local address = params.addr or 0
    local baseAddr = params.baseAddr or 0x40010000
    local mode = params.mode or "8bit"
    local csw = params.csw or nil
    local status, result = xpcall(mfdiCore.swdRead, debug.traceback, port, apsel, address, baseAddr, mode, csw)
    if status and result then
        return result
    else
        helper.LogError("mfdiSWDRead failed, ", result)
        return false
    end
end

function mfdi.mfdiGPO(params)
    local net = params.net
    local ioVoltage = params.ioVoltage
    local io = params.IO
    local duty = params.duty
    local output = params.output
    local mode = params.mode
    local status, result = xpcall(mfdiCore.mfdiGPO, debug.traceback, io, net, ioVoltage, output, mode, duty)
    if status and result then
        return result
    else
        helper.LogError("mfdiGPO failed, ", result)
        return false
    end
end

function mfdi.fpgaGPO(params)
    local io = params.IO
    local duty = params.duty
    local output = params.output
    local status, result = xpcall(mfdiCore.fpgaGPO, debug.traceback, io, output, duty)
    if status and result then
        return result
    else
        helper.LogError("fpgaGPO failed, ", result)
        return false
    end
end

-- function alias
-- !@brief Matchbox CSV API
-- !@brief diags command need to return result if params output is existed

local ActionHelper = require("SMTActionHelper")

local CSVInterfaceTable = {delegate = mfdi}

setmetatable(CSVInterfaceTable, ActionHelper.MetaTableFlowLogging)

return CSVInterfaceTable
