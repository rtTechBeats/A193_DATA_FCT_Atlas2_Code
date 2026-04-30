-------------------------------------------------------------------
----***************************************************************
---- INVT Constants Table
----***************************************************************
-------------------------------------------------------------------
local constants = {}
local stationInfo = Atlas.loadPlugin("StationInfo")
local jsonPlugin = require("Serialization/JSONSerialization")

constants.VENDOR_CODE_FOLDER = {INVT = "Tech/INVT"}
--!@ DEBUGGING_LOG_DISABLED false means NPI stage, set log level to "INFO" to get more info
--!@ DEBUGGING_LOG_DISABLED true means MP stage, set log level to "ERROR" to reduce log print and log size
constants.DEBUGGING_LOG_DISABLED = false
--!@ Whether show login dialog
constants.NEED_LOGIN = false
--!@ Whether run GroupTeardown after test
constants.NEED_GROUP_EXIT = true
--!@ Whether run test in parallel
constants.NEED_PARALLEL_TEST = true
--!@ Unmanage plugin table, use NEED_PARALLEL_TEST replace, wait to discard
constants.UNMANAGE_PLUGIN_TABLE = {
    -- Group Plugins
    "InteractiveView", "MDParser", "VariableTable", "MutexPlugin",
    -- Device Plugins
    "SMTCommonPlugin", "TimeUtility", "FileOperation", "Regex", "SFC", "Utilities",
    "StationInfo", "RunShellCommand", "PListSerializationPlugin", "JSONSerializationPlugin",
    -- INVT Plugins
    "RTCommonLib", "MixRPC"
}

constants.LoopDuration = 5  -- second
constants.LIB_PATH = string.gsub(Atlas.assetsPath,"Assets","Modules").."/Tech/INVT/Modules/Lib"
constants.GH_INFO_PATH = "/vault/data_collection/test_station_config/gh_station_info.json"
constants.GH_INFO_TAB = jsonPlugin.LoadFromFile(constants.GH_INFO_PATH)
constants.GH_INFO_GHINFO = constants.GH_INFO_TAB["ghinfo"]

constants.Scanner = {
    SnLength = 1,
    Columns = 4
}

constants.Fixture = {
    AUTO_START = true,
    FIXTURE_TYPE = "uart",
    FIXTURE_OPTION = {"stream", "uart", "simulator"},
    START_CMD = "fixture_run\n",
    RESET_CMD = "fixture_reset\n",
    START_DONE = "fixture_run %[OK%]",
    RESET_DONE = "fixture_reset %[OK%]",
    IN_CMD = "fixture_in\n",
    DOWN_CMD = "fixture_down\n",
    IN_DONE = "fixture_in %[OK%]",
    DOWN_DONE = "fixture_down %[OK%]",
    LogPath = "/vault/AtlasFixture.log",
    URL = "uart:///dev/cu.usbserial-Kimi?baud=115200&mode=8N1",

}

constants.StationInfo = {
    site = stationInfo.site(),
    controlRun = stationInfo.control_run(),
    location = stationInfo.location(),
    product = stationInfo.product(),
    stationID = stationInfo.station_id(),
    stationType = stationInfo.station_type(),
    lineNumber = stationInfo.line_number(),
    stationOverlay = stationInfo.station_overlay(),
    stationName = stationInfo.product().."-"..stationInfo.station_type()
}

constants.UploadMesInfo = {
    "tSOC_offset",
    "tCMC_offset",
    "tBST_offset"
}

constants.RP2Port = {
    slot1 = "/dev/cu.usbmodemRYNTC11",
    slot2 = "/dev/cu.usbmodemRYNTC21",
    slot3 = "/dev/cu.usbmodemRYNTC31",
    slot4 = "/dev/cu.usbmodemRYNTC41",
}

constants.StationURL = {
    --!@ CommBuilder Plugin create Uart URL format as below
    --!@ uart://{port}?baud={baud}&mode={dataBits}{parity}{stopBits}
    --!@ tcp://{ip}:{port}

    slot1 = {
        VirtualPort = {
            apUartUrl = "uart:///tmp/dev/xav1",
            vtMetaUrl = "xav://169.254.1.32:7801:uart_uut0"
        },
        mixURL = "169.254.1.32:7801",
        dutUartURL = "uart:///dev/cu.usbserial-DATA_FCT_CH0?baud=115200&mode=8N1",
        dutUSBCURL = "uart:///dev/cu.usbmodem141401?baud=115200&mode=8N1",
        dutUSBLocationID = 0x14140000
    },
    slot2 = {
        VirtualPort = {
            apUartUrl = "uart:///tmp/dev/xav2",
            vtMetaUrl = "xav://169.254.1.32:7801:uart_uut1"
        },
        mixURL = "169.254.1.33:7801",
        dutUartURL = "uart:///dev/cu.usbserial-DATA_FCT_CH1?baud=115200&mode=8N1",
        dutUSBCURL = "uart:///dev/cu.usbmodem141301?baud=115200&mode=8N1",
        dutUSBLocationID = 0x14130000
    },
    slot3 = {
        VirtualPort = {
            apUartUrl = "uart:///tmp/dev/xav3",
            vtMetaUrl = "xav://169.254.1.32:7801:uart_uut2"
        },
        mixURL = "169.254.1.34:7801",
        dutUartURL = "uart:///dev/cu.usbserial-DATA_FCT_CH2?baud=115200&mode=8N1",
        dutUSBCURL = "uart:///dev/cu.usbmodem141201?baud=115200&mode=8N1",
        dutUSBLocationID = 0x14120000
    },
    slot4 = {
        VirtualPort = {
            apUartUrl = "uart:///tmp/dev/xav4",
            vtMetaUrl = "xav://169.254.1.32:7801:uart_uut3"
        },
        mixURL = "169.254.1.35:7801",
        dutUartURL = "uart:///dev/cu.usbserial-DATA_FCT_CH3?baud=115200&mode=8N1",
        dutUSBCURL = "uart:///dev/cu.usbmodem1411401?baud=115200&mode=8N1",
        dutUSBLocationID = 0x14114000

    }
}

constants.COMM_MUX = {
    Uart = {
        name = "Uart",
        primary = true,
        setup_params = {
            log = {
                SMTLogFile = "/DutCommunication/Uart/DUT_Uart.log",
                PreLogFile = "/DutCommunication/Uart/Debug/Debug_uart_raw.log",
                PostLogFile = "/DutCommunication/Uart/Debug/Debug_uart.log"
            },
            active = true,
            delimiter = "[m",
            hangDetection = false
        },
        need_open = true
    },
    USBUart = {
        name = "USBUart",
        primary = true,
        setup_params = {
            log = {
                SMTLogFile = "/DutCommunication/USB_Uart/DUT_USB_Uart.log",
                PreLogFile = "/DutCommunication/USB_Uart/Debug/Debug_usb_uart_raw.log",
                PostLogFile = "/DutCommunication/USB_Uart/Debug/Debug_usb_uart.log"
            },
            active = true,
            delimiter = "[m",
            hangDetection = false
        },
        need_open = false
    }
}

constants.CB_OFFSETS_TABLE = {
    -- station type, cb offsets table
    ["DFU"] = "00",
    ["FCT"] = "01"
}

return constants
