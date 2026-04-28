-------------------------------------------------------------------
----***************************************************************
---- User Time Plugin
----***************************************************************
-------------------------------------------------------------------
local helper = require("INVT/Modules/SMTLoggingHelper")

local M = {}

local function getPlugin()
    if Device then
        local status, plugin = xpcall(Device.getPlugin, debug.traceback, "TimeUtility")
        if status then
            return plugin
        else
            return Atlas.loadPlugin("SMTCommonPlugin").createTimeUtility()
        end
    else
        return Atlas.loadPlugin("SMTCommonPlugin").createTimeUtility()
    end
end

M.timeUtil = getPlugin()

--! @brief sleep time duration, unit is second
function M.sleep(duration)
    M.timeUtil.delay(duration)
end

--! @brief sleep time duration, unit is millisecond
function M.sleep_ms(time_in_ms)
    M.timeUtil.delay(time_in_ms / 1000)
end

--! @brief only one thread is allowed to sleep at one time
function M.staggerDelay(time_in_ms)
    local mutex = require("mutex")
    local _mutex_plugin = Device.getPlugin("MutexPlugin")
    local id = "identifier-for-stagger-delay"
    mutex.runWithLock(_mutex_plugin, id, M.delay, time_in_ms)
end

--! @brief unix timeStamp
function M.time()
    return M.timeUtil.getTimeStamp()
end

--! @brief system timeZone
function M.systemTimeZone()
    return M.timeUtil.getSystemTimeZone()
end

--! @brief start record duration time with identifier
function M.tick(identifier)
    local id = identifier or "TimeID"
    return M.timeUtil.tickWithIdentifier(id)
end

--! @brief stop record duration time with identifier
function M.tock(identifier)
    local id = identifier or "TimeID"
    return M.timeUtil.tockWithIdentifier(id)
end

--! @brief timeStamp string format
function M.timeStampFormat(format)
    local format = format or "%Y-%m-%d %H:%M:%S"
    local timeStamp, millisecond = string.match(M.time(), "(%d+)(%.%d*)")
    local millisecond = millisecond or ""
    local timeStampStr = os.date(format, timeStamp) .. millisecond
    return timeStampStr
end


return M
