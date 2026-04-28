local UnitTool = {}
local unit_exponents = {
    LENGTH = {NM = -9, UM = -6, MM = -3, CM = -2, M = 0},
    VOLTAGE = {NV = -9, UV = -6, MV = -3, V = 0},
    CURRENT = {NA = -9, UA = -6, MA = -3, A = 0},
    POWER = {UW = -6, MW = -3, W = 0},
    FREQUENCY = {HZ = 0, KHZ = 3, MHZ = 6, GHZ = 9},
    RESISTANCE = {MOHM = -3, OHM = 0, KOHM = 3},
    INDUCTANCE = { NH = -9, UH = -6,  MH= -3, H = 0},
    CAPACITANCE = { PF = -12, NF = -9, UF = -6,  MF= -3, F = 0},
    TIME = {S = 0, MS = -3, US = -6, NS = -9},
    PEAK_VOLTAGE = {VPP = 0, MVPP = -3},
    BYTE = {B = 0, KB = 1, MB = 2, GB = 3, TB = 4}
}

function UnitTool.convertUnit(value, from_units, to_units)
    if from_units == nil or to_units == nil or tonumber(value) == nil then
        error("Parameter is Empty.")
    end

    local from_u, to_u = nil, nil
    for _, v in pairs(unit_exponents) do
        from_u = v[string.upper(from_units)]
        to_u = v[string.upper(to_units)]
        if from_u and to_u then
            break
        end
    end

    if from_u == nil or to_u == nil then
        error('Parameter not accept Invalid units!')
    end

    local delta_exponent = from_u - to_u
    return tonumber(value) * (10 ^ delta_exponent)
end

return UnitTool
