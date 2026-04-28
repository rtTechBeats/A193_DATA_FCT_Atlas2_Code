--[[---------------------------------
--Version : V1.0
--Author  : Yuekie
--Date    : 20230114
--Comment : First Relese
--]] ---------------------------------
----------------- Bit Operation -----------------
local MATRIX_AND = {{0, 0}, {0, 1}}
local MATRIX_XOR = {{0, 1}, {1, 0}}

local function operateBits(x, y, matrix)
    local z = 0
    local pow = 1
    while x > 0 or y > 0 do
        z = z + (matrix[x % 2 + 1][y % 2 + 1] * pow)
        pow = pow * 2
        x = math.floor(x / 2)
        y = math.floor(y / 2)
    end
    return z
end

local function lShift(data, sBits)
    return data * (2 ^ sBits);
end

local function XOR(data1, data2)
    return operateBits(data1, data2, MATRIX_XOR)
end

local function AND(data1, data2)
    return operateBits(data1, data2, MATRIX_AND)
end

local function reverse(data, bitSize)
    local revData = 0
    for i = 1, bitSize do
        revData = revData * 2 + (data % 2)
        data = math.floor(data / 2)
    end
    return revData
end

local function rShift(data, sBits)
    return math.floor(data / (2 ^ sBits));
end

----------------- CRC Caculation -----------------

local CRC = {}
local REVERSE = true
local NON_REVERSE = false

local crcModuleList = {
--   Name                 Identifier-name,    Poly            Reverse         Init-value  XOR-out     Check
    ["crc-8"]           = {'Crc8',            0x107,          NON_REVERSE,    0x00,       0x00,       0xF4},
    ["crc-8-darc"]      = {'Crc8Darc',        0x139,          REVERSE,        0x00,       0x00,       0x15},
    ["crc-8-i-code"]    = {'Crc8ICode',       0x11D,          NON_REVERSE,    0xFD,       0x00,       0x7E},
    ["crc-8-itu"]       = {'Crc8Itu',         0x107,          NON_REVERSE,    0x55,       0x55,       0xA1},
    ["crc-8-maxim"]     = {'Crc8Maxim',       0x131,          REVERSE,        0x00,       0x00,       0xA1},
    ["crc-8-rohc"]      = {'Crc8Rohc',        0x107,          REVERSE,        0xFF,       0x00,       0xD0},
    ["crc-8-wcdma"]     = {'Crc8Wcdma',       0x19B,          REVERSE,        0x00,       0x00,       0x25},

    ["crc-16"]          = {'Crc16',           0x18005,        REVERSE,        0x0000,     0x0000,     0xBB3D},
    ["crc-16-buypass"]  = {'Crc16Buypass',    0x18005,        NON_REVERSE,    0x0000,     0x0000,     0xFEE8},
    ["crc-16-dds-110"]  = {'Crc16Dds110',     0x18005,        NON_REVERSE,    0x800D,     0x0000,     0x9ECF},
    ["crc-16-dect"]     = {'Crc16Dect',       0x10589,        NON_REVERSE,    0x0001,     0x0001,     0x007E},
    ["crc-16-dnp"]      = {'Crc16Dnp',        0x13D65,        REVERSE,        0xFFFF,     0xFFFF,     0xEA82},
    ["crc-16-en-13757"] = {'Crc16En13757',    0x13D65,        NON_REVERSE,    0xFFFF,     0xFFFF,     0xC2B7},
    ["crc-16-genibus"]  = {'Crc16Genibus',    0x11021,        NON_REVERSE,    0x0000,     0xFFFF,     0xD64E},
    ["crc-16-maxim"]    = {'Crc16Maxim',      0x18005,        REVERSE,        0xFFFF,     0xFFFF,     0x44C2},
    ["crc-16-mcrf4xx"]  = {'Crc16Mcrf4xx',    0x11021,        REVERSE,        0xFFFF,     0x0000,     0x6F91},
    ["crc-16-riello"]   = {'Crc16Riello',     0x11021,        REVERSE,        0x554D,     0x0000,     0x63D0},
    ["crc-16-t10-dif"]  = {'Crc16T10Dif',     0x18BB7,        NON_REVERSE,    0x0000,     0x0000,     0xD0DB},
    ["crc-16-teledisk"] = {'Crc16Teledisk',   0x1A097,        NON_REVERSE,    0x0000,     0x0000,     0x0FB3},
    ["crc-16-usb"]      = {'Crc16Usb',        0x18005,        REVERSE,        0x0000,     0xFFFF,     0xB4C8},
    ["x-25"]            = {'CrcX25',          0x11021,        REVERSE,        0x0000,     0xFFFF,     0x906E},
    ["xmodem"]          = {'CrcXmodem',       0x11021,        NON_REVERSE,    0x0000,     0x0000,     0x31C3},
    ["modbus"]          = {'CrcModbus',       0x18005,        REVERSE,        0xFFFF,     0x0000,     0x4B37},

    -- Note definitions of CCITT are disputable. See:
    --    http://homepages.tesco.net/~rainstorm/crc-catalogue.htm
    --    http://web.archive.org/web/20071229021252/http://www.joegeluso.com/software/articles/ccitt.htm
    -- CRC online computing website:
    --    https://crccalc.com/
--   Name                   Identifier-name,      Poly            Reverse         Init-value  XOR-out     Check
    ["kermit"]              = {'CrcKermit',      0x11021,         REVERSE,        0x0000,     0x0000,     0x2189},
    ["crc-ccitt-false"]     = {'CrcCcittFalse',  0x11021,         NON_REVERSE,    0xFFFF,     0x0000,     0x29B1},
    ["crc-aug-ccitt"]       = {'CrcAugCcitt',    0x11021,         NON_REVERSE,    0x1D0F,     0x0000,     0xE5CC},
    ["crc-24"]              = {'Crc24',          0x1864CFB,       NON_REVERSE,    0xB704CE,   0x000000,   0x21CF02},
    ["crc-24-flexray-a"]    = {'Crc24FlexrayA',  0x15D6DCB,       NON_REVERSE,    0xFEDCBA,   0x000000,   0x7979BD},
    ["crc-24-flexray-b"]    = {'Crc24FlexrayB',  0x15D6DCB,       NON_REVERSE,    0xABCDEF,   0x000000,   0x1F23B8},
    ["crc-32"]              = {'Crc32',          0x104C11DB7,     REVERSE,        0xFFFFFFFF, 0xFFFFFFFF, 0xCBF43926},
    ["crc-32-bzip2"]        = {'Crc32Bzip2',     0x104C11DB7,     NON_REVERSE,    0xFFFFFFFF, 0xFFFFFFFF, 0xFC891918},
    ["crc-32c"]             = {'Crc32C',         0x11EDC6F41,     REVERSE,        0xFFFFFFFF, 0xFFFFFFFF, 0xE3069283},
    ["crc-32d"]             = {'Crc32D',         0x1A833982B,     REVERSE,        0xFFFFFFFF, 0xFFFFFFFF, 0x87315576},
    ["crc-32-mpeg-2"]       = {'Crc32Mpeg2',     0x104C11DB7,     NON_REVERSE,    0xFFFFFFFF, 0x00000000, 0x0376E6E7},
    ["posix"]               = {'CrcPosix',       0x104C11DB7,     NON_REVERSE,    0x00000000, 0xFFFFFFFF, 0x765E7680},
    ["crc-32q"]             = {'Crc32Q',         0x1814141AB,     NON_REVERSE,    0x00000000, 0x00000000, 0x3010BF7F},
    ["jamcrc"]              = {'CrcJamCrc',      0x104C11DB7,     REVERSE,        0xFFFFFFFF, 0x00000000, 0x340BC6D9},
    ["crc-32-xfer"]         = {'Crc32Xfer',      0x1000000AF,     NON_REVERSE,    0x00000000, 0x00000000, 0xBD0BE338},
    ["crc-32-mef"]          = {'Crc32Mef',       0x1741B8CD7,     REVERSE,        0xFFFFFFFF, 0x00000000, 0xD2C22F51},
    ["crc-32-autosar"]      = {'Crc32AutoSar',   0x1F4ACFB13,     REVERSE,        0xFFFFFFFF, 0xFFFFFFFF, 0x1697D06A},
    ["crc-32-cd-rom-edc"]   = {'Crc32CdRomEdc',  0x18001801B,     REVERSE,        0x00000000, 0x00000000, 0x6EC2EDC4},

    -- 64-bit
--   Name                  Identifier-name,   Poly                    Reverse         Init-value          XOR-out             Check
    ["crc-64"]           = {'Crc64',          0x1000000000000001B,    REVERSE,        0x0000000000000000, 0x0000000000000000, 0x46A5A9388A5BEFFE},
    ["crc-64-we"]        = {'Crc64We',        0x142F0E1EBA9EA3693,    NON_REVERSE,    0x0000000000000000, 0xFFFFFFFFFFFFFFFF, 0x62EC59E3F1A4F00A},
    ["crc-64-jones"]     = {'Crc64Jones',     0x1AD93D23594C935A9,    REVERSE,        0xFFFFFFFFFFFFFFFF, 0x0000000000000000, 0xCAA717168609F281},
}

local function makeEnquiryTable(poly, bitSize)
    local CRCDataTable = {};
    local CRCLog = "local CRCDataTable = {\r\n";
    local mask = lShift(0x1, bitSize) - 1
    local filter = lShift(0x1, bitSize - 1)
    for i = 0, 255 do
        local CRCData = lShift(i, bitSize - 8);
        for j = 1, 8 do
            if AND(CRCData, filter) > 0 then
                CRCData = XOR(lShift(CRCData, 1), poly)
            else
                CRCData = lShift(CRCData, 1);
            end
        end

        CRCData = AND(CRCData, mask);
        CRCDataTable[i + 1] = CRCData;
        -- local tip = string.format("data : 0x%02x CRC : 0x%04x",i,CRCData);
        -- print(tip);

        if (i + 1) % 8 == 1 then
            CRCLog = CRCLog .. "\t";
        end

        CRCLog = CRCLog .. string.format("0x%04x,", CRCData);
        if (i + 1) % 8 == 0 then
            CRCLog = CRCLog .. "\r\n";
        end
    end

    CRCLog = CRCLog .. "};\r\n";
    -- print(CRCLog);

    return CRCDataTable;
end

local function verifyPoly(poly)
    local sizeArr = {8, 16, 24, 32, 64}
    for _, v in ipairs(sizeArr) do
        local base = lShift(0x1, v)
        if poly < base * 2 then
            return AND(poly, base - 1), v;
        end
    end

    assert(false, "invalid poly parameter: " .. tostring(poly))
end

--[[
Description:
    A common function for CRC calculate, this function may take long time.

Params:
    dataTable: raw data table need be calculated by CRC
    poly : polynomial of CRC, such as 0x11021 match x^16 + x^12 + x^5 + x^0.
    initCRC : the inital value of CRC, such as 0x0000.
    reverseIn : if reverse input data
    reverseOut : if reverse output data
    xorOut : the value need to be XOR into CRC, such as 0x0000.

Returns:
    number : CRC calculate value.

Usage:
    CRC.computeData({0x20, 0x30}, 0x11021, 0x0000, flase, false, 0x0000)

History:
    2023-01-14 Yuekie.Qi: First version.
--]]
function CRC.computeData(dataTable, poly, initCRC, reverseIn, reverseOut, xorOut)

    if dataTable == nil or type(dataTable) ~= "table" or #dataTable == 0 then
        error("Invalid dataTable input, please check.")
    end

    local bitSize = 0
    poly, bitSize = verifyPoly(poly)
    local mask = lShift(0x1, bitSize) - 1
    local filter = lShift(0x1, bitSize - 1)
    local CRCData = initCRC;
    for _, v in ipairs(dataTable) do
        -- print(i)
        local inputData = reverseIn and reverse(v, 8) or v
        inputData = lShift(inputData, bitSize - 8);
        CRCData = XOR(inputData, CRCData);
        for i = 1, 8 do
            -- print(i)
            if AND(CRCData, filter) > 0 then
                CRCData = lShift(CRCData, 1)
                CRCData = XOR(CRCData, poly)
            else
                CRCData = lShift(CRCData, 1);
            end
        end

        CRCData = AND(CRCData, mask);
    end

    if reverseOut then
        CRCData = reverse(CRCData, bitSize)
    end

    if xorOut ~= nil and type(xorOut) == "number" then
        CRCData = XOR(CRCData, xorOut)
    end

    return CRCData;
end

--[[
Description:
    For creating CRC calculate function, it's better invoke this API during code initial.

Params:
    poly : polynomial of CRC, such as 0x11021 match x^16 + x^12 + x^5 + x^0.
    initCRC : the inital value of CRC, such as 0x0000.
    reverseIn : if reverse input data
    reverseOut : if reverse output data
    xorOut : the value need to be XOR into CRC, such as 0x0000.

Returns:
    function : CRC calculate function.

Usage:
    CRC.makeCRCFunc(0x11021, 0x0000, flase, false, 0x0000)

History:
    2023-01-14 Yuekie.Qi: First version.
--]]
function CRC.makeCRCFunc(poly, initCRC, reverseIn, reverseOut, xorOut)
    local bitSize = 0
    poly, bitSize = verifyPoly(poly)
    local enquiryTable = makeEnquiryTable(poly, bitSize)
    return function(dataTable)

        if dataTable == nil or type(dataTable) ~= "table" or #dataTable == 0 then
            error("Invalid dataTable input, please check.")
        end

        local CRCData = initCRC;
        local mask = lShift(0x1, bitSize) - 1
        for _, v in ipairs(dataTable) do
            local index = rShift(CRCData, bitSize - 8);
            index = XOR(reverseIn and reverse(v, 8) or v, index);
            CRCData = lShift(CRCData, 8);
            CRCData = XOR(enquiryTable[index + 1], CRCData);
            CRCData = AND(CRCData, mask);
        end

        if reverseOut then
            CRCData = reverse(CRCData, bitSize)
        end

        if xorOut ~= nil and type(xorOut) == "number" then
            CRCData = XOR(CRCData, xorOut)
        end

        return CRCData;
    end
end

--[[
Description:
    For creating CRC calculate function, it's better invoke this API during code initial.

Params:
    crcModule: crc module name, which are defined in 'crcModuleList' table

Returns:
    function : CRC calculate function.

Usage:
    CRC.makePredefineFunc("crc-32")

History:
    2023-01-14 Yuekie.Qi: First version.
--]]
function CRC.makePredefineFunc(crcModule)
    local moduleData = crcModuleList[crcModule]
    assert(moduleData, tostring(crcModule) .. " is not predefine")

    local unpack = unpack or table.unpack
    -- Identifier-name Poly Reverse Init-value XOR-out Check
    local name, poly, reverse, initCRC, xorOut, check = unpack(moduleData)
    return CRC.makeCRCFunc(poly, initCRC, reverse, reverse, xorOut);
end

------------------ test code ------------------
-- print(CRC.computeData({0x03,0x11},0x8005,0x0000,true,true,0x0000))
-- print(CRC.computeData({0x03,0x11},0x1021,0x0000,true,true,0x78AB))
-- print(CRC.computeData({0x03,0x11},0x1021,0xFFFF,false,false,0x78AB))
-- print(CRC.computeData({0x03,0x11},0x104C11DB7,0x00000000,true,true,0xFFFFFFFF))

-- local crcFunc = CRC.makeCRCFunc(0x1021, 0x0000, true, true, 0x0000)
-- print(crcFunc({0x03, 0x11}))

-- local crcFunc2 = CRC.makeCRCFunc(0x1021, 0xFFFF, false, false, 0x0000)
-- print(crcFunc2({0x03, 0x11}))

-- local crcFunc3 = CRC.makePredefineFunc("crc-32")
-- print(crcFunc3({0x03, 0x11}))
------------------ test code ------------------

return CRC
