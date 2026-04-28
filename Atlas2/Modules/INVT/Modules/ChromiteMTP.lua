local ChromiteMTPCore = require("Internal/ChromiteMTPCore")
local ChromiteMTP = ChromiteMTPCore
local Log = require("Common/logging")


-- !@brief schooner CSV API
-- !@brief chromite vrect adc cal
-- !@param calTable table like {DMM = {5000,7500,1000}, ADC = {4995,7495,9995}}
-- !@return true or error out
function ChromiteMTP.chromiteVrectCal(calTable)
    -- local dieTemp = calTable["dieTemp"]
    --         print ("chromiteVrectCal dieTemp = ",dieTemp)
    local temp = calTable["temp1"]
    local status, result = xpcall(ChromiteMTPCore.chromiteVrectCalCore, debug.traceback, calTable, temp)
    if status and result then
        return true
    else
        local failMsg = tostring(result)
        Log.LogError(failMsg)
        error(failMsg)
    end
end

-- !@brief schooner CSV API
-- !@brief chromite isns adc cal
-- !@param calTable table like {DMM = {100,250,500}, ADC = {99,248,497}}
-- !@return true or error out
function ChromiteMTP.chromiteIsnsCal(calTable)
    -- local dieTemp = calTable["dieTemp"]
    --     print ("chromiteIsnsCal dieTemp = ",dieTemp)
    local temp = calTable["temp1"]
    local status, result = xpcall(ChromiteMTPCore.chromiteIsnsCalCore, debug.traceback, calTable, temp)
    if status and result then
        return true
    else
        local failMsg = tostring(result)
        Log.LogError(failMsg)
        error(failMsg)
    end
end

-- !@brief schooner CSV API
-- !@brief read chromite sector data
-- !@param sector number B747 FCT_SECTOR = 159
-- !@return true or error out
function ChromiteMTP.readSector(sector)
    local status, result = xpcall(ChromiteMTPCore.readSectorCore, debug.traceback, sector)
    if status and result then
        return true
    else
        local failMsg = tostring(result)
        Log.LogError(failMsg)
        error(failMsg)
    end
end


-- !@brief schooner CSV API
-- !@brief set up MTP data
-- !@return true or error out
function ChromiteMTP.setUpMTPData()
    local status, result = xpcall(ChromiteMTPCore.setUpMTPDataCore, debug.traceback)
    if status and result then
        return true
    else
        local failMsg = tostring(result)
        Log.LogError(failMsg)
        error(failMsg)
    end
end

-- !@brief schooner CSV API
-- !@brief organize FCT MTP DATA
-- !@return true or error out
function ChromiteMTP.organizeMTPData()
    local status, result = xpcall(ChromiteMTPCore.organizeMTPDataCore, debug.traceback)
    if status and result then
        return true
    else
        local failMsg = tostring(result)
        Log.LogError(failMsg)
        error(failMsg)
    end
end
-- !@brief schooner CSV API
-- !@brief burn FCT MTP DATA
-- !@return true or error out
function ChromiteMTP.burnMTPData()
    local status, result = xpcall(ChromiteMTPCore.burnMTPDataCore, debug.traceback)
    if status and result then
        return true
    else
        local failMsg = tostring(result)
        Log.LogError(failMsg)
        error(failMsg)
    end
end
local ActionHelper = require("SMTActionHelper")

local CSVInterfaceTable = {delegate = ChromiteMTP}

setmetatable(CSVInterfaceTable, ActionHelper.MetaTableFlowLogging)

return CSVInterfaceTable
