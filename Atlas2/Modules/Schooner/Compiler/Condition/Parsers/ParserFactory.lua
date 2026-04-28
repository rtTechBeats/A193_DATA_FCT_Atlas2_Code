local common = require('Schooner.SchoonerCommon')
local baseParser = require("Schooner.Compiler.Condition.Parsers.BaseParser")
local filterParser = require("Schooner.Compiler.Condition.Parsers.FilterParser")
local ModeParser = require("Schooner.Compiler.Condition.Parsers.ModeParser")
local EnableSamplingParser = require(
                             'Schooner.Compiler.Condition.Parsers.EnableSamplingParser')
local NoCLParser = require('Schooner.Compiler.Condition.Parsers.NoCLParser')

local ParserFactory = {}

local parsers = {
    [common.RESERVED_CONDITIONS.MODE] = ModeParser,
    [common.RESERVED_CONDITIONS.PRODUCT] = filterParser,
    [common.RESERVED_CONDITIONS.STATIONTYPE] = filterParser,
    [common.RESERVED_CONDITIONS.NOCL] = NoCLParser,
    [common.RESERVED_CONDITIONS.ENABLE_SAMPLING] = EnableSamplingParser
}

function ParserFactory.createParser(condition)
    return (parsers[condition.Name] or baseParser).new(condition)
end

return ParserFactory
