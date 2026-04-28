-- Version:V1.0
local ErrorCode = {}
local Log = require("Common/logging")
local CommonFunc = require("Common/Utilities")

ErrorCode.moduleCodeList = {
    DMMControl = 100,
    AudioModule = 101,
    PowerControl = 102,
    ELoad = 103,
    PowerSequence = 104,
    SimpleComm = 105,
    TdmSignal = 106,
    PdmSignal = 107,
    FixtureInfo = 108,
    StreamLiteFixtureControl = 109,
    INVTInteractiveViewError = 110,
    EFSClientError = 111,
    RelayModule = 112,
    RPCClient = 113,
    StationUtils = 114,
    DataloggerModule = 115,
    SignalLogging = 116,

    DelayError = 500,
    ProcessError = 501,
    ActionsLoadError = 502,
    BaseLib = 504,
    PluginLoader = 505,
    SFCQueryError = 506,
    InteractiveViewError = 507,
    PopupError = 508,
    RelayError = 509,
    StationInfoError = 510,
    StreamLiteError = 511,
    UtilityError = 512,
    FixtureInfoError = 513
}

-- Process error.
ErrorCode.FatalErr = {code = 999, msg = "Fatal error with unknown issue.", info = ""}
ErrorCode.FunctionNotSupportErr = {code = 998, msg = "This function not support for Resource.", info = ""}
ErrorCode.FunctionNotReadyErr = {code = 998, msg = "This function not ready now", info = ""}

-- Resource is defined as fixture instrument.
ErrorCode.TestShowFail = {code = 000, msg = "Test show fail.", info = ""}

-- Resource is defined as fixture instrument.
ErrorCode.ResourceNotFoundErr = {code = 010, msg = "Resource not found.", info = ""}
ErrorCode.ResourceOpenErr = {code = 011, msg = "Resource can't open.", info = ""}
ErrorCode.ResourceNoResponseErr = {code = 012, msg = "Resource Communication no response error.", info = ""}
ErrorCode.ResourceResponseErr = {code = 013, msg = "Resource Communication response show error message:", info = ""}

-- Parameter is functions input.
ErrorCode.ParameterEmptyErr = {code = 020, msg = "Parameter is Empty.", info = ""}
ErrorCode.ParameterFormatErr = {code = 021, msg = "Parameter is Empty.", info = ""}
ErrorCode.ParameterOutOfRangeErr = {code = 022, msg = "Parameter out of range.", info = ""}
ErrorCode.ParameterNotAcceptErr = {code = 023, msg = "Parameter not accept.", info = ""}
ErrorCode.ParameterTypeErr = {code = 024, msg = "Parameter type error.", info = ""}

-- file operation error.
ErrorCode.FileNotExistErr = {code = 030, msg = "File not exist.", info = ""}
ErrorCode.FolderNotExistErr = {code = 031, msg = "Folder not exist.", info = ""}

ErrorCode.UnitErr = {code = 040, msg = "Unit error.", info = ""}

-- plugin error.
ErrorCode.PluginNotExistErr = {code = 050, msg = "Plugin not exist in Plugins folder.", info = ""}
ErrorCode.PluginLoadErr = {code = 051, msg = "Plugin load error.", info = ""}
ErrorCode.PluginGetErr = {code = 052, msg = "Plugin not load or an error plugins object to get.", info = ""}

-- gpio error.
ErrorCode.GPIOSetErr = {code = 060, msg = "gpio in input mode,can't set gpio's level.", info = ""}

ErrorCode.SFCQueryFailErr = {code = 070, msg = "SFCQueryRecord error or SFC Server not good.", info = ""}
-- action defined error.
ErrorCode.RepeatedActionErr = {code = 100, msg = "Repeated actions be defined.", info = ""}
ErrorCode.RepeatedKeyErr = {code = 101, msg = "Repeated key in two tables.", info = ""}
-- Process error.
ErrorCode.LimitsVersionErr = {code = 111, msg = "To set an error limits version for SMT.", info = ""}
ErrorCode.LogNotExistErr = {code = 112, msg = "The log to Insight is not exists.", info = ""}
ErrorCode.TimeoutErr = {code = 113, msg = "Timeout event occur", info = ""}
ErrorCode.ParseErr = {code = 114, msg = "Parse event occur", info = ""}

-- return error.
ErrorCode.ReturnEmptyErr = {code = 150, msg = "Return is Empty.", info = ""}
ErrorCode.ReturnFormatErr = {code = 151, msg = "Return is Empty.", info = ""}
ErrorCode.ReturnOutOfRangeErr = {code = 152, msg = "Return out of range.", info = ""}
ErrorCode.ReturnNotAcceptErr = {code = 153, msg = "Return not accept.", info = ""}
ErrorCode.ReturnTypeErr = {code = 154, msg = "Return type error.", info = ""}

-- fixture error.
ErrorCode.MotionErr = {code = 160, msg = "Motion error", info = ""}

function ErrorCode.init(modulesName, modulecode)
    local sourceInfo = CommonFunc.splitBySeveralDelimiter(debug.getinfo(2).source, '/')
    local sourceModule = sourceInfo and sourceInfo[#sourceInfo - 1]
    local errorFunc = function(errorType, moreInfo)
        local moduleCode = ErrorCode.moduleCodeList[modulesName] or modulecode
        local code = moduleCode * 1000 + errorType.code
        local msg = errorType.msg
        if not errorType.info then
            errorType.info = ""
        end
        if not moreInfo then
            moreInfo = ""
        end
        local info = string.format(errorType.info == "" and "%s" or errorType.info, moreInfo) or ""
        Log.LogError(modulesName, msg, info)
        local errorString = 'ERROR_CODE[' .. tostring(string.format("%06d", code)) .. ']:' .. tostring(msg) .. "," ..
                                tostring(info)
        if sourceModule == 'ActionsBox' then
            Matchbox.reportFailure(errorString)
        else
            error(errorString, 2)
        end
    end
    return errorFunc
end

return ErrorCode
