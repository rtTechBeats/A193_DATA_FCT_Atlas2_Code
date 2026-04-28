local log = require("Matchbox/logging")
local PluginsLoader = require("Tech/INVT/Modules/PluginsLoader")
local runShellCmd = PluginsLoader.getPlugin("RunShellCommand")
local init = require("Tech/INVT/init")
local FwUpdate = {}

local function ssh_command_execute(xavierAddr, command, timeout)
    local ssh_cmd = [[
        expect -c "
        set timeout %d;
        spawn ssh root@%s \"%s\"
        expect {
            \"*yes/no*\" { send "yes"\n; exp_continue }
            \"*assword*\" { send 123456\n }
        } ;
        expect *\n;
        expect eof
        "
    ]]
    ssh_cmd = string.format(ssh_cmd, timeout, xavierAddr, command)
    local result = runShellCmd.run(ssh_cmd)
    log.LogInfo("ssh_command_execute result", result.output)

    return result.output
end

local function checkNetworkConnection(host)
    local cmd = string.format("ping -c 2 -W 2 %s", host)
    local result = runShellCmd.run(cmd)
    if string.match(result.output, "icmp_seq=") then
        return true
    else
        return false
    end
end

function FwUpdate.sshCommand(host, command, userName, password, timeout)
    local cmd = "expect -c "
    local expectCmd = string.format("set timeout %d;\
spawn ssh %s@%s %s \
expect {\
    \\\"yes/no\\\" { send \\\"yes\r\\\"; exp_continue }\
    \\\"password\\\" { send \\\"%s\r\\\" }\
} ;\
expect \\\"*#\\\";\
expect eof;", timeout, userName, host, command, password)
    local result = runShellCmd.run(cmd .. "\"" .. expectCmd .. "\"")

    return result.output
end

local function scpCommand(xavier_addr, local_path, remote_path, timeout)
    local scp_cmd = [[
            expect -c "
            set timeout %d;
            spawn scp -P 22 %s root@%s:%s;
            expect {
                \"*yes/no*\" { send "yes"\n; exp_continue }
                \"*assword*\" { send 123456\n }
            } ;
            expect *\n;
            expect eof
            "
    ]]
    scp_cmd = string.format(scp_cmd, timeout, local_path, xavier_addr, remote_path)
    log.LogInfo(string.format("%s is downloading %s to %s ...", xavier_addr, local_path, remote_path))
    local result = runShellCmd.run(scp_cmd)

    return result.output
end

function FwUpdate.md5Command(path)
    local cmd = string.format("md5 %s", path)
    local result = runShellCmd.run(cmd)
    log.LogInfo("md5Command result", result.output)

    return result.output
end

local function getlocalFWInformation()
    local localFW = {}
    local fw_path = init.MIX_FW_PATH
    local cmdResponse = runShellCmd.run(string.format("ls %s/*.tgz", fw_path))
    localFW["FWName"] = string.match(cmdResponse.output, ".*/(MIX.*tgz)")
    localFW["FWPath"] = string.match(cmdResponse.output, "(.*tgz)")
    localFW["FWVer"] = string.match(cmdResponse.output, ".*_INVT_(.-)%.tgz")
    if localFW.FWPath ~= nil then
        local result = FwUpdate.md5Command(localFW.FWPath)
        local md5 = string.match(result, " = ([0-9a-f]+)%s*$")
        if md5 then
            localFW["FWMD5"] = md5
        end
    end
    log.LogInfo("local Firmware information:", localFW)

    return localFW
end

local function compareXavierFWVersion()
    local compare_result = {}
    for index, xavier_addr in ipairs(init.TOPOLOGY.xavier_addr) do
        local slot_info = {}
        slot_info["slot"] = index
        slot_info["host"] = xavier_addr
        local net_status = checkNetworkConnection(xavier_addr)
        if net_status then
            local rpcClient = PluginsLoader.createRPCClient(xavier_addr, init.TOPOLOGY.xavier_port_base)
            local status, result = pcall(rpcClient.rpc, "xavier.fw_version")
            rpcClient.shutdown()
            if status then
                slot_info["currentFWVer"] = result.MIX_FW_PACKAGE
                slot_info["upgrade"] = (slot_info["currentFWVer"] ~= FwUpdate.localFW.FWVer)
            end
        else
            slot_info["error"] = "Network connection issue!"
        end
        table.insert(compare_result, slot_info)
    end

    return compare_result
end

local function FinallyCheck(upgrade_addr_table)
    log.LogInfo("Waiting upgrade FW ...")
    runShellCmd.run("sleep 300")
    local counts = 60
    -- set 60 times to ensure that the Xavier server is started after upgrading firmware.
    repeat
        for index, xavier_addr in ipairs(upgrade_addr_table) do
            local net_status = checkNetworkConnection(xavier_addr)
            if net_status then
                local rpcClient = PluginsLoader.createRPCClient(xavier_addr, init.TOPOLOGY.xavier_port_base)
                local status, ret = pcall(rpcClient.rpc, "server.mode")
                rpcClient.shutdown()
                if status and ret == "normal" then
                    log.LogInfo(string.format("%s\t mode is normal.", xavier_addr))
                    table.remove(upgrade_addr_table, index)
                else
                    log.LogInfo(string.format("%s\t mode is %s.", xavier_addr, ret))
                end
            end
        end
        runShellCmd.run("sleep 1")
        counts = counts - 1
    until (counts < 1) or (#upgrade_addr_table == 0)
    return compareXavierFWVersion(runShellCmd)
end

function FwUpdate.updateMixFirmware()
    -- 1. summary local FW information(path/version/md5)
    FwUpdate["localFW"] = getlocalFWInformation()
    -- 2. compare Xavier FW version
    FwUpdate["slot_information_table"] = compareXavierFWVersion()
    local upgrade_addr_table = {}
    local upgrade_flag = nil
    for _, slot_info in ipairs(FwUpdate.slot_information_table) do
        if slot_info.upgrade then
            table.insert(upgrade_addr_table, slot_info.host)
            upgrade_flag = slot_info.upgrade
        end
    end
    -- 3. copy FW file to remote
    for _, xavier_addr in ipairs(upgrade_addr_table) do
        scpCommand(xavier_addr, FwUpdate.localFW.FWPath, "/var/fw_update/upload/", 60)
    end
    -- 4. check remote md5
    -- 5. delete rpc log
    -- 6. sync & reboot(system will run start.sh & reboot)
    for _, xavier_addr in ipairs(upgrade_addr_table) do
        local md5_check_cmd = string.format("md5sum /var/fw_update/upload/%s", FwUpdate.localFW.FWName)
        local output = ssh_command_execute(xavier_addr, md5_check_cmd, 10)
        local remote_md5_result = string.match(output, "password:.-([0-9a-f]+).*$")
        if remote_md5_result ~= FwUpdate.localFW.FWMD5 then
            scpCommand(xavier_addr, FwUpdate.localFW.FWPath, "/var/fw_update/upload/", 60)
            output = ssh_command_execute(xavier_addr, md5_check_cmd, 10)
            remote_md5_result = string.match(output, "password:.-([0-9a-f]+).*$")
            if remote_md5_result ~= FwUpdate.localFW.FWMD5 then
                log.LogError(string.format("LocalFWMD5:\t%s\nRemoteFWMD5:\t%s", FwUpdate.localFW.FWMD5,
                                           remote_md5_result))
                error("LocalFWMD5 is different with RemoteFWMD5!")
            end
        end
        ssh_command_execute(xavier_addr, "rm -rf /var/log/rpc_log/*", 20)
        ssh_command_execute(xavier_addr, "sync;reboot", 10)
    end
    -- 7. check Xavier Server status and compare Xavier FW version
    if upgrade_flag then
        FwUpdate["slot_information_table"] = FinallyCheck(upgrade_addr_table)
        log.LogInfo("Xavier Information:")
        log.LogInfo(FwUpdate.slot_information_table)
    end
end

return FwUpdate
