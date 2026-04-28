local module = {}

local function getPlugin()
    if Device then
        local status, plugin = xpcall(Device.getPlugin, debug.traceback, "FileOperation")
        if status then
            return plugin
        else
            return Atlas.loadPlugin("SMTCommonPlugin").createFileManipulationUtility()
        end
    else
        return Atlas.loadPlugin("SMTCommonPlugin").createFileManipulationUtility()
    end
end

module.__plugin = getPlugin()

function module.newFile(path)
    return io.open(path, "w+")
end

function module.createDirectory(path)
    return module.__plugin.createDirectory(path)
end

function module.listDirectory(path, needReportIsDir)
    return module.__plugin.listDirectory(path, needReportIsDir)
end

function module.copyFiles(src, dest)
    return module.__plugin.copy(src, dest)
end

function module.moveFiles(src, dest)
    return module.__plugin.move(src, dest)
end

return module
