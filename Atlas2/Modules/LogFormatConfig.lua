-------------------------------------------------------------------
----***************************************************************
----   LogFormatGenerator for convert device.log to flow.log and pivot.csv
----   Author: Apple & USISX ATESW Callon, Katherine
----***************************************************************
-------------------------------------------------------------------
local LogFormatConfig = {}

-- @ Content Prefix/Suffix
LogFormatConfig.TEST_NAME_PREFIX = "==Test: "
LogFormatConfig.TEST_RESULT_PREFIX = ""
LogFormatConfig.RECORD_PREFIX = ""
LogFormatConfig.FIXTURE_CMD_PREFIX = "[rpc_client]"
LogFormatConfig.FIXTURE_RESP_PREFIX = "[result]"
LogFormatConfig.DUT_CMD_PREFIX = "cmd-send: "
LogFormatConfig.DUT_RESP_PREFIX = ""
LogFormatConfig.FLOW_DEBUG_PREFIX = ""

LogFormatConfig.TEST_NAME_SUFFIX = "==Test:"
LogFormatConfig.TEST_RESULT_SUFFIX = ""
LogFormatConfig.RECORD_SUFFIX = ""
LogFormatConfig.FIXTURE_CMD_SUFFIX = ""
LogFormatConfig.FIXTURE_RESP_SUFFIX = ""
LogFormatConfig.DUT_CMD_SUFFIX = ""
LogFormatConfig.DUT_RESP_SUFFIX = ""
LogFormatConfig.FLOW_DEBUG_SUFFIX = ""

LogFormatConfig.TEST_SEPARATOR = "\n"

-- @ Data Format
LogFormatConfig.TIMESTAMP = "%Y/%m/%d %H:%M:%S.%f"
LogFormatConfig.SUBTEST_NAME_CONNECTOR = string.format("\n%30s==SubTest: ", "")
LogFormatConfig.SUBSUBTEST_NAME_CONNECTOR = string.format("\n%30s==SubSubTest: ", "")

-- LogFormatConfig.FLOW_LOG_RECORD_NAME_FORMAT = "%s"

-- @ Content Indentation
LogFormatConfig.TEST_START_INDENTATION = 4
LogFormatConfig.TEST_RESULT_INDENTATION = 4
LogFormatConfig.RECORD_INDENTATION = 2
LogFormatConfig.FIXTURE_CMD_INDENTATION = 4
LogFormatConfig.FIXTURE_RESP_INDENTATION = 4
LogFormatConfig.DUT_CMD_INDENTATION = 2
LogFormatConfig.DUT_RESP_INDENTATION = 2
LogFormatConfig.FLOW_DEBUG_INDENTATION = 2

LogFormatConfig.PREFIX_LEN = 1

-- @ Log filter
LogFormatConfig.specialFilterFlg = true -- @ if not use it set false 
LogFormatConfig.specialFilterPattern = "DataChannel write:error:" -- @ if not use it set null e.g.""

LogFormatConfig.LINE_TO_FILTER = {"Channel was stalled due to overlogging."}

return LogFormatConfig
