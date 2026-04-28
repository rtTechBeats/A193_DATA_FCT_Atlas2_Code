return  {
  testPlanAttribute = {
    DisableOrphanedRecordChecking = true
  },
  testPlanForModes = {
    Audit = {
      conditions = {
        group = {
          {
            generator = {
              func = "mode",
              module = "Schooner/DefaultConditionGeneratorAndValidator"
            },
            name = "Mode",
            validator = {
              allowedList = {
                "Audit",
                "Production"
              },
              type = "IN"
            }
          }
        },
        test = {
          {
            name = "vendorID",
            validator = {
              allowedList = {
                "_INIT_",
                "0x01:INVT"
              },
              type = "IN"
            }
          },
          {
            name = "TEST_MODE",
            validator = {
              allowedList = {
                "_INIT_",
                "Production",
                "Audit"
              },
              type = "IN"
            }
          }
        }
      },
      limitInfo = {
        conditions = {
        },
        limitPositionInfos = {
        },
        withMode = false,
        withProduct = false,
        withStationType = false
      },
      limits = {
        {
          required = true,
          subsubtestname = "stationInfo_Product",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "stationInfo_Station_name",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "createAttr_Station_name",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "stationInfo_Vendor_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "createAttr_Vendor_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "stationInfo_Slot_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "createAttr_Slot_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "stationInfo_Fixture_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "createAttr_Fixture_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "stationInfo_Xavier_FW_Version",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "createAttr_Xavier_FW_Version",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "ResetAll",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_1000mV_3uA",
          subtestname = "Resistance",
          testname = "POWER_OFF"
        },
        {
          lowerLimit = 50,
          required = true,
          subsubtestname = "NTC2_NRF_131_TO_GND",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 165
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_GND_TO_FIXTURE_GND",
          subtestname = "Resistance",
          testname = "POWER_OFF"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_1000mV_100uA",
          subtestname = "Resistance",
          testname = "POWER_OFF"
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_ACCEL_A51_SDA_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_ACCEL_A51_SCL_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_CHGR_SDA_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_CHGR_SCL_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_PDC_ULPOD_SDA_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_PDC_ULPOD_SCL_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_BMU_SDA_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_BMU_SCL_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          required = true,
          subsubtestname = "Relay_DUT_GND_TO_FIXTURE_GND",
          subtestname = "Leakage",
          testname = "POWER_OFF"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_500mV_200uA",
          subtestname = "Leakage",
          testname = "POWER_OFF"
        },
        {
          required = true,
          subsubtestname = "Delay_2000ms",
          subtestname = "Leakage",
          testname = "POWER_OFF"
        },
        {
          lowerLimit = -1,
          required = true,
          subsubtestname = "Measure_Leakage_PP_VSYS",
          subtestname = "Leakage",
          testname = "POWER_OFF",
          units = "mA",
          upperLimit = 1
        },
        {
          lowerLimit = -1,
          required = true,
          subsubtestname = "Measure_Leakage_PP5V_AON",
          subtestname = "Leakage",
          testname = "POWER_OFF",
          units = "mA",
          upperLimit = 1
        },
        {
          lowerLimit = -1,
          required = true,
          subsubtestname = "Measure_Leakage_PP3V3_AON",
          subtestname = "Leakage",
          testname = "POWER_OFF",
          units = "mA",
          upperLimit = 1
        },
        {
          lowerLimit = -1,
          required = true,
          subsubtestname = "Measure_Leakage_PP3V3_PDC",
          subtestname = "Leakage",
          testname = "POWER_OFF",
          units = "mA",
          upperLimit = 1
        },
        {
          lowerLimit = -1,
          required = true,
          subsubtestname = "Measure_Leakage_PP1V83",
          subtestname = "Leakage",
          testname = "POWER_OFF",
          units = "mA",
          upperLimit = 1
        },
        {
          required = true,
          subsubtestname = "ResetAll",
          subtestname = "Leakage",
          testname = "POWER_OFF"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_NRF2SYS_SHDN_1KPULLDOWN",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Pull_Up_SYS_RST",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP_VSYS_TO_PSU_BATTERY_POS1",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Power_On_PP_VSYS_8V",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "Reset_Current_System",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info",
          units = "mA",
          upperLimit = 2
        },
        {
          required = true,
          subsubtestname = "Release_SYS_RST",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Delay_5000ms",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "PP_VSYS_I",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mA",
          upperLimit = 2
        },
        {
          lowerLimit = 7900,
          required = true,
          subsubtestname = "PP_VSYS_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 8100
        },
        {
          lowerLimit = 5100,
          required = true,
          subsubtestname = "PP5V0_AON_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 5300
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "PP1V83_AON_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "PP1V83_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_AON_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_PDC_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_DECUSB_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 850,
          required = true,
          subsubtestname = "PP_RADIO_DECRF_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 950
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "SYS_Info",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Read_MLB_SN",
          subtestname = "SYS_Info",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "HWID_Ver",
          subtestname = "SYS_Info",
          testname = "System_Info",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "FW_Ver_NRF",
          subtestname = "SYS_Info",
          testname = "System_Info",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Flash_ID",
          subtestname = "SYS_Info",
          testname = "System_Info",
          units = "string"
        },
        {
          lowerLimit = 1,
          required = true,
          subsubtestname = "Flash_Write_Read_Test",
          subtestname = "SYS_Info",
          testname = "System_Info",
          upperLimit = 1
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "NRF_NTC",
          testname = "System_Info"
        },
        {
          lowerLimit = 20,
          required = true,
          subsubtestname = "NTC2_TEMP",
          subtestname = "NRF_NTC",
          testname = "System_Info",
          units = "C",
          upperLimit = 30
        },
        {
          lowerLimit = 20,
          required = true,
          subsubtestname = "BST_NTC0_TEMP",
          subtestname = "NRF_NTC",
          testname = "System_Info",
          units = "C",
          upperLimit = 30
        },
        {
          lowerLimit = 20,
          required = true,
          subsubtestname = "CMC_NTC1_TEMP",
          subtestname = "NRF_NTC",
          testname = "System_Info",
          units = "C",
          upperLimit = 30
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_NTC2_NRF_131_TO_CCS",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_1500mV_1mA",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC2_TEMP",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 1450,
          required = true,
          subsubtestname = "DMM_READ_NTC2_V",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1550
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 9,
          required = true,
          subsubtestname = "Calculate-NTC2_Temp",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 11
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_850mV_1mA",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC2_TEMP",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 800,
          required = true,
          subsubtestname = "DMM_READ_NTC2_V",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 900
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 44,
          required = true,
          subsubtestname = "Calculate-NTC2_Temp",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 46
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Hex",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Write_NTC2_TEMP_Offset",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Read_NTC2_TEMP_Offset",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Float",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Disable_CCS",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_NTC2_NRF_131_TO_CCS",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_CMC_NTC1_NRF_130_TO_CCS",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_1500mV_1mA",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC1_TEMP",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 1450,
          required = true,
          subsubtestname = "DMM_READ_CMC_NTC1_NRF_130_V",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1550
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 9,
          required = true,
          subsubtestname = "Calculate-NTC1_Temp",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 11
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_850mV_1mA",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC1_TEMP",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 800,
          required = true,
          subsubtestname = "DMM_READ_CMC_NTC1_NRF_130_V",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 900
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 44,
          required = true,
          subsubtestname = "Calculate-NTC1_Temp",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 46
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Hex",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Write_NTC1_TEMP_Offset",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Read_NTC1_TEMP_Offset",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Float",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Disable_CCS",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_CMC_NTC1_NRF_130_TO_CCS",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_BST_NTC0_NRF_129_TO_CCS",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_1500mV_1mA",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC0_TEMP",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 1450,
          required = true,
          subsubtestname = "DMM_READ_BST_NTC0_NRF_129_V",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1550
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 9,
          required = true,
          subsubtestname = "Calculate-NTC0_Temp",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 11
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_850mV_1mA",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC0_TEMP",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 800,
          required = true,
          subsubtestname = "DMM_READ_BST_NTC0_NRF_129_V",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 900
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 44,
          required = true,
          subsubtestname = "Calculate-NTC0_Temp",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 46
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Hex",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Write_NTC0_TEMP_Offset",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Read_NTC0_TEMP_Offset",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Float",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Disable_CCS",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_BST_NTC0_NRF_129_TO_CCS",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "ResetAll",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP_VSYS_TO_PSU_BATTERY_POS1",
          subtestname = "No_Load",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Power_On_PP_VSYS_8V",
          subtestname = "No_Load",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Delay_5000ms",
          subtestname = "No_Load",
          testname = "Buck_5V"
        },
        {
          lowerLimit = 5100,
          required = true,
          subsubtestname = "PP5V_AON_V_No_Load",
          subtestname = "No_Load",
          testname = "Buck_5V",
          units = "mV",
          upperLimit = 5300
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "PP_VSYS_I_No_Load",
          subtestname = "No_Load",
          testname = "Buck_5V",
          units = "mA",
          upperLimit = 2
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_No_Load",
          subtestname = "No_Load",
          testname = "Buck_5V",
          units = "mV",
          upperLimit = 100
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP5V_AON_TO_E_LOAD_1_INPUT2",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Eload1_Enable_200mA_PP5V_AON",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          lowerLimit = 7900,
          required = true,
          subsubtestname = "PP_VSYS_V_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "mV",
          upperLimit = 8100
        },
        {
          lowerLimit = 120,
          required = true,
          subsubtestname = "PP_VSYS_I_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "mA",
          upperLimit = 160
        },
        {
          lowerLimit = 5050,
          required = true,
          subsubtestname = "PP5V_AON_V_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "mV",
          upperLimit = 5250
        },
        {
          lowerLimit = 190,
          required = true,
          subsubtestname = "Buck_5V_Output_Current_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "mA",
          upperLimit = 210
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "mV",
          upperLimit = 100
        },
        {
          lowerLimit = 90,
          required = true,
          subsubtestname = "Eff_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "%",
          upperLimit = 95
        },
        {
          required = true,
          subsubtestname = "Eload1_Disable",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Delay_2000ms",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_PP5V_AON_TO_E_LOAD_1_INPUT2",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_AON_V_No_Load",
          subtestname = "No_Load",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_PDC_V_No_Load",
          subtestname = "No_Load",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "PP_VSYS_I_No_Load",
          subtestname = "No_Load",
          testname = "Buck_3V3",
          units = "mA",
          upperLimit = 2
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_No_Load",
          subtestname = "No_Load",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 50
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP3V3_PDC_TO_E_LOAD_1_INPUT5",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          required = true,
          subsubtestname = "Eload1_Enable_200mA_PP3V3_PDC",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          lowerLimit = 7900,
          required = true,
          subsubtestname = "PP_VSYS_V_Load_200mA",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 8100
        },
        {
          lowerLimit = 80,
          required = true,
          subsubtestname = "PP_VSYS_I_Load_200mA",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mA",
          upperLimit = 110
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_AON_V_200mA_Load",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 3150,
          required = true,
          subsubtestname = "PP3V3_PDC_V_200mA_Load",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 3350
        },
        {
          lowerLimit = 190,
          required = true,
          subsubtestname = "Buck_3V3_Output_Current_Load_200mA",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mA",
          upperLimit = 210
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_Load_200mA",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 10
        },
        {
          lowerLimit = 89,
          required = true,
          subsubtestname = "Eff_Load_200mA",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "%",
          upperLimit = 94
        },
        {
          required = true,
          subsubtestname = "Eload1_Disable",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          required = true,
          subsubtestname = "Delay_2000ms",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_PP3V3_PDC_TO_E_LOAD_1_INPUT5",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_NRF2SYS_SHDN_1KPULLDOWN",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "PP_VSYS_I_No_Load",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8",
          units = "mA",
          upperLimit = 2
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP1V83_TO_E_LOAD_1_INPUT6",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Eload1_Enable_10mA_PP1V83",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_1",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "PP1V83_AON_V_10mA_Load",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 1700,
          required = true,
          subsubtestname = "PP1V83_V_10mA_Load",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 1850
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "PP_VSYS_I_10mA_Load",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8",
          units = "mA",
          upperLimit = 5
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_10mA_Load",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 50
        },
        {
          required = true,
          subsubtestname = "Eload1_Disable",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_2",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_PP1V83_TO_E_LOAD_1_INPUT6",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP1V83_AON_TO_E_LOAD_1_INPUT4",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Eload1_Enable_200mA_PP1V83_AON",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_1",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          lowerLimit = 7900,
          required = true,
          subsubtestname = "PP_VSYS_V_Load_200mA",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 8100
        },
        {
          lowerLimit = 30,
          required = true,
          subsubtestname = "PP_VSYS_I_Load_200mA",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mA",
          upperLimit = 70
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "PP1V83_AON_V_200mA_Load",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "PP1V83_V_200mA_Load",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 190,
          required = true,
          subsubtestname = "Buck_1V83_Output_Current_Load_200mA",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mA",
          upperLimit = 210
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_Load_200mA",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 80,
          required = true,
          subsubtestname = "Eff_Load_200mA",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "%",
          upperLimit = 90
        },
        {
          required = true,
          subsubtestname = "Eload1_Disable",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_2",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_PP1V83_AON_TO_E_LOAD_1_INPUT4",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_NRF2SYS_SHDN_1KPULLDOWN",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_USBUART_EN",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan"
        },
        {
          required = true,
          subsubtestname = "I2C0_NRF_ACCEL_A51_Scan",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan"
        },
        {
          required = true,
          subsubtestname = "I2C0_NRF_ACCEL_A51_Scan_Device1",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C0_NRF_ACCEL_A51_Scan_Device2",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C1_NRF_CPS_Scan",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C2_NRF_CHGR_Scan",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C3_NRF_BMU_Scan",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C4_NRF_PDC_ULPOD_Scan",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan"
        },
        {
          required = true,
          subsubtestname = "I2C4_NRF_PDC_ULPOD_Scan_Device1",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C4_NRF_PDC_ULPOD_Scan_Device2",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "ACCEL_Self_Test",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan"
        },
        {
          lowerLimit = 70,
          required = true,
          subsubtestname = "X_Self_Test",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          upperLimit = 1500
        },
        {
          lowerLimit = 70,
          required = true,
          subsubtestname = "Y_Self_Test",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          upperLimit = 1500
        },
        {
          lowerLimit = 70,
          required = true,
          subsubtestname = "Z_Self_Test",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          upperLimit = 1500
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "PP_VSYS_I_LED_OFF",
          subtestname = "PP_VSYS_I",
          testname = "LED",
          units = "mA",
          upperLimit = 2
        },
        {
          required = true,
          subsubtestname = "LED_WHITE_ON",
          subtestname = "LED_WHITE",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "LED_WHITE",
          testname = "LED"
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "VSYS_I_LED_WHITE_ON",
          subtestname = "LED_WHITE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "DELTA_I_LED_WHITE_ON",
          subtestname = "LED_WHITE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 500,
          required = true,
          subsubtestname = "Measure_LED_WHITE_E",
          subtestname = "LED_WHITE",
          testname = "LED",
          units = "mV",
          upperLimit = 1000
        },
        {
          lowerLimit = 5,
          required = true,
          subsubtestname = "Calculate_LED_WHITE_Current",
          subtestname = "LED_WHITE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "LED_WHITE_OFF",
          subtestname = "LED_WHITE",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "LED_RED_ON",
          subtestname = "LED_RED",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "LED_RED",
          testname = "LED"
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "VSYS_I_LED_RED_ON",
          subtestname = "LED_RED",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "DELTA_I_LED_RED_ON",
          subtestname = "LED_RED",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 500,
          required = true,
          subsubtestname = "Measure_LED_RED_E",
          subtestname = "LED_RED",
          testname = "LED",
          units = "mV",
          upperLimit = 1000
        },
        {
          lowerLimit = 5,
          required = true,
          subsubtestname = "Calculate_LED_RED_Current",
          subtestname = "LED_RED",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "LED_RED_OFF",
          subtestname = "LED_RED",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "LED_GREEN_ON",
          subtestname = "LED_GREEN",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "LED_GREEN",
          testname = "LED"
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "VSYS_I_LED_GREEN_ON",
          subtestname = "LED_GREEN",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "DELTA_I_LED_GREEN_ON",
          subtestname = "LED_GREEN",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 500,
          required = true,
          subsubtestname = "Measure_LED_GREEN_E",
          subtestname = "LED_GREEN",
          testname = "LED",
          units = "mV",
          upperLimit = 1000
        },
        {
          lowerLimit = 5,
          required = true,
          subsubtestname = "Calculate_LED_GREEN_Current",
          subtestname = "LED_GREEN",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "LED_GREEN_OFF",
          subtestname = "LED_GREEN",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "LED_BLUE_ON",
          subtestname = "LED_BLUE",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "LED_BLUE",
          testname = "LED"
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "VSYS_I_LED_BLUE_ON",
          subtestname = "LED_BLUE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "DELTA_I_LED_BLUE_ON",
          subtestname = "LED_BLUE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 500,
          required = true,
          subsubtestname = "Measure_LED_BLUE_E",
          subtestname = "LED_BLUE",
          testname = "LED",
          units = "mV",
          upperLimit = 1000
        },
        {
          lowerLimit = 5,
          required = true,
          subsubtestname = "Calculate_LED_BLUE_Current",
          subtestname = "LED_BLUE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "LED_BLUE_OFF",
          subtestname = "LED_BLUE",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_5",
          subtestname = "LED_BLUE",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Config_NRF2SYS_SHDN_Output",
          subtestname = "PP5V_OFF",
          testname = "LED"
        },
        {
          lowerLimit = 2000,
          required = true,
          subsubtestname = "Measure_LED_BLUE_K_Voltage",
          subtestname = "PP5V_OFF",
          testname = "LED",
          units = "mV",
          upperLimit = 4000
        },
        {
          required = true,
          subsubtestname = "Set_NRF2SYS_SHDN_H",
          subtestname = "PP5V_OFF",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "PP5V_OFF",
          testname = "LED"
        },
        {
          lowerLimit = -10,
          required = true,
          subsubtestname = "Measure_LED_BLUE_K_Voltage_0",
          subtestname = "PP5V_OFF",
          testname = "LED",
          units = "mV",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "Set_NRF2SYS_SHDN_L",
          subtestname = "PP5V_OFF",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_HD_CHG_ILIM_HIZ_L_TO_GND",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_SYS_RST_TO_PULSE1_IN",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Start_Pulse_Measure",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Config_FW_TRIGGERED_SYS_RST_Output",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_FW_RST_0",
          subtestname = "FW_RST",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Set_FW_TRIGGERED_SYS_RST_H",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 18,
          required = true,
          subsubtestname = "Measure_SYS_RST_PULSE_TIME",
          subtestname = "FW_RST",
          testname = "HALFDOME",
          units = "ms",
          upperLimit = 22
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_FW_RST_0_After_RST",
          subtestname = "FW_RST",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_HD_WTD_FLG_NRF_TO_DMMCH0",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Config_WTD_FLG_Input",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_WTD_FLG",
          subtestname = "WTD_PET",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_HD_WTD_PET_L",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Delay_6500ms",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Start_Pulse_Measure",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Start_Sampling_HD_WTD_FLG_NRF",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 18,
          required = true,
          subsubtestname = "Measure_SYS_RST_PULSE_TIME",
          subtestname = "WTD_PET",
          testname = "HALFDOME",
          units = "ms",
          upperLimit = 22
        },
        {
          required = true,
          subsubtestname = "Get_WTD_FLG_Pulse_Data",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 1700,
          required = true,
          subsubtestname = "Measure_WTD_FLG",
          subtestname = "WTD_PET",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 1900
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_HD_WTD_FLG_NRF_TO_DMMCH0",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_HD_WTD_PET_H",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Config_WTD_FLG_Input_After_WTD_PET_H",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_WTD_FLG_After_WTD_PET_H",
          subtestname = "WTD_PET",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_HD_WTD_DIS_H",
          subtestname = "WTD_DIS",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_HD_WTD_PET_L",
          subtestname = "WTD_DIS",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Delay_9000ms",
          subtestname = "WTD_DIS",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Check_System_Not_Reboot",
          subtestname = "WTD_DIS",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Resume_NRF_HD_WTD_PET",
          subtestname = "WTD_DIS",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_HD_WTD_DIS_L",
          subtestname = "WTD_DIS",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Drive_OVER_TEMP_COMP_OUT_H",
          subtestname = "TEMP_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_RST_WARN_NRF_INT_H",
          subtestname = "TEMP_RST",
          testname = "HALFDOME",
          units = "string"
        },
        {
          lowerLimit = -10,
          required = true,
          subsubtestname = "Measure_PP3V3_PDC",
          subtestname = "TEMP_RST",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "Delay_2500ms",
          subtestname = "TEMP_RST",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 1700,
          required = true,
          subsubtestname = "Measure_Voltage_SYS_RST",
          subtestname = "TEMP_RST",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 1950
        },
        {
          required = true,
          subsubtestname = "Drive_OVER_TEMP_COMP_OUT_L",
          subtestname = "TEMP_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_HD_CHG_ILIM_HIZ_L_TO_GND",
          subtestname = "TEMP_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Delay_3000ms",
          subtestname = "TEMP_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Config_CHRG_CLR_Output",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_CHRG_CLR_H",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Pull_Up_BTN_BMU_WAKE_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 1700,
          required = true,
          subsubtestname = "Measure_Pull_Up_BTN_BMU_WAKE_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 1900
        },
        {
          required = true,
          subsubtestname = "Config_RST_WARN_NRF_INT_Input",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Config_HD_BTN_NRF_007_Input",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_RST_WARN_NRF_INT_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Read_HD_BTN_NRF_007_H",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "string"
        },
        {
          lowerLimit = -10,
          required = true,
          subsubtestname = "Measure_HD_CHG_ILIM_HIZ_L_0",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "Release_BTN_BMU_WAKE_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Pull_Down_BUTTON_CONN",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_HD_BTN_NRF_007_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Delay_2500ms",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Measure_BTN_BMU_WAKE_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 500
        },
        {
          required = true,
          subsubtestname = "Delay_11500ms",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_PP3V3_PDC_TO_DMMCH0",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Start_Pulse_Measure",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_RST_WARN_NRF_INT_H",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Dmm_Sampling_PP3V3_PDC",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 18,
          required = true,
          subsubtestname = "Measure_PP3V3_PDC_Pulse_Time",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "ms",
          upperLimit = 22
        },
        {
          required = true,
          subsubtestname = "Relay_Disonnect_PP3V3_PDC_TO_DMMCH0",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 18,
          required = true,
          subsubtestname = "Measure_SYS_RST_PULSE_TIME",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "ms",
          upperLimit = 22
        },
        {
          required = true,
          subsubtestname = "Release_BUTTON_CONN",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 1700,
          required = true,
          subsubtestname = "Measure_Voltage_HD_CHG_ILIM_HIZ_L_1",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 1950
        },
        {
          required = true,
          subsubtestname = "Config_CHRG_CLR_Output",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_CHRG_CLR_H",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Delay_100ms",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          lowerLimit = -10,
          required = true,
          subsubtestname = "Measure_Voltage_HD_CHG_ILIM_HIZ_L_0",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "Config_NRF_305_PDC_RST_Output",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_305_PDC_RST_H",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          lowerLimit = -10,
          required = true,
          subsubtestname = "Measure_PP3V3_PDC",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "Set_NRF_305_PDC_RST_L",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "VBAT_I_SPKEAR_OFF",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer",
          units = "mA",
          upperLimit = 2
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP_SPK_TO_DMMCH1",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer"
        },
        {
          required = true,
          subsubtestname = "SPKEAR_ON",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer"
        },
        {
          lowerLimit = 10,
          required = true,
          subsubtestname = "VBAT_I_SPKEAR_ON",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer",
          units = "mA",
          upperLimit = 25
        },
        {
          required = true,
          subsubtestname = "Dmm_Sampling_Sine_Wave",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer"
        },
        {
          lowerLimit = 10,
          required = true,
          subsubtestname = "DELTA_I_SPKEAR_ON",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer",
          units = "mA",
          upperLimit = 25
        },
        {
          required = true,
          subsubtestname = "Analyze_Audio_Data",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer"
        },
        {
          lowerLimit = 2600,
          required = true,
          subsubtestname = "Get_Audio_Freq",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer",
          units = "Hz",
          upperLimit = 2800
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "Get_Audio_Vpp",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer",
          units = "mV",
          upperLimit = 3600
        },
        {
          required = true,
          subsubtestname = "ResetAll",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_USBUART_EN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP_VSYS_TO_PSU_BATTERY_POS1",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO"
        },
        {
          required = true,
          subsubtestname = "Power_On_PP_VSYS_8V",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO"
        },
        {
          required = true,
          subsubtestname = "Delay_5000ms",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO"
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P104_OH_CHG_QON_NRF_L",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P104_OL_CHG_QON_NRF_L",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P105_OH_NRF_BST_IN_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P105_OL_NRF_BST_IN_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P127_OH_NRF_VBUS_BST_EN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P127_OL_NRF_VBUS_BST_EN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P128_OH_NRF_VSYS_BST_EN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P128_OL_NRF_VSYS_BST_EN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P200_OH_NRF_ULPOD_SWDIO",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P200_OL_NRF_ULPOD_SWDIO",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P206_OH_NRF_ULPOD_SWDCLK",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P206_OL_NRF_ULPOD_SWDCLK",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P306_OH_NRF_306_ULPOD_RST",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P306_OL_NRF_306_ULPOD_RST",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P307_OH_NRF_VSYS_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P307_OL_NRF_VSYS_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P308_OH_NRF_VBST_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P308_OL_NRF_VBST_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P312_OH_NRF_312_CPS_PWRDN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P312_OL_NRF_312_CPS_PWRDN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          required = true,
          subsubtestname = "P000_IH_PDC_INT_NRF",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P000_IL_PDC_INT_NRF",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P008_IH_ULPOD_INT_NRF",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P008_IL_ULPOD_INT_NRF",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P101_IH_CPS_INT_NRF_101",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P101_IL_CPS_INT_NRF_101",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P103_IH_VSYS_BST_PG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P103_IL_VSYS_BST_PG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P116_IH_VBUS_BST_PG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P116_IL_VBUS_BST_PG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P126_IH_PDC0_PD_NEG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P126_IL_PDC0_PD_NEG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P208_IH_CHG_CE_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P208_IL_CHG_CE_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P310_IH_CHG_STAT_NRF_310",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P310_IL_CHG_STAT_NRF_310",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P311_IH_CHG_INT_NRF_311",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P311_IL_CHG_INT_NRF_311",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_BST_NTC0_NRF_129_TO_CCS",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Enable_VBUS_ADC_NRF_106_380mV",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_1",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 370,
          required = true,
          subsubtestname = "DMM_VBUS_ADC_NRF_106_380mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 390
        },
        {
          lowerLimit = 4500,
          required = true,
          subsubtestname = "VBUS_ADC_Read_5000mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 5500
        },
        {
          required = true,
          subsubtestname = "Enable_VBUS_ADC_NRF_106_684mV",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_2",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 674,
          required = true,
          subsubtestname = "DMM_VBUS_ADC_NRF_106_684mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 694
        },
        {
          lowerLimit = 8000,
          required = true,
          subsubtestname = "VBUS_ADC_Read_9000mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 10000
        },
        {
          required = true,
          subsubtestname = "Enable_VBUS_ADC_NRF_106_1140mV",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_3",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 1130,
          required = true,
          subsubtestname = "DMM_VBUS_ADC_NRF_106_1140mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 1150
        },
        {
          lowerLimit = 14000,
          required = true,
          subsubtestname = "VBUS_ADC_Read_15000mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 16000
        },
        {
          required = true,
          subsubtestname = "Disable_CCS",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_BST_NTC0_NRF_129_TO_CCS",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_VBST_ADC_NRF_100_TO_CCS",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Enable_VBST_ADC_NRF_100_400mV",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_1",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 390,
          required = true,
          subsubtestname = "DMM_VBST_ADC_NRF_100_400mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 410
        },
        {
          lowerLimit = 6000,
          required = true,
          subsubtestname = "VBST_ADC_Read_6500mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 7000
        },
        {
          required = true,
          subsubtestname = "Enable_VBST_ADC_NRF_100_738mV",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_2",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 728,
          required = true,
          subsubtestname = "DMM_VBST_ADC_NRF_100_738mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 748
        },
        {
          lowerLimit = 11000,
          required = true,
          subsubtestname = "VBST_ADC_Read_12000mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 13000
        },
        {
          required = true,
          subsubtestname = "Enable_VBST_ADC_NRF_100_1107mV",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_3",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 1097,
          required = true,
          subsubtestname = "DMM_VBST_ADC_NRF_100_1107mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 1117
        },
        {
          lowerLimit = 17000,
          required = true,
          subsubtestname = "VBST_ADC_Read_18000mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 19000
        },
        {
          required = true,
          subsubtestname = "ResetAll",
          subtestname = "Teardown",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "delay_300ms",
          subtestname = "Teardown",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "uploadFCTInfo",
          subtestname = "Teardown",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "addLogToInsight",
          subtestname = "Teardown",
          testname = "Fixture"
        }
      },
      mainActions = {
        {
          filename = "Fixture/HardwareCheck.csv",
          name = "Fixture_HardwareCheck",
          plugins = "*",
          testIdx = 1
        },
        {
          filename = "POWER_OFF/Resistance.csv",
          name = "POWER_OFF_Resistance",
          plugins = "*",
          testIdx = 2
        },
        {
          filename = "POWER_OFF/Leakage.csv",
          name = "POWER_OFF_Leakage",
          plugins = "*",
          testIdx = 3
        },
        {
          filename = "System_Info/SYS_RST_CURRENT.csv",
          name = "System_Info_SYS_RST_CURRENT",
          plugins = "*",
          testIdx = 4
        },
        {
          filename = "System_Info/SYS_POWER.csv",
          name = "System_Info_SYS_POWER",
          plugins = "*",
          testIdx = 5
        },
        {
          filename = "System_Info/SYS_Info.csv",
          name = "System_Info_SYS_Info",
          plugins = "*",
          testIdx = 6
        },
        {
          filename = "System_Info/NRF_NTC.csv",
          name = "System_Info_NRF_NTC",
          plugins = "*",
          testIdx = 7
        },
        {
          filename = "Calibration_NTC/NTC2_10C.csv",
          name = "Calibration_NTC_NTC2_10C",
          plugins = "*",
          testIdx = 8
        },
        {
          filename = "Calibration_NTC/NTC2_45C.csv",
          name = "Calibration_NTC_NTC2_45C",
          plugins = "*",
          testIdx = 9
        },
        {
          args = {
            {
              action = {
                actionIdx = 9,
                returnIdx = 1
              }
            },
            {
              action = {
                actionIdx = 9,
                returnIdx = 2
              }
            }
          },
          filename = "Calibration_NTC/NTC2_After_Cal.csv",
          name = "Calibration_NTC_NTC2_After_Cal",
          plugins = "*",
          testIdx = 10
        },
        {
          filename = "Calibration_NTC/NTC1_10C.csv",
          name = "Calibration_NTC_NTC1_10C",
          plugins = "*",
          testIdx = 11
        },
        {
          filename = "Calibration_NTC/NTC1_45C.csv",
          name = "Calibration_NTC_NTC1_45C",
          plugins = "*",
          testIdx = 12
        },
        {
          args = {
            {
              action = {
                actionIdx = 12,
                returnIdx = 1
              }
            },
            {
              action = {
                actionIdx = 12,
                returnIdx = 2
              }
            }
          },
          filename = "Calibration_NTC/NTC1_After_Cal.csv",
          name = "Calibration_NTC_NTC1_After_Cal",
          plugins = "*",
          testIdx = 13
        },
        {
          filename = "Calibration_NTC/NTC0_10C.csv",
          name = "Calibration_NTC_NTC0_10C",
          plugins = "*",
          testIdx = 14
        },
        {
          filename = "Calibration_NTC/NTC0_45C.csv",
          name = "Calibration_NTC_NTC0_45C",
          plugins = "*",
          testIdx = 15
        },
        {
          args = {
            {
              action = {
                actionIdx = 15,
                returnIdx = 1
              }
            },
            {
              action = {
                actionIdx = 15,
                returnIdx = 2
              }
            }
          },
          filename = "Calibration_NTC/NTC0_After_Cal.csv",
          name = "Calibration_NTC_NTC0_After_Cal",
          plugins = "*",
          testIdx = 16
        },
        {
          filename = "Buck_5V/No_Load.csv",
          name = "Buck_5V_No_Load",
          plugins = "*",
          testIdx = 17
        },
        {
          args = {
            {
              action = {
                actionIdx = 17,
                returnIdx = 1
              }
            }
          },
          filename = "Buck_5V/Load_200mA_PP5V_AON.csv",
          name = "Buck_5V_Load_200mA_PP5V_AON",
          plugins = "*",
          testIdx = 18
        },
        {
          filename = "Buck_3V3/No_Load.csv",
          name = "Buck_3V3_No_Load",
          plugins = "*",
          testIdx = 19
        },
        {
          args = {
            {
              action = {
                actionIdx = 19,
                returnIdx = 1
              }
            }
          },
          filename = "Buck_3V3/Load_200mA_PP3V3_PDC.csv",
          name = "Buck_3V3_Load_200mA_PP3V3_PDC",
          plugins = "*",
          testIdx = 20
        },
        {
          filename = "Buck_1V8/Load_10mA_1V8.csv",
          name = "Buck_1V8_Load_10mA_1V8",
          plugins = "*",
          testIdx = 21
        },
        {
          args = {
            {
              action = {
                actionIdx = 21,
                returnIdx = 1
              }
            }
          },
          filename = "Buck_1V8/Load_200mA_1V8_AON.csv",
          name = "Buck_1V8_Load_200mA_1V8_AON",
          plugins = "*",
          testIdx = 22
        },
        {
          filename = "I2C_Device_Scan/I2C_Scan.csv",
          name = "I2C_Device_Scan_I2C_Scan",
          plugins = "*",
          testIdx = 23
        },
        {
          filename = "LED/PP_VSYS_I.csv",
          name = "LED_PP_VSYS_I",
          plugins = "*",
          testIdx = 24
        },
        {
          args = {
            {
              action = {
                actionIdx = 24,
                returnIdx = 1
              }
            }
          },
          filename = "LED/LED_WHITE.csv",
          name = "LED_LED_WHITE",
          plugins = "*",
          testIdx = 25
        },
        {
          args = {
            {
              action = {
                actionIdx = 24,
                returnIdx = 1
              }
            }
          },
          filename = "LED/LED_RED.csv",
          name = "LED_LED_RED",
          plugins = "*",
          testIdx = 26
        },
        {
          args = {
            {
              action = {
                actionIdx = 24,
                returnIdx = 1
              }
            }
          },
          filename = "LED/LED_GREEN.csv",
          name = "LED_LED_GREEN",
          plugins = "*",
          testIdx = 27
        },
        {
          args = {
            {
              action = {
                actionIdx = 24,
                returnIdx = 1
              }
            }
          },
          filename = "LED/LED_BLUE.csv",
          name = "LED_LED_BLUE",
          plugins = "*",
          testIdx = 28
        },
        {
          filename = "LED/PP5V_OFF.csv",
          name = "LED_PP5V_OFF",
          plugins = "*",
          testIdx = 29
        },
        {
          filename = "HALFDOME/FW_RST.csv",
          name = "HALFDOME_FW_RST",
          plugins = "*",
          testIdx = 30
        },
        {
          filename = "HALFDOME/WTD_PET.csv",
          name = "HALFDOME_WTD_PET",
          plugins = "*",
          testIdx = 31
        },
        {
          filename = "HALFDOME/WTD_DIS.csv",
          name = "HALFDOME_WTD_DIS",
          plugins = "*",
          testIdx = 32
        },
        {
          filename = "HALFDOME/TEMP_RST.csv",
          name = "HALFDOME_TEMP_RST",
          plugins = "*",
          testIdx = 33
        },
        {
          filename = "HALFDOME/BTN_RST_EXIT_SHIP.csv",
          name = "HALFDOME_BTN_RST_EXIT_SHIP",
          plugins = "*",
          testIdx = 34
        },
        {
          filename = "HALFDOME/ILIM_HIZ.csv",
          name = "HALFDOME_ILIM_HIZ",
          plugins = "*",
          testIdx = 35
        },
        {
          filename = "Buzzer/SINE_2P7K_Test.csv",
          name = "Buzzer_SINE_2P7K_Test",
          plugins = "*",
          testIdx = 36
        },
        {
          filename = "NRF_GPIO/OUTPUT.csv",
          name = "NRF_GPIO_OUTPUT",
          plugins = "*",
          testIdx = 37
        },
        {
          filename = "NRF_GPIO/INPUT.csv",
          name = "NRF_GPIO_INPUT",
          plugins = "*",
          testIdx = 38
        },
        {
          filename = "ADC_READ/VBUS.csv",
          name = "ADC_READ_VBUS",
          plugins = "*",
          testIdx = 39
        },
        {
          filename = "ADC_READ/VBST.csv",
          name = "ADC_READ_VBST",
          plugins = "*",
          testIdx = 40
        }
      },
      mainTests = {
        {
          Conditions = "",
          Coverage = "HardwareCheck",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "Fixture",
          TestParameters = "",
          actions = {
            1
          },
          fullName = "Fixture HardwareCheck",
          outputs = {
            FIXTUREID = {
              actionIdx = 1,
              actionName = "Fixture_HardwareCheck",
              returnIdx = 1
            },
            MIXFWPACKAGE = {
              actionIdx = 1,
              actionName = "Fixture_HardwareCheck",
              returnIdx = 2
            },
            SLOTID = {
              actionIdx = 1,
              actionName = "Fixture_HardwareCheck",
              returnIdx = 3
            },
            StationName = {
              actionIdx = 1,
              actionName = "Fixture_HardwareCheck",
              returnIdx = 4
            },
            VENDORID = {
              actionIdx = 1,
              actionName = "Fixture_HardwareCheck",
              returnIdx = 5
            }
          },
          subTestName = "HardwareCheck",
          testName = "Fixture"
        },
        {
          Conditions = "",
          Coverage = "Resistance",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "POWER_OFF",
          TestParameters = "",
          actions = {
            2
          },
          deps = {
            1
          },
          fullName = "POWER_OFF Resistance",
          outputs = {
          },
          subTestName = "Resistance",
          testName = "POWER_OFF"
        },
        {
          Conditions = "",
          Coverage = "Leakage",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "POWER_OFF",
          TestParameters = "",
          actions = {
            3
          },
          deps = {
            2
          },
          fullName = "POWER_OFF Leakage",
          outputs = {
          },
          subTestName = "Leakage",
          testName = "POWER_OFF"
        },
        {
          Conditions = "",
          Coverage = "SYS_RST_CURRENT",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "System_Info",
          TestParameters = "",
          actions = {
            4
          },
          deps = {
            3
          },
          fullName = "System_Info SYS_RST_CURRENT",
          outputs = {
          },
          subTestName = "SYS_RST_CURRENT",
          testName = "System_Info"
        },
        {
          Conditions = "",
          Coverage = "SYS_POWER",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "System_Info",
          TestParameters = "",
          actions = {
            5
          },
          deps = {
            4
          },
          fullName = "System_Info SYS_POWER",
          outputs = {
          },
          subTestName = "SYS_POWER",
          testName = "System_Info"
        },
        {
          Conditions = "",
          Coverage = "SYS_Info",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "System_Info",
          TestParameters = "",
          actions = {
            6
          },
          deps = {
            5
          },
          fullName = "System_Info SYS_Info",
          outputs = {
            MLBSN = {
              actionIdx = 6,
              actionName = "System_Info_SYS_Info",
              returnIdx = 1
            }
          },
          subTestName = "SYS_Info",
          testName = "System_Info"
        },
        {
          Conditions = "",
          Coverage = "NRF_NTC",
          SamplingGroup = "",
          Technology = "System_Info",
          TestParameters = "",
          actions = {
            7
          },
          deps = {
            6
          },
          fullName = "System_Info NRF_NTC",
          outputs = {
          },
          subTestName = "NRF_NTC",
          testName = "System_Info"
        },
        {
          Conditions = "",
          Coverage = "NTC2_10C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            8
          },
          deps = {
            7
          },
          fullName = "Calibration_NTC NTC2_10C",
          outputs = {
            DUT_NTC2 = {
              actionIdx = 8,
              actionName = "Calibration_NTC_NTC2_10C",
              returnIdx = 1
            },
            Fixture_NTC2 = {
              actionIdx = 8,
              actionName = "Calibration_NTC_NTC2_10C",
              returnIdx = 2
            },
            NTC2_VOLT = {
              actionIdx = 8,
              actionName = "Calibration_NTC_NTC2_10C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 8,
              actionName = "Calibration_NTC_NTC2_10C",
              returnIdx = 4
            },
            Tmp_Offset_NTC2 = {
              actionIdx = 8,
              actionName = "Calibration_NTC_NTC2_10C",
              returnIdx = 5
            }
          },
          subTestName = "NTC2_10C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC2_45C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            9
          },
          deps = {
            8
          },
          fullName = "Calibration_NTC NTC2_45C",
          outputs = {
            DUT_NTC2 = {
              actionIdx = 9,
              actionName = "Calibration_NTC_NTC2_45C",
              returnIdx = 1
            },
            Fixture_NTC2 = {
              actionIdx = 9,
              actionName = "Calibration_NTC_NTC2_45C",
              returnIdx = 2
            },
            NTC2_VOLT = {
              actionIdx = 9,
              actionName = "Calibration_NTC_NTC2_45C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 9,
              actionName = "Calibration_NTC_NTC2_45C",
              returnIdx = 4
            }
          },
          subTestName = "NTC2_45C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC2_After_Cal",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            10
          },
          deps = {
            9
          },
          fullName = "Calibration_NTC NTC2_After_Cal",
          outputs = {
            Tmp_Offset_NTC2 = {
              actionIdx = 10,
              actionName = "Calibration_NTC_NTC2_After_Cal",
              returnIdx = 1
            },
            Tmp_Offset_NTC2_Hex = {
              actionIdx = 10,
              actionName = "Calibration_NTC_NTC2_After_Cal",
              returnIdx = 2
            },
            Tmp_Offset_NTC2_Read = {
              actionIdx = 10,
              actionName = "Calibration_NTC_NTC2_After_Cal",
              returnIdx = 3
            }
          },
          subTestName = "NTC2_After_Cal",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC1_10C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            11
          },
          deps = {
            10
          },
          fullName = "Calibration_NTC NTC1_10C",
          outputs = {
            DUT_NTC1 = {
              actionIdx = 11,
              actionName = "Calibration_NTC_NTC1_10C",
              returnIdx = 1
            },
            Fixture_NTC1 = {
              actionIdx = 11,
              actionName = "Calibration_NTC_NTC1_10C",
              returnIdx = 2
            },
            NTC1_VOLT = {
              actionIdx = 11,
              actionName = "Calibration_NTC_NTC1_10C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 11,
              actionName = "Calibration_NTC_NTC1_10C",
              returnIdx = 4
            },
            Tmp_Offset_NTC1 = {
              actionIdx = 11,
              actionName = "Calibration_NTC_NTC1_10C",
              returnIdx = 5
            }
          },
          subTestName = "NTC1_10C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC1_45C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            12
          },
          deps = {
            11
          },
          fullName = "Calibration_NTC NTC1_45C",
          outputs = {
            DUT_NTC1 = {
              actionIdx = 12,
              actionName = "Calibration_NTC_NTC1_45C",
              returnIdx = 1
            },
            Fixture_NTC1 = {
              actionIdx = 12,
              actionName = "Calibration_NTC_NTC1_45C",
              returnIdx = 2
            },
            NTC1_VOLT = {
              actionIdx = 12,
              actionName = "Calibration_NTC_NTC1_45C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 12,
              actionName = "Calibration_NTC_NTC1_45C",
              returnIdx = 4
            }
          },
          subTestName = "NTC1_45C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC1_After_Cal",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            13
          },
          deps = {
            12
          },
          fullName = "Calibration_NTC NTC1_After_Cal",
          outputs = {
            Tmp_Offset_NTC1 = {
              actionIdx = 13,
              actionName = "Calibration_NTC_NTC1_After_Cal",
              returnIdx = 1
            },
            Tmp_Offset_NTC1_Hex = {
              actionIdx = 13,
              actionName = "Calibration_NTC_NTC1_After_Cal",
              returnIdx = 2
            },
            Tmp_Offset_NTC1_Read = {
              actionIdx = 13,
              actionName = "Calibration_NTC_NTC1_After_Cal",
              returnIdx = 3
            }
          },
          subTestName = "NTC1_After_Cal",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC0_10C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            14
          },
          deps = {
            13
          },
          fullName = "Calibration_NTC NTC0_10C",
          outputs = {
            DUT_NTC0 = {
              actionIdx = 14,
              actionName = "Calibration_NTC_NTC0_10C",
              returnIdx = 1
            },
            Fixture_NTC0 = {
              actionIdx = 14,
              actionName = "Calibration_NTC_NTC0_10C",
              returnIdx = 2
            },
            NTC0_VOLT = {
              actionIdx = 14,
              actionName = "Calibration_NTC_NTC0_10C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 14,
              actionName = "Calibration_NTC_NTC0_10C",
              returnIdx = 4
            },
            Tmp_Offset_NTC0 = {
              actionIdx = 14,
              actionName = "Calibration_NTC_NTC0_10C",
              returnIdx = 5
            }
          },
          subTestName = "NTC0_10C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC0_45C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            15
          },
          deps = {
            14
          },
          fullName = "Calibration_NTC NTC0_45C",
          outputs = {
            DUT_NTC0 = {
              actionIdx = 15,
              actionName = "Calibration_NTC_NTC0_45C",
              returnIdx = 1
            },
            Fixture_NTC0 = {
              actionIdx = 15,
              actionName = "Calibration_NTC_NTC0_45C",
              returnIdx = 2
            },
            NTC0_VOLT = {
              actionIdx = 15,
              actionName = "Calibration_NTC_NTC0_45C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 15,
              actionName = "Calibration_NTC_NTC0_45C",
              returnIdx = 4
            }
          },
          subTestName = "NTC0_45C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC0_After_Cal",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            16
          },
          deps = {
            15
          },
          fullName = "Calibration_NTC NTC0_After_Cal",
          outputs = {
            Tmp_Offset_NTC0 = {
              actionIdx = 16,
              actionName = "Calibration_NTC_NTC0_After_Cal",
              returnIdx = 1
            },
            Tmp_Offset_NTC0_Hex = {
              actionIdx = 16,
              actionName = "Calibration_NTC_NTC0_After_Cal",
              returnIdx = 2
            },
            Tmp_Offset_NTC0_Read = {
              actionIdx = 16,
              actionName = "Calibration_NTC_NTC0_After_Cal",
              returnIdx = 3
            }
          },
          subTestName = "NTC0_After_Cal",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "No_Load",
          SamplingGroup = "",
          Technology = "Buck_5V",
          TestParameters = "",
          actions = {
            17
          },
          deps = {
            16
          },
          fullName = "Buck_5V No_Load",
          outputs = {
            PP_VSYS_I_No_Load = {
              actionIdx = 17,
              actionName = "Buck_5V_No_Load",
              returnIdx = 1
            }
          },
          subTestName = "No_Load",
          testName = "Buck_5V"
        },
        {
          Conditions = "",
          Coverage = "Load_200mA_PP5V_AON",
          SamplingGroup = "",
          Technology = "Buck_5V",
          TestParameters = "",
          actions = {
            18
          },
          deps = {
            17
          },
          fullName = "Buck_5V Load_200mA_PP5V_AON",
          outputs = {
            Buck_5V_Output_Current = {
              actionIdx = 18,
              actionName = "Buck_5V_Load_200mA_PP5V_AON",
              returnIdx = 1
            },
            PP5V_AON_V_Load_200mA = {
              actionIdx = 18,
              actionName = "Buck_5V_Load_200mA_PP5V_AON",
              returnIdx = 2
            },
            VSYS_I_Load_200mA = {
              actionIdx = 18,
              actionName = "Buck_5V_Load_200mA_PP5V_AON",
              returnIdx = 3
            },
            VSYS_V_Load_200mA = {
              actionIdx = 18,
              actionName = "Buck_5V_Load_200mA_PP5V_AON",
              returnIdx = 4
            }
          },
          subTestName = "Load_200mA_PP5V_AON",
          testName = "Buck_5V"
        },
        {
          Conditions = "",
          Coverage = "No_Load",
          SamplingGroup = "",
          Technology = "Buck_3V3",
          TestParameters = "",
          actions = {
            19
          },
          deps = {
            18
          },
          fullName = "Buck_3V3 No_Load",
          outputs = {
            PP_VSYS_I_No_Load_3V3 = {
              actionIdx = 19,
              actionName = "Buck_3V3_No_Load",
              returnIdx = 1
            }
          },
          subTestName = "No_Load",
          testName = "Buck_3V3"
        },
        {
          Conditions = "",
          Coverage = "Load_200mA_PP3V3_PDC",
          SamplingGroup = "",
          Technology = "Buck_3V3",
          TestParameters = "",
          actions = {
            20
          },
          deps = {
            19
          },
          fullName = "Buck_3V3 Load_200mA_PP3V3_PDC",
          outputs = {
            Buck_3V3_Output_Current_3V3 = {
              actionIdx = 20,
              actionName = "Buck_3V3_Load_200mA_PP3V3_PDC",
              returnIdx = 1
            },
            PP3V3_AON_V_Load_200mA_3V3 = {
              actionIdx = 20,
              actionName = "Buck_3V3_Load_200mA_PP3V3_PDC",
              returnIdx = 2
            },
            VSYS_I_Load_200mA_3V3 = {
              actionIdx = 20,
              actionName = "Buck_3V3_Load_200mA_PP3V3_PDC",
              returnIdx = 3
            },
            VSYS_V_Load_200mA_3V3 = {
              actionIdx = 20,
              actionName = "Buck_3V3_Load_200mA_PP3V3_PDC",
              returnIdx = 4
            }
          },
          subTestName = "Load_200mA_PP3V3_PDC",
          testName = "Buck_3V3"
        },
        {
          Conditions = "",
          Coverage = "Load_10mA_1V8",
          SamplingGroup = "",
          Technology = "Buck_1V8",
          TestParameters = "",
          actions = {
            21
          },
          deps = {
            20
          },
          fullName = "Buck_1V8 Load_10mA_1V8",
          outputs = {
            PP_VSYS_I_No_Load_1V8 = {
              actionIdx = 21,
              actionName = "Buck_1V8_Load_10mA_1V8",
              returnIdx = 1
            }
          },
          subTestName = "Load_10mA_1V8",
          testName = "Buck_1V8"
        },
        {
          Conditions = "",
          Coverage = "Load_200mA_1V8_AON",
          SamplingGroup = "",
          Technology = "Buck_1V8",
          TestParameters = "",
          actions = {
            22
          },
          deps = {
            21
          },
          fullName = "Buck_1V8 Load_200mA_1V8_AON",
          outputs = {
            Buck_1V8_Output_Current = {
              actionIdx = 22,
              actionName = "Buck_1V8_Load_200mA_1V8_AON",
              returnIdx = 1
            },
            PP1V8_V_Load_200mA = {
              actionIdx = 22,
              actionName = "Buck_1V8_Load_200mA_1V8_AON",
              returnIdx = 2
            },
            VSYS_I_Load_200mA_1V8 = {
              actionIdx = 22,
              actionName = "Buck_1V8_Load_200mA_1V8_AON",
              returnIdx = 3
            },
            VSYS_V_Load_200mA_1V8 = {
              actionIdx = 22,
              actionName = "Buck_1V8_Load_200mA_1V8_AON",
              returnIdx = 4
            }
          },
          subTestName = "Load_200mA_1V8_AON",
          testName = "Buck_1V8"
        },
        {
          Conditions = "",
          Coverage = "I2C_Scan",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "I2C_Device_Scan",
          TestParameters = "",
          actions = {
            23
          },
          deps = {
            22
          },
          fullName = "I2C_Device_Scan I2C_Scan",
          outputs = {
            ACCEL_Data = {
              actionIdx = 23,
              actionName = "I2C_Device_Scan_I2C_Scan",
              returnIdx = 1
            },
            diags_output = {
              actionIdx = 23,
              actionName = "I2C_Device_Scan_I2C_Scan",
              returnIdx = 2
            }
          },
          subTestName = "I2C_Scan",
          testName = "I2C_Device_Scan"
        },
        {
          Conditions = "",
          Coverage = "PP_VSYS_I",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            24
          },
          deps = {
            23
          },
          fullName = "LED PP_VSYS_I",
          outputs = {
            PP_VSYS_I_No_Load_LED = {
              actionIdx = 24,
              actionName = "LED_PP_VSYS_I",
              returnIdx = 1
            }
          },
          subTestName = "PP_VSYS_I",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "LED_WHITE",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            25
          },
          deps = {
            24
          },
          fullName = "LED LED_WHITE",
          outputs = {
            VBAT_I_LED_WHITE_ON = {
              actionIdx = 25,
              actionName = "LED_LED_WHITE",
              returnIdx = 1
            },
            White_E = {
              actionIdx = 25,
              actionName = "LED_LED_WHITE",
              returnIdx = 2
            }
          },
          subTestName = "LED_WHITE",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "LED_RED",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            26
          },
          deps = {
            24,
            25
          },
          fullName = "LED LED_RED",
          outputs = {
            Red_E = {
              actionIdx = 26,
              actionName = "LED_LED_RED",
              returnIdx = 1
            },
            VBAT_I_LED_RED_ON = {
              actionIdx = 26,
              actionName = "LED_LED_RED",
              returnIdx = 2
            }
          },
          subTestName = "LED_RED",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "LED_GREEN",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            27
          },
          deps = {
            24,
            26
          },
          fullName = "LED LED_GREEN",
          outputs = {
            Green_E = {
              actionIdx = 27,
              actionName = "LED_LED_GREEN",
              returnIdx = 1
            },
            VBAT_I_LED_GREEN_ON = {
              actionIdx = 27,
              actionName = "LED_LED_GREEN",
              returnIdx = 2
            }
          },
          subTestName = "LED_GREEN",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "LED_BLUE",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            28
          },
          deps = {
            24,
            27
          },
          fullName = "LED LED_BLUE",
          outputs = {
            Blue_E = {
              actionIdx = 28,
              actionName = "LED_LED_BLUE",
              returnIdx = 1
            },
            VBAT_I_LED_BLUE_ON = {
              actionIdx = 28,
              actionName = "LED_LED_BLUE",
              returnIdx = 2
            }
          },
          subTestName = "LED_BLUE",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "PP5V_OFF",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            29
          },
          deps = {
            28
          },
          fullName = "LED PP5V_OFF",
          outputs = {
          },
          subTestName = "PP5V_OFF",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "FW_RST",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            30
          },
          deps = {
            29
          },
          fullName = "HALFDOME FW_RST",
          outputs = {
          },
          subTestName = "FW_RST",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "WTD_PET",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            31
          },
          deps = {
            30
          },
          fullName = "HALFDOME WTD_PET",
          outputs = {
            WTD_FLG_Path = {
              actionIdx = 31,
              actionName = "HALFDOME_WTD_PET",
              returnIdx = 1
            }
          },
          subTestName = "WTD_PET",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "WTD_DIS",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            32
          },
          deps = {
            31
          },
          fullName = "HALFDOME WTD_DIS",
          outputs = {
          },
          subTestName = "WTD_DIS",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "TEMP_RST",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            33
          },
          deps = {
            32
          },
          fullName = "HALFDOME TEMP_RST",
          outputs = {
          },
          subTestName = "TEMP_RST",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "BTN_RST_EXIT_SHIP",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            34
          },
          deps = {
            33
          },
          fullName = "HALFDOME BTN_RST_EXIT_SHIP",
          outputs = {
            PDC_File = {
              actionIdx = 34,
              actionName = "HALFDOME_BTN_RST_EXIT_SHIP",
              returnIdx = 1
            }
          },
          subTestName = "BTN_RST_EXIT_SHIP",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "ILIM_HIZ",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            35
          },
          deps = {
            34
          },
          fullName = "HALFDOME ILIM_HIZ",
          outputs = {
          },
          subTestName = "ILIM_HIZ",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "SINE_2P7K_Test",
          SamplingGroup = "",
          Technology = "Buzzer",
          TestParameters = "",
          actions = {
            36
          },
          deps = {
            35
          },
          fullName = "Buzzer SINE_2P7K_Test",
          outputs = {
            PATH = {
              actionIdx = 36,
              actionName = "Buzzer_SINE_2P7K_Test",
              returnIdx = 1
            },
            VBAT_I_SPKEAR_OFF = {
              actionIdx = 36,
              actionName = "Buzzer_SINE_2P7K_Test",
              returnIdx = 2
            },
            VBAT_I_SPKEAR_ON = {
              actionIdx = 36,
              actionName = "Buzzer_SINE_2P7K_Test",
              returnIdx = 3
            },
            retTable = {
              actionIdx = 36,
              actionName = "Buzzer_SINE_2P7K_Test",
              returnIdx = 4
            }
          },
          subTestName = "SINE_2P7K_Test",
          testName = "Buzzer"
        },
        {
          Conditions = "",
          Coverage = "OUTPUT",
          SamplingGroup = "",
          Technology = "NRF_GPIO",
          TestParameters = "",
          actions = {
            37
          },
          deps = {
            36
          },
          fullName = "NRF_GPIO OUTPUT",
          outputs = {
          },
          subTestName = "OUTPUT",
          testName = "NRF_GPIO"
        },
        {
          Conditions = "",
          Coverage = "INPUT",
          SamplingGroup = "",
          Technology = "NRF_GPIO",
          TestParameters = "",
          actions = {
            38
          },
          deps = {
            37
          },
          fullName = "NRF_GPIO INPUT",
          outputs = {
          },
          subTestName = "INPUT",
          testName = "NRF_GPIO"
        },
        {
          Conditions = "",
          Coverage = "VBUS",
          SamplingGroup = "",
          Technology = "ADC_READ",
          TestParameters = "",
          actions = {
            39
          },
          deps = {
            38
          },
          fullName = "ADC_READ VBUS",
          outputs = {
          },
          subTestName = "VBUS",
          testName = "ADC_READ"
        },
        {
          Conditions = "",
          Coverage = "VBST",
          SamplingGroup = "",
          Technology = "ADC_READ",
          TestParameters = "",
          actions = {
            40
          },
          deps = {
            39
          },
          fullName = "ADC_READ VBST",
          outputs = {
          },
          subTestName = "VBST",
          testName = "ADC_READ"
        }
      },
      samplings = {
      },
      teardownActions = {
        {
          dataQuery = true,
          name = "data",
          testIdx = 1
        },
        {
          args = {
            {
              action = {
                actionIdx = 1,
                returnIdx = 4
              }
            }
          },
          filename = "Fixture/Teardown.csv",
          name = "Fixture_Teardown",
          plugins = "*",
          testIdx = 1
        }
      },
      teardownTests = {
        {
          Conditions = "",
          Coverage = "Teardown",
          SamplingGroup = "",
          Technology = "Fixture",
          TestParameters = "",
          actions = {
            1,
            2
          },
          fullName = "Fixture Teardown",
          outputs = {
          },
          subTestName = "Teardown",
          testName = "Fixture"
        }
      },
      testPlanAttribute = {
        limitsHasConditions = false,
        requireConditionValidator = false
      }
    },
    Production = {
      conditions = {
        group = {
          {
            generator = {
              func = "mode",
              module = "Schooner/DefaultConditionGeneratorAndValidator"
            },
            name = "Mode",
            validator = {
              allowedList = {
                "Audit",
                "Production"
              },
              type = "IN"
            }
          }
        },
        test = {
          {
            name = "vendorID",
            validator = {
              allowedList = {
                "_INIT_",
                "0x01:INVT"
              },
              type = "IN"
            }
          },
          {
            name = "TEST_MODE",
            validator = {
              allowedList = {
                "_INIT_",
                "Production",
                "Audit"
              },
              type = "IN"
            }
          }
        }
      },
      limitInfo = {
        conditions = {
        },
        limitPositionInfos = {
        },
        withMode = false,
        withProduct = false,
        withStationType = false
      },
      limits = {
        {
          required = true,
          subsubtestname = "stationInfo_Product",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "stationInfo_Station_name",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "createAttr_Station_name",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "stationInfo_Vendor_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "createAttr_Vendor_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "stationInfo_Slot_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "createAttr_Slot_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "stationInfo_Fixture_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "createAttr_Fixture_ID",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "stationInfo_Xavier_FW_Version",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "createAttr_Xavier_FW_Version",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "ResetAll",
          subtestname = "HardwareCheck",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_1000mV_3uA",
          subtestname = "Resistance",
          testname = "POWER_OFF"
        },
        {
          lowerLimit = 50,
          required = true,
          subsubtestname = "NTC2_NRF_131_TO_GND",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 165
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_GND_TO_FIXTURE_GND",
          subtestname = "Resistance",
          testname = "POWER_OFF"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_1000mV_100uA",
          subtestname = "Resistance",
          testname = "POWER_OFF"
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_ACCEL_A51_SDA_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_ACCEL_A51_SCL_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_CHGR_SDA_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_CHGR_SCL_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_PDC_ULPOD_SDA_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_PDC_ULPOD_SCL_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_BMU_SDA_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "I2C_NRF_BMU_SCL_TO_PP1V8",
          subtestname = "Resistance",
          testname = "POWER_OFF",
          units = "kohm",
          upperLimit = 2.4
        },
        {
          required = true,
          subsubtestname = "Relay_DUT_GND_TO_FIXTURE_GND",
          subtestname = "Leakage",
          testname = "POWER_OFF"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_500mV_200uA",
          subtestname = "Leakage",
          testname = "POWER_OFF"
        },
        {
          required = true,
          subsubtestname = "Delay_2000ms",
          subtestname = "Leakage",
          testname = "POWER_OFF"
        },
        {
          lowerLimit = -1,
          required = true,
          subsubtestname = "Measure_Leakage_PP_VSYS",
          subtestname = "Leakage",
          testname = "POWER_OFF",
          units = "mA",
          upperLimit = 1
        },
        {
          lowerLimit = -1,
          required = true,
          subsubtestname = "Measure_Leakage_PP5V_AON",
          subtestname = "Leakage",
          testname = "POWER_OFF",
          units = "mA",
          upperLimit = 1
        },
        {
          lowerLimit = -1,
          required = true,
          subsubtestname = "Measure_Leakage_PP3V3_AON",
          subtestname = "Leakage",
          testname = "POWER_OFF",
          units = "mA",
          upperLimit = 1
        },
        {
          lowerLimit = -1,
          required = true,
          subsubtestname = "Measure_Leakage_PP3V3_PDC",
          subtestname = "Leakage",
          testname = "POWER_OFF",
          units = "mA",
          upperLimit = 1
        },
        {
          lowerLimit = -1,
          required = true,
          subsubtestname = "Measure_Leakage_PP1V83",
          subtestname = "Leakage",
          testname = "POWER_OFF",
          units = "mA",
          upperLimit = 1
        },
        {
          required = true,
          subsubtestname = "ResetAll",
          subtestname = "Leakage",
          testname = "POWER_OFF"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_NRF2SYS_SHDN_1KPULLDOWN",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Pull_Up_SYS_RST",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP_VSYS_TO_PSU_BATTERY_POS1",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Power_On_PP_VSYS_8V",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "Reset_Current_System",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info",
          units = "mA",
          upperLimit = 2
        },
        {
          required = true,
          subsubtestname = "Release_SYS_RST",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Delay_5000ms",
          subtestname = "SYS_RST_CURRENT",
          testname = "System_Info"
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "PP_VSYS_I",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mA",
          upperLimit = 2
        },
        {
          lowerLimit = 7900,
          required = true,
          subsubtestname = "PP_VSYS_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 8100
        },
        {
          lowerLimit = 5100,
          required = true,
          subsubtestname = "PP5V0_AON_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 5300
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "PP1V83_AON_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "PP1V83_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_AON_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_PDC_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_DECUSB_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 850,
          required = true,
          subsubtestname = "PP_RADIO_DECRF_V",
          subtestname = "SYS_POWER",
          testname = "System_Info",
          units = "mV",
          upperLimit = 950
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "SYS_Info",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "Read_MLB_SN",
          subtestname = "SYS_Info",
          testname = "System_Info"
        },
        {
          required = true,
          subsubtestname = "HWID_Ver",
          subtestname = "SYS_Info",
          testname = "System_Info",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "FW_Ver_NRF",
          subtestname = "SYS_Info",
          testname = "System_Info",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Flash_ID",
          subtestname = "SYS_Info",
          testname = "System_Info",
          units = "string"
        },
        {
          lowerLimit = 1,
          required = true,
          subsubtestname = "Flash_Write_Read_Test",
          subtestname = "SYS_Info",
          testname = "System_Info",
          upperLimit = 1
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "NRF_NTC",
          testname = "System_Info"
        },
        {
          lowerLimit = 20,
          required = true,
          subsubtestname = "NTC2_TEMP",
          subtestname = "NRF_NTC",
          testname = "System_Info",
          units = "C",
          upperLimit = 30
        },
        {
          lowerLimit = 20,
          required = true,
          subsubtestname = "BST_NTC0_TEMP",
          subtestname = "NRF_NTC",
          testname = "System_Info",
          units = "C",
          upperLimit = 30
        },
        {
          lowerLimit = 20,
          required = true,
          subsubtestname = "CMC_NTC1_TEMP",
          subtestname = "NRF_NTC",
          testname = "System_Info",
          units = "C",
          upperLimit = 30
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_NTC2_NRF_131_TO_CCS",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_1500mV_1mA",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC2_TEMP",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 1450,
          required = true,
          subsubtestname = "DMM_READ_NTC2_V",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1550
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 9,
          required = true,
          subsubtestname = "Calculate-NTC2_Temp",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 11
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC2_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_850mV_1mA",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC2_TEMP",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 800,
          required = true,
          subsubtestname = "DMM_READ_NTC2_V",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 900
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 44,
          required = true,
          subsubtestname = "Calculate-NTC2_Temp",
          subtestname = "NTC2_45C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 46
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Hex",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Write_NTC2_TEMP_Offset",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Read_NTC2_TEMP_Offset",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Float",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Disable_CCS",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_NTC2_NRF_131_TO_CCS",
          subtestname = "NTC2_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_CMC_NTC1_NRF_130_TO_CCS",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_1500mV_1mA",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC1_TEMP",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 1450,
          required = true,
          subsubtestname = "DMM_READ_CMC_NTC1_NRF_130_V",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1550
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 9,
          required = true,
          subsubtestname = "Calculate-NTC1_Temp",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 11
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC1_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_850mV_1mA",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC1_TEMP",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 800,
          required = true,
          subsubtestname = "DMM_READ_CMC_NTC1_NRF_130_V",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 900
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 44,
          required = true,
          subsubtestname = "Calculate-NTC1_Temp",
          subtestname = "NTC1_45C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 46
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Hex",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Write_NTC1_TEMP_Offset",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Read_NTC1_TEMP_Offset",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Float",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Disable_CCS",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_CMC_NTC1_NRF_130_TO_CCS",
          subtestname = "NTC1_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_BST_NTC0_NRF_129_TO_CCS",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_1500mV_1mA",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC0_TEMP",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 1450,
          required = true,
          subsubtestname = "DMM_READ_BST_NTC0_NRF_129_V",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1550
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 9,
          required = true,
          subsubtestname = "Calculate-NTC0_Temp",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 11
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC0_10C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "CCS_Enable_850mV_1mA",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "NTC0_TEMP",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          lowerLimit = 800,
          required = true,
          subsubtestname = "DMM_READ_BST_NTC0_NRF_129_V",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 900
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "DMM_READ_PP1V83_V",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 44,
          required = true,
          subsubtestname = "Calculate-NTC0_Temp",
          subtestname = "NTC0_45C",
          testname = "Calibration_NTC",
          units = "C",
          upperLimit = 46
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC",
          units = "C"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Hex",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Write_NTC0_TEMP_Offset",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Read_NTC0_TEMP_Offset",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "TEMP_OFFSET_Float",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Disable_CCS",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_BST_NTC0_NRF_129_TO_CCS",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "ResetAll",
          subtestname = "NTC0_After_Cal",
          testname = "Calibration_NTC"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP_VSYS_TO_PSU_BATTERY_POS1",
          subtestname = "No_Load",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Power_On_PP_VSYS_8V",
          subtestname = "No_Load",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Delay_5000ms",
          subtestname = "No_Load",
          testname = "Buck_5V"
        },
        {
          lowerLimit = 5100,
          required = true,
          subsubtestname = "PP5V_AON_V_No_Load",
          subtestname = "No_Load",
          testname = "Buck_5V",
          units = "mV",
          upperLimit = 5300
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "PP_VSYS_I_No_Load",
          subtestname = "No_Load",
          testname = "Buck_5V",
          units = "mA",
          upperLimit = 2
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_No_Load",
          subtestname = "No_Load",
          testname = "Buck_5V",
          units = "mV",
          upperLimit = 100
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP5V_AON_TO_E_LOAD_1_INPUT2",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Eload1_Enable_200mA_PP5V_AON",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          lowerLimit = 7900,
          required = true,
          subsubtestname = "PP_VSYS_V_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "mV",
          upperLimit = 8100
        },
        {
          lowerLimit = 120,
          required = true,
          subsubtestname = "PP_VSYS_I_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "mA",
          upperLimit = 160
        },
        {
          lowerLimit = 5050,
          required = true,
          subsubtestname = "PP5V_AON_V_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "mV",
          upperLimit = 5250
        },
        {
          lowerLimit = 190,
          required = true,
          subsubtestname = "Buck_5V_Output_Current_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "mA",
          upperLimit = 210
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "mV",
          upperLimit = 100
        },
        {
          lowerLimit = 90,
          required = true,
          subsubtestname = "Eff_Load_200mA",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V",
          units = "%",
          upperLimit = 95
        },
        {
          required = true,
          subsubtestname = "Eload1_Disable",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Delay_2000ms",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_PP5V_AON_TO_E_LOAD_1_INPUT2",
          subtestname = "Load_200mA_PP5V_AON",
          testname = "Buck_5V"
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_AON_V_No_Load",
          subtestname = "No_Load",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_PDC_V_No_Load",
          subtestname = "No_Load",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "PP_VSYS_I_No_Load",
          subtestname = "No_Load",
          testname = "Buck_3V3",
          units = "mA",
          upperLimit = 2
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_No_Load",
          subtestname = "No_Load",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 50
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP3V3_PDC_TO_E_LOAD_1_INPUT5",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          required = true,
          subsubtestname = "Eload1_Enable_200mA_PP3V3_PDC",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          lowerLimit = 7900,
          required = true,
          subsubtestname = "PP_VSYS_V_Load_200mA",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 8100
        },
        {
          lowerLimit = 80,
          required = true,
          subsubtestname = "PP_VSYS_I_Load_200mA",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mA",
          upperLimit = 110
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "PP3V3_AON_V_200mA_Load",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 3400
        },
        {
          lowerLimit = 3150,
          required = true,
          subsubtestname = "PP3V3_PDC_V_200mA_Load",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 3350
        },
        {
          lowerLimit = 190,
          required = true,
          subsubtestname = "Buck_3V3_Output_Current_Load_200mA",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mA",
          upperLimit = 210
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_Load_200mA",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "mV",
          upperLimit = 10
        },
        {
          lowerLimit = 89,
          required = true,
          subsubtestname = "Eff_Load_200mA",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3",
          units = "%",
          upperLimit = 94
        },
        {
          required = true,
          subsubtestname = "Eload1_Disable",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          required = true,
          subsubtestname = "Delay_2000ms",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_PP3V3_PDC_TO_E_LOAD_1_INPUT5",
          subtestname = "Load_200mA_PP3V3_PDC",
          testname = "Buck_3V3"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_NRF2SYS_SHDN_1KPULLDOWN",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "PP_VSYS_I_No_Load",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8",
          units = "mA",
          upperLimit = 2
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP1V83_TO_E_LOAD_1_INPUT6",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Eload1_Enable_10mA_PP1V83",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_1",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "PP1V83_AON_V_10mA_Load",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 1700,
          required = true,
          subsubtestname = "PP1V83_V_10mA_Load",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 1850
        },
        {
          lowerLimit = 2,
          required = true,
          subsubtestname = "PP_VSYS_I_10mA_Load",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8",
          units = "mA",
          upperLimit = 5
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_10mA_Load",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 50
        },
        {
          required = true,
          subsubtestname = "Eload1_Disable",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_2",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_PP1V83_TO_E_LOAD_1_INPUT6",
          subtestname = "Load_10mA_1V8",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP1V83_AON_TO_E_LOAD_1_INPUT4",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Eload1_Enable_200mA_PP1V83_AON",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_1",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          lowerLimit = 7900,
          required = true,
          subsubtestname = "PP_VSYS_V_Load_200mA",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 8100
        },
        {
          lowerLimit = 30,
          required = true,
          subsubtestname = "PP_VSYS_I_Load_200mA",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mA",
          upperLimit = 70
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "PP1V83_AON_V_200mA_Load",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "PP1V83_V_200mA_Load",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = 190,
          required = true,
          subsubtestname = "Buck_1V83_Output_Current_Load_200mA",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mA",
          upperLimit = 210
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Ripple_Load_200mA",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 80,
          required = true,
          subsubtestname = "Eff_Load_200mA",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8",
          units = "%",
          upperLimit = 90
        },
        {
          required = true,
          subsubtestname = "Eload1_Disable",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_2",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_PP1V83_AON_TO_E_LOAD_1_INPUT4",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_NRF2SYS_SHDN_1KPULLDOWN",
          subtestname = "Load_200mA_1V8_AON",
          testname = "Buck_1V8"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_USBUART_EN",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan"
        },
        {
          required = true,
          subsubtestname = "I2C0_NRF_ACCEL_A51_Scan",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan"
        },
        {
          required = true,
          subsubtestname = "I2C0_NRF_ACCEL_A51_Scan_Device1",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C0_NRF_ACCEL_A51_Scan_Device2",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C1_NRF_CPS_Scan",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C2_NRF_CHGR_Scan",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C3_NRF_BMU_Scan",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C4_NRF_PDC_ULPOD_Scan",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan"
        },
        {
          required = true,
          subsubtestname = "I2C4_NRF_PDC_ULPOD_Scan_Device1",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "I2C4_NRF_PDC_ULPOD_Scan_Device2",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "ACCEL_Self_Test",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan"
        },
        {
          lowerLimit = 70,
          required = true,
          subsubtestname = "X_Self_Test",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          upperLimit = 1500
        },
        {
          lowerLimit = 70,
          required = true,
          subsubtestname = "Y_Self_Test",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          upperLimit = 1500
        },
        {
          lowerLimit = 70,
          required = true,
          subsubtestname = "Z_Self_Test",
          subtestname = "I2C_Scan",
          testname = "I2C_Device_Scan",
          upperLimit = 1500
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "PP_VSYS_I_LED_OFF",
          subtestname = "PP_VSYS_I",
          testname = "LED",
          units = "mA",
          upperLimit = 2
        },
        {
          required = true,
          subsubtestname = "LED_WHITE_ON",
          subtestname = "LED_WHITE",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "LED_WHITE",
          testname = "LED"
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "VSYS_I_LED_WHITE_ON",
          subtestname = "LED_WHITE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "DELTA_I_LED_WHITE_ON",
          subtestname = "LED_WHITE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 500,
          required = true,
          subsubtestname = "Measure_LED_WHITE_E",
          subtestname = "LED_WHITE",
          testname = "LED",
          units = "mV",
          upperLimit = 1000
        },
        {
          lowerLimit = 5,
          required = true,
          subsubtestname = "Calculate_LED_WHITE_Current",
          subtestname = "LED_WHITE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "LED_WHITE_OFF",
          subtestname = "LED_WHITE",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "LED_RED_ON",
          subtestname = "LED_RED",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "LED_RED",
          testname = "LED"
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "VSYS_I_LED_RED_ON",
          subtestname = "LED_RED",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "DELTA_I_LED_RED_ON",
          subtestname = "LED_RED",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 500,
          required = true,
          subsubtestname = "Measure_LED_RED_E",
          subtestname = "LED_RED",
          testname = "LED",
          units = "mV",
          upperLimit = 1000
        },
        {
          lowerLimit = 5,
          required = true,
          subsubtestname = "Calculate_LED_RED_Current",
          subtestname = "LED_RED",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "LED_RED_OFF",
          subtestname = "LED_RED",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "LED_GREEN_ON",
          subtestname = "LED_GREEN",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "LED_GREEN",
          testname = "LED"
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "VSYS_I_LED_GREEN_ON",
          subtestname = "LED_GREEN",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "DELTA_I_LED_GREEN_ON",
          subtestname = "LED_GREEN",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 500,
          required = true,
          subsubtestname = "Measure_LED_GREEN_E",
          subtestname = "LED_GREEN",
          testname = "LED",
          units = "mV",
          upperLimit = 1000
        },
        {
          lowerLimit = 5,
          required = true,
          subsubtestname = "Calculate_LED_GREEN_Current",
          subtestname = "LED_GREEN",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "LED_GREEN_OFF",
          subtestname = "LED_GREEN",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "LED_BLUE_ON",
          subtestname = "LED_BLUE",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "LED_BLUE",
          testname = "LED"
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "VSYS_I_LED_BLUE_ON",
          subtestname = "LED_BLUE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 3,
          required = true,
          subsubtestname = "DELTA_I_LED_BLUE_ON",
          subtestname = "LED_BLUE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          lowerLimit = 500,
          required = true,
          subsubtestname = "Measure_LED_BLUE_E",
          subtestname = "LED_BLUE",
          testname = "LED",
          units = "mV",
          upperLimit = 1000
        },
        {
          lowerLimit = 5,
          required = true,
          subsubtestname = "Calculate_LED_BLUE_Current",
          subtestname = "LED_BLUE",
          testname = "LED",
          units = "mA",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "LED_BLUE_OFF",
          subtestname = "LED_BLUE",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_5",
          subtestname = "LED_BLUE",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Config_NRF2SYS_SHDN_Output",
          subtestname = "PP5V_OFF",
          testname = "LED"
        },
        {
          lowerLimit = 2000,
          required = true,
          subsubtestname = "Measure_LED_BLUE_K_Voltage",
          subtestname = "PP5V_OFF",
          testname = "LED",
          units = "mV",
          upperLimit = 4000
        },
        {
          required = true,
          subsubtestname = "Set_NRF2SYS_SHDN_H",
          subtestname = "PP5V_OFF",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "PP5V_OFF",
          testname = "LED"
        },
        {
          lowerLimit = -10,
          required = true,
          subsubtestname = "Measure_LED_BLUE_K_Voltage_0",
          subtestname = "PP5V_OFF",
          testname = "LED",
          units = "mV",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "Set_NRF2SYS_SHDN_L",
          subtestname = "PP5V_OFF",
          testname = "LED"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_HD_CHG_ILIM_HIZ_L_TO_GND",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_SYS_RST_TO_PULSE1_IN",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Start_Pulse_Measure",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Config_FW_TRIGGERED_SYS_RST_Output",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_FW_RST_0",
          subtestname = "FW_RST",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Set_FW_TRIGGERED_SYS_RST_H",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 18,
          required = true,
          subsubtestname = "Measure_SYS_RST_PULSE_TIME",
          subtestname = "FW_RST",
          testname = "HALFDOME",
          units = "ms",
          upperLimit = 22
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "FW_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_FW_RST_0_After_RST",
          subtestname = "FW_RST",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_HD_WTD_FLG_NRF_TO_DMMCH0",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Config_WTD_FLG_Input",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_WTD_FLG",
          subtestname = "WTD_PET",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_HD_WTD_PET_L",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Delay_6500ms",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Start_Pulse_Measure",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Start_Sampling_HD_WTD_FLG_NRF",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 18,
          required = true,
          subsubtestname = "Measure_SYS_RST_PULSE_TIME",
          subtestname = "WTD_PET",
          testname = "HALFDOME",
          units = "ms",
          upperLimit = 22
        },
        {
          required = true,
          subsubtestname = "Get_WTD_FLG_Pulse_Data",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 1700,
          required = true,
          subsubtestname = "Measure_WTD_FLG",
          subtestname = "WTD_PET",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 1900
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_HD_WTD_FLG_NRF_TO_DMMCH0",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_HD_WTD_PET_H",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Config_WTD_FLG_Input_After_WTD_PET_H",
          subtestname = "WTD_PET",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_WTD_FLG_After_WTD_PET_H",
          subtestname = "WTD_PET",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_HD_WTD_DIS_H",
          subtestname = "WTD_DIS",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_HD_WTD_PET_L",
          subtestname = "WTD_DIS",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Delay_9000ms",
          subtestname = "WTD_DIS",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Check_System_Not_Reboot",
          subtestname = "WTD_DIS",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Resume_NRF_HD_WTD_PET",
          subtestname = "WTD_DIS",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_HD_WTD_DIS_L",
          subtestname = "WTD_DIS",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Drive_OVER_TEMP_COMP_OUT_H",
          subtestname = "TEMP_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_RST_WARN_NRF_INT_H",
          subtestname = "TEMP_RST",
          testname = "HALFDOME",
          units = "string"
        },
        {
          lowerLimit = -10,
          required = true,
          subsubtestname = "Measure_PP3V3_PDC",
          subtestname = "TEMP_RST",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "Delay_2500ms",
          subtestname = "TEMP_RST",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 1700,
          required = true,
          subsubtestname = "Measure_Voltage_SYS_RST",
          subtestname = "TEMP_RST",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 1950
        },
        {
          required = true,
          subsubtestname = "Drive_OVER_TEMP_COMP_OUT_L",
          subtestname = "TEMP_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_HD_CHG_ILIM_HIZ_L_TO_GND",
          subtestname = "TEMP_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Delay_3000ms",
          subtestname = "TEMP_RST",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Config_CHRG_CLR_Output",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_CHRG_CLR_H",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Pull_Up_BTN_BMU_WAKE_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 1700,
          required = true,
          subsubtestname = "Measure_Pull_Up_BTN_BMU_WAKE_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 1900
        },
        {
          required = true,
          subsubtestname = "Config_RST_WARN_NRF_INT_Input",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Config_HD_BTN_NRF_007_Input",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_RST_WARN_NRF_INT_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Read_HD_BTN_NRF_007_H",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "string"
        },
        {
          lowerLimit = -10,
          required = true,
          subsubtestname = "Measure_HD_CHG_ILIM_HIZ_L_0",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "Release_BTN_BMU_WAKE_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Pull_Down_BUTTON_CONN",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_HD_BTN_NRF_007_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Delay_2500ms",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 0,
          required = true,
          subsubtestname = "Measure_BTN_BMU_WAKE_L",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 500
        },
        {
          required = true,
          subsubtestname = "Delay_11500ms",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_PP3V3_PDC_TO_DMMCH0",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Start_Pulse_Measure",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Read_RST_WARN_NRF_INT_H",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Dmm_Sampling_PP3V3_PDC",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 18,
          required = true,
          subsubtestname = "Measure_PP3V3_PDC_Pulse_Time",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "ms",
          upperLimit = 22
        },
        {
          required = true,
          subsubtestname = "Relay_Disonnect_PP3V3_PDC_TO_DMMCH0",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 18,
          required = true,
          subsubtestname = "Measure_SYS_RST_PULSE_TIME",
          subtestname = "BTN_RST_EXIT_SHIP",
          testname = "HALFDOME",
          units = "ms",
          upperLimit = 22
        },
        {
          required = true,
          subsubtestname = "Release_BUTTON_CONN",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 1700,
          required = true,
          subsubtestname = "Measure_Voltage_HD_CHG_ILIM_HIZ_L_1",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 1950
        },
        {
          required = true,
          subsubtestname = "Config_CHRG_CLR_Output",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_CHRG_CLR_H",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Delay_100ms",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          lowerLimit = -10,
          required = true,
          subsubtestname = "Measure_Voltage_HD_CHG_ILIM_HIZ_L_0",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "Config_NRF_305_PDC_RST_Output",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          required = true,
          subsubtestname = "Set_NRF_305_PDC_RST_H",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          lowerLimit = -10,
          required = true,
          subsubtestname = "Measure_PP3V3_PDC",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME",
          units = "mV",
          upperLimit = 10
        },
        {
          required = true,
          subsubtestname = "Set_NRF_305_PDC_RST_L",
          subtestname = "ILIM_HIZ",
          testname = "HALFDOME"
        },
        {
          lowerLimit = 0.1,
          required = true,
          subsubtestname = "VBAT_I_SPKEAR_OFF",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer",
          units = "mA",
          upperLimit = 2
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP_SPK_TO_DMMCH1",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer"
        },
        {
          required = true,
          subsubtestname = "SPKEAR_ON",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer"
        },
        {
          lowerLimit = 10,
          required = true,
          subsubtestname = "VBAT_I_SPKEAR_ON",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer",
          units = "mA",
          upperLimit = 25
        },
        {
          required = true,
          subsubtestname = "Dmm_Sampling_Sine_Wave",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer"
        },
        {
          lowerLimit = 10,
          required = true,
          subsubtestname = "DELTA_I_SPKEAR_ON",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer",
          units = "mA",
          upperLimit = 25
        },
        {
          required = true,
          subsubtestname = "Analyze_Audio_Data",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer"
        },
        {
          lowerLimit = 2600,
          required = true,
          subsubtestname = "Get_Audio_Freq",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer",
          units = "Hz",
          upperLimit = 2800
        },
        {
          lowerLimit = 3200,
          required = true,
          subsubtestname = "Get_Audio_Vpp",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer",
          units = "mV",
          upperLimit = 3600
        },
        {
          required = true,
          subsubtestname = "ResetAll",
          subtestname = "SINE_2P7K_Test",
          testname = "Buzzer"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_USBUART_EN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_PP_VSYS_TO_PSU_BATTERY_POS1",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO"
        },
        {
          required = true,
          subsubtestname = "Power_On_PP_VSYS_8V",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO"
        },
        {
          required = true,
          subsubtestname = "Delay_5000ms",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO"
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P104_OH_CHG_QON_NRF_L",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P104_OL_CHG_QON_NRF_L",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P105_OH_NRF_BST_IN_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P105_OL_NRF_BST_IN_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P127_OH_NRF_VBUS_BST_EN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P127_OL_NRF_VBUS_BST_EN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P128_OH_NRF_VSYS_BST_EN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P128_OL_NRF_VSYS_BST_EN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P200_OH_NRF_ULPOD_SWDIO",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P200_OL_NRF_ULPOD_SWDIO",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P206_OH_NRF_ULPOD_SWDCLK",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P206_OL_NRF_ULPOD_SWDCLK",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P306_OH_NRF_306_ULPOD_RST",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P306_OL_NRF_306_ULPOD_RST",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P307_OH_NRF_VSYS_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P307_OL_NRF_VSYS_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P308_OH_NRF_VBST_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P308_OL_NRF_VBST_DISCHARGE",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          lowerLimit = 1750,
          required = true,
          subsubtestname = "P312_OH_NRF_312_CPS_PWRDN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 1900
        },
        {
          lowerLimit = -50,
          required = true,
          subsubtestname = "P312_OL_NRF_312_CPS_PWRDN",
          subtestname = "OUTPUT",
          testname = "NRF_GPIO",
          units = "mV",
          upperLimit = 50
        },
        {
          required = true,
          subsubtestname = "P000_IH_PDC_INT_NRF",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P000_IL_PDC_INT_NRF",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P008_IH_ULPOD_INT_NRF",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P008_IL_ULPOD_INT_NRF",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P101_IH_CPS_INT_NRF_101",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P101_IL_CPS_INT_NRF_101",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P103_IH_VSYS_BST_PG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P103_IL_VSYS_BST_PG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P116_IH_VBUS_BST_PG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P116_IL_VBUS_BST_PG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P126_IH_PDC0_PD_NEG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P126_IL_PDC0_PD_NEG_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P208_IH_CHG_CE_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P208_IL_CHG_CE_NRF_L",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P310_IH_CHG_STAT_NRF_310",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P310_IL_CHG_STAT_NRF_310",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P311_IH_CHG_INT_NRF_311",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "P311_IL_CHG_INT_NRF_311",
          subtestname = "INPUT",
          testname = "NRF_GPIO",
          units = "string"
        },
        {
          required = true,
          subsubtestname = "Detect_Diags",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_BST_NTC0_NRF_129_TO_CCS",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Enable_VBUS_ADC_NRF_106_380mV",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_1",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 370,
          required = true,
          subsubtestname = "DMM_VBUS_ADC_NRF_106_380mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 390
        },
        {
          lowerLimit = 4500,
          required = true,
          subsubtestname = "VBUS_ADC_Read_5000mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 5500
        },
        {
          required = true,
          subsubtestname = "Enable_VBUS_ADC_NRF_106_684mV",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_2",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 674,
          required = true,
          subsubtestname = "DMM_VBUS_ADC_NRF_106_684mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 694
        },
        {
          lowerLimit = 8000,
          required = true,
          subsubtestname = "VBUS_ADC_Read_9000mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 10000
        },
        {
          required = true,
          subsubtestname = "Enable_VBUS_ADC_NRF_106_1140mV",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_3",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 1130,
          required = true,
          subsubtestname = "DMM_VBUS_ADC_NRF_106_1140mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 1150
        },
        {
          lowerLimit = 14000,
          required = true,
          subsubtestname = "VBUS_ADC_Read_15000mV",
          subtestname = "VBUS",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 16000
        },
        {
          required = true,
          subsubtestname = "Disable_CCS",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Relay_Disconnect_DUT_BST_NTC0_NRF_129_TO_CCS",
          subtestname = "VBUS",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Relay_Connect_DUT_VBST_ADC_NRF_100_TO_CCS",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Enable_VBST_ADC_NRF_100_400mV",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_1",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 390,
          required = true,
          subsubtestname = "DMM_VBST_ADC_NRF_100_400mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 410
        },
        {
          lowerLimit = 6000,
          required = true,
          subsubtestname = "VBST_ADC_Read_6500mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 7000
        },
        {
          required = true,
          subsubtestname = "Enable_VBST_ADC_NRF_100_738mV",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_2",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 728,
          required = true,
          subsubtestname = "DMM_VBST_ADC_NRF_100_738mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 748
        },
        {
          lowerLimit = 11000,
          required = true,
          subsubtestname = "VBST_ADC_Read_12000mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 13000
        },
        {
          required = true,
          subsubtestname = "Enable_VBST_ADC_NRF_100_1107mV",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          required = true,
          subsubtestname = "Delay_1000ms_3",
          subtestname = "VBST",
          testname = "ADC_READ"
        },
        {
          lowerLimit = 1097,
          required = true,
          subsubtestname = "DMM_VBST_ADC_NRF_100_1107mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 1117
        },
        {
          lowerLimit = 17000,
          required = true,
          subsubtestname = "VBST_ADC_Read_18000mV",
          subtestname = "VBST",
          testname = "ADC_READ",
          units = "mV",
          upperLimit = 19000
        },
        {
          required = true,
          subsubtestname = "ResetAll",
          subtestname = "Teardown",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "delay_300ms",
          subtestname = "Teardown",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "uploadFCTInfo",
          subtestname = "Teardown",
          testname = "Fixture"
        },
        {
          required = true,
          subsubtestname = "addLogToInsight",
          subtestname = "Teardown",
          testname = "Fixture"
        }
      },
      mainActions = {
        {
          filename = "Fixture/HardwareCheck.csv",
          name = "Fixture_HardwareCheck",
          plugins = "*",
          testIdx = 1
        },
        {
          filename = "POWER_OFF/Resistance.csv",
          name = "POWER_OFF_Resistance",
          plugins = "*",
          testIdx = 2
        },
        {
          filename = "POWER_OFF/Leakage.csv",
          name = "POWER_OFF_Leakage",
          plugins = "*",
          testIdx = 3
        },
        {
          filename = "System_Info/SYS_RST_CURRENT.csv",
          name = "System_Info_SYS_RST_CURRENT",
          plugins = "*",
          testIdx = 4
        },
        {
          filename = "System_Info/SYS_POWER.csv",
          name = "System_Info_SYS_POWER",
          plugins = "*",
          testIdx = 5
        },
        {
          filename = "System_Info/SYS_Info.csv",
          name = "System_Info_SYS_Info",
          plugins = "*",
          testIdx = 6
        },
        {
          filename = "System_Info/NRF_NTC.csv",
          name = "System_Info_NRF_NTC",
          plugins = "*",
          testIdx = 7
        },
        {
          filename = "Calibration_NTC/NTC2_10C.csv",
          name = "Calibration_NTC_NTC2_10C",
          plugins = "*",
          testIdx = 8
        },
        {
          filename = "Calibration_NTC/NTC2_45C.csv",
          name = "Calibration_NTC_NTC2_45C",
          plugins = "*",
          testIdx = 9
        },
        {
          args = {
            {
              action = {
                actionIdx = 9,
                returnIdx = 1
              }
            },
            {
              action = {
                actionIdx = 9,
                returnIdx = 2
              }
            }
          },
          filename = "Calibration_NTC/NTC2_After_Cal.csv",
          name = "Calibration_NTC_NTC2_After_Cal",
          plugins = "*",
          testIdx = 10
        },
        {
          filename = "Calibration_NTC/NTC1_10C.csv",
          name = "Calibration_NTC_NTC1_10C",
          plugins = "*",
          testIdx = 11
        },
        {
          filename = "Calibration_NTC/NTC1_45C.csv",
          name = "Calibration_NTC_NTC1_45C",
          plugins = "*",
          testIdx = 12
        },
        {
          args = {
            {
              action = {
                actionIdx = 12,
                returnIdx = 1
              }
            },
            {
              action = {
                actionIdx = 12,
                returnIdx = 2
              }
            }
          },
          filename = "Calibration_NTC/NTC1_After_Cal.csv",
          name = "Calibration_NTC_NTC1_After_Cal",
          plugins = "*",
          testIdx = 13
        },
        {
          filename = "Calibration_NTC/NTC0_10C.csv",
          name = "Calibration_NTC_NTC0_10C",
          plugins = "*",
          testIdx = 14
        },
        {
          filename = "Calibration_NTC/NTC0_45C.csv",
          name = "Calibration_NTC_NTC0_45C",
          plugins = "*",
          testIdx = 15
        },
        {
          args = {
            {
              action = {
                actionIdx = 15,
                returnIdx = 1
              }
            },
            {
              action = {
                actionIdx = 15,
                returnIdx = 2
              }
            }
          },
          filename = "Calibration_NTC/NTC0_After_Cal.csv",
          name = "Calibration_NTC_NTC0_After_Cal",
          plugins = "*",
          testIdx = 16
        },
        {
          filename = "Buck_5V/No_Load.csv",
          name = "Buck_5V_No_Load",
          plugins = "*",
          testIdx = 17
        },
        {
          args = {
            {
              action = {
                actionIdx = 17,
                returnIdx = 1
              }
            }
          },
          filename = "Buck_5V/Load_200mA_PP5V_AON.csv",
          name = "Buck_5V_Load_200mA_PP5V_AON",
          plugins = "*",
          testIdx = 18
        },
        {
          filename = "Buck_3V3/No_Load.csv",
          name = "Buck_3V3_No_Load",
          plugins = "*",
          testIdx = 19
        },
        {
          args = {
            {
              action = {
                actionIdx = 19,
                returnIdx = 1
              }
            }
          },
          filename = "Buck_3V3/Load_200mA_PP3V3_PDC.csv",
          name = "Buck_3V3_Load_200mA_PP3V3_PDC",
          plugins = "*",
          testIdx = 20
        },
        {
          filename = "Buck_1V8/Load_10mA_1V8.csv",
          name = "Buck_1V8_Load_10mA_1V8",
          plugins = "*",
          testIdx = 21
        },
        {
          args = {
            {
              action = {
                actionIdx = 21,
                returnIdx = 1
              }
            }
          },
          filename = "Buck_1V8/Load_200mA_1V8_AON.csv",
          name = "Buck_1V8_Load_200mA_1V8_AON",
          plugins = "*",
          testIdx = 22
        },
        {
          filename = "I2C_Device_Scan/I2C_Scan.csv",
          name = "I2C_Device_Scan_I2C_Scan",
          plugins = "*",
          testIdx = 23
        },
        {
          filename = "LED/PP_VSYS_I.csv",
          name = "LED_PP_VSYS_I",
          plugins = "*",
          testIdx = 24
        },
        {
          args = {
            {
              action = {
                actionIdx = 24,
                returnIdx = 1
              }
            }
          },
          filename = "LED/LED_WHITE.csv",
          name = "LED_LED_WHITE",
          plugins = "*",
          testIdx = 25
        },
        {
          args = {
            {
              action = {
                actionIdx = 24,
                returnIdx = 1
              }
            }
          },
          filename = "LED/LED_RED.csv",
          name = "LED_LED_RED",
          plugins = "*",
          testIdx = 26
        },
        {
          args = {
            {
              action = {
                actionIdx = 24,
                returnIdx = 1
              }
            }
          },
          filename = "LED/LED_GREEN.csv",
          name = "LED_LED_GREEN",
          plugins = "*",
          testIdx = 27
        },
        {
          args = {
            {
              action = {
                actionIdx = 24,
                returnIdx = 1
              }
            }
          },
          filename = "LED/LED_BLUE.csv",
          name = "LED_LED_BLUE",
          plugins = "*",
          testIdx = 28
        },
        {
          filename = "LED/PP5V_OFF.csv",
          name = "LED_PP5V_OFF",
          plugins = "*",
          testIdx = 29
        },
        {
          filename = "HALFDOME/FW_RST.csv",
          name = "HALFDOME_FW_RST",
          plugins = "*",
          testIdx = 30
        },
        {
          filename = "HALFDOME/WTD_PET.csv",
          name = "HALFDOME_WTD_PET",
          plugins = "*",
          testIdx = 31
        },
        {
          filename = "HALFDOME/WTD_DIS.csv",
          name = "HALFDOME_WTD_DIS",
          plugins = "*",
          testIdx = 32
        },
        {
          filename = "HALFDOME/TEMP_RST.csv",
          name = "HALFDOME_TEMP_RST",
          plugins = "*",
          testIdx = 33
        },
        {
          filename = "HALFDOME/BTN_RST_EXIT_SHIP.csv",
          name = "HALFDOME_BTN_RST_EXIT_SHIP",
          plugins = "*",
          testIdx = 34
        },
        {
          filename = "HALFDOME/ILIM_HIZ.csv",
          name = "HALFDOME_ILIM_HIZ",
          plugins = "*",
          testIdx = 35
        },
        {
          filename = "Buzzer/SINE_2P7K_Test.csv",
          name = "Buzzer_SINE_2P7K_Test",
          plugins = "*",
          testIdx = 36
        },
        {
          filename = "NRF_GPIO/OUTPUT.csv",
          name = "NRF_GPIO_OUTPUT",
          plugins = "*",
          testIdx = 37
        },
        {
          filename = "NRF_GPIO/INPUT.csv",
          name = "NRF_GPIO_INPUT",
          plugins = "*",
          testIdx = 38
        },
        {
          filename = "ADC_READ/VBUS.csv",
          name = "ADC_READ_VBUS",
          plugins = "*",
          testIdx = 39
        },
        {
          filename = "ADC_READ/VBST.csv",
          name = "ADC_READ_VBST",
          plugins = "*",
          testIdx = 40
        }
      },
      mainTests = {
        {
          Conditions = "",
          Coverage = "HardwareCheck",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "Fixture",
          TestParameters = "",
          actions = {
            1
          },
          fullName = "Fixture HardwareCheck",
          outputs = {
            FIXTUREID = {
              actionIdx = 1,
              actionName = "Fixture_HardwareCheck",
              returnIdx = 1
            },
            MIXFWPACKAGE = {
              actionIdx = 1,
              actionName = "Fixture_HardwareCheck",
              returnIdx = 2
            },
            SLOTID = {
              actionIdx = 1,
              actionName = "Fixture_HardwareCheck",
              returnIdx = 3
            },
            StationName = {
              actionIdx = 1,
              actionName = "Fixture_HardwareCheck",
              returnIdx = 4
            },
            VENDORID = {
              actionIdx = 1,
              actionName = "Fixture_HardwareCheck",
              returnIdx = 5
            }
          },
          subTestName = "HardwareCheck",
          testName = "Fixture"
        },
        {
          Conditions = "",
          Coverage = "Resistance",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "POWER_OFF",
          TestParameters = "",
          actions = {
            2
          },
          deps = {
            1
          },
          fullName = "POWER_OFF Resistance",
          outputs = {
          },
          subTestName = "Resistance",
          testName = "POWER_OFF"
        },
        {
          Conditions = "",
          Coverage = "Leakage",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "POWER_OFF",
          TestParameters = "",
          actions = {
            3
          },
          deps = {
            2
          },
          fullName = "POWER_OFF Leakage",
          outputs = {
          },
          subTestName = "Leakage",
          testName = "POWER_OFF"
        },
        {
          Conditions = "",
          Coverage = "SYS_RST_CURRENT",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "System_Info",
          TestParameters = "",
          actions = {
            4
          },
          deps = {
            3
          },
          fullName = "System_Info SYS_RST_CURRENT",
          outputs = {
          },
          subTestName = "SYS_RST_CURRENT",
          testName = "System_Info"
        },
        {
          Conditions = "",
          Coverage = "SYS_POWER",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "System_Info",
          TestParameters = "",
          actions = {
            5
          },
          deps = {
            4
          },
          fullName = "System_Info SYS_POWER",
          outputs = {
          },
          subTestName = "SYS_POWER",
          testName = "System_Info"
        },
        {
          Conditions = "",
          Coverage = "SYS_Info",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "System_Info",
          TestParameters = "",
          actions = {
            6
          },
          deps = {
            5
          },
          fullName = "System_Info SYS_Info",
          outputs = {
            MLBSN = {
              actionIdx = 6,
              actionName = "System_Info_SYS_Info",
              returnIdx = 1
            }
          },
          subTestName = "SYS_Info",
          testName = "System_Info"
        },
        {
          Conditions = "",
          Coverage = "NRF_NTC",
          SamplingGroup = "",
          Technology = "System_Info",
          TestParameters = "",
          actions = {
            7
          },
          deps = {
            6
          },
          fullName = "System_Info NRF_NTC",
          outputs = {
          },
          subTestName = "NRF_NTC",
          testName = "System_Info"
        },
        {
          Conditions = "",
          Coverage = "NTC2_10C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            8
          },
          deps = {
            7
          },
          fullName = "Calibration_NTC NTC2_10C",
          outputs = {
            DUT_NTC2 = {
              actionIdx = 8,
              actionName = "Calibration_NTC_NTC2_10C",
              returnIdx = 1
            },
            Fixture_NTC2 = {
              actionIdx = 8,
              actionName = "Calibration_NTC_NTC2_10C",
              returnIdx = 2
            },
            NTC2_VOLT = {
              actionIdx = 8,
              actionName = "Calibration_NTC_NTC2_10C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 8,
              actionName = "Calibration_NTC_NTC2_10C",
              returnIdx = 4
            },
            Tmp_Offset_NTC2 = {
              actionIdx = 8,
              actionName = "Calibration_NTC_NTC2_10C",
              returnIdx = 5
            }
          },
          subTestName = "NTC2_10C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC2_45C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            9
          },
          deps = {
            8
          },
          fullName = "Calibration_NTC NTC2_45C",
          outputs = {
            DUT_NTC2 = {
              actionIdx = 9,
              actionName = "Calibration_NTC_NTC2_45C",
              returnIdx = 1
            },
            Fixture_NTC2 = {
              actionIdx = 9,
              actionName = "Calibration_NTC_NTC2_45C",
              returnIdx = 2
            },
            NTC2_VOLT = {
              actionIdx = 9,
              actionName = "Calibration_NTC_NTC2_45C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 9,
              actionName = "Calibration_NTC_NTC2_45C",
              returnIdx = 4
            }
          },
          subTestName = "NTC2_45C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC2_After_Cal",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            10
          },
          deps = {
            9
          },
          fullName = "Calibration_NTC NTC2_After_Cal",
          outputs = {
            Tmp_Offset_NTC2 = {
              actionIdx = 10,
              actionName = "Calibration_NTC_NTC2_After_Cal",
              returnIdx = 1
            },
            Tmp_Offset_NTC2_Hex = {
              actionIdx = 10,
              actionName = "Calibration_NTC_NTC2_After_Cal",
              returnIdx = 2
            },
            Tmp_Offset_NTC2_Read = {
              actionIdx = 10,
              actionName = "Calibration_NTC_NTC2_After_Cal",
              returnIdx = 3
            }
          },
          subTestName = "NTC2_After_Cal",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC1_10C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            11
          },
          deps = {
            10
          },
          fullName = "Calibration_NTC NTC1_10C",
          outputs = {
            DUT_NTC1 = {
              actionIdx = 11,
              actionName = "Calibration_NTC_NTC1_10C",
              returnIdx = 1
            },
            Fixture_NTC1 = {
              actionIdx = 11,
              actionName = "Calibration_NTC_NTC1_10C",
              returnIdx = 2
            },
            NTC1_VOLT = {
              actionIdx = 11,
              actionName = "Calibration_NTC_NTC1_10C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 11,
              actionName = "Calibration_NTC_NTC1_10C",
              returnIdx = 4
            },
            Tmp_Offset_NTC1 = {
              actionIdx = 11,
              actionName = "Calibration_NTC_NTC1_10C",
              returnIdx = 5
            }
          },
          subTestName = "NTC1_10C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC1_45C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            12
          },
          deps = {
            11
          },
          fullName = "Calibration_NTC NTC1_45C",
          outputs = {
            DUT_NTC1 = {
              actionIdx = 12,
              actionName = "Calibration_NTC_NTC1_45C",
              returnIdx = 1
            },
            Fixture_NTC1 = {
              actionIdx = 12,
              actionName = "Calibration_NTC_NTC1_45C",
              returnIdx = 2
            },
            NTC1_VOLT = {
              actionIdx = 12,
              actionName = "Calibration_NTC_NTC1_45C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 12,
              actionName = "Calibration_NTC_NTC1_45C",
              returnIdx = 4
            }
          },
          subTestName = "NTC1_45C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC1_After_Cal",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            13
          },
          deps = {
            12
          },
          fullName = "Calibration_NTC NTC1_After_Cal",
          outputs = {
            Tmp_Offset_NTC1 = {
              actionIdx = 13,
              actionName = "Calibration_NTC_NTC1_After_Cal",
              returnIdx = 1
            },
            Tmp_Offset_NTC1_Hex = {
              actionIdx = 13,
              actionName = "Calibration_NTC_NTC1_After_Cal",
              returnIdx = 2
            },
            Tmp_Offset_NTC1_Read = {
              actionIdx = 13,
              actionName = "Calibration_NTC_NTC1_After_Cal",
              returnIdx = 3
            }
          },
          subTestName = "NTC1_After_Cal",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC0_10C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            14
          },
          deps = {
            13
          },
          fullName = "Calibration_NTC NTC0_10C",
          outputs = {
            DUT_NTC0 = {
              actionIdx = 14,
              actionName = "Calibration_NTC_NTC0_10C",
              returnIdx = 1
            },
            Fixture_NTC0 = {
              actionIdx = 14,
              actionName = "Calibration_NTC_NTC0_10C",
              returnIdx = 2
            },
            NTC0_VOLT = {
              actionIdx = 14,
              actionName = "Calibration_NTC_NTC0_10C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 14,
              actionName = "Calibration_NTC_NTC0_10C",
              returnIdx = 4
            },
            Tmp_Offset_NTC0 = {
              actionIdx = 14,
              actionName = "Calibration_NTC_NTC0_10C",
              returnIdx = 5
            }
          },
          subTestName = "NTC0_10C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC0_45C",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            15
          },
          deps = {
            14
          },
          fullName = "Calibration_NTC NTC0_45C",
          outputs = {
            DUT_NTC0 = {
              actionIdx = 15,
              actionName = "Calibration_NTC_NTC0_45C",
              returnIdx = 1
            },
            Fixture_NTC0 = {
              actionIdx = 15,
              actionName = "Calibration_NTC_NTC0_45C",
              returnIdx = 2
            },
            NTC0_VOLT = {
              actionIdx = 15,
              actionName = "Calibration_NTC_NTC0_45C",
              returnIdx = 3
            },
            PP1V83 = {
              actionIdx = 15,
              actionName = "Calibration_NTC_NTC0_45C",
              returnIdx = 4
            }
          },
          subTestName = "NTC0_45C",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "NTC0_After_Cal",
          SamplingGroup = "",
          Technology = "Calibration_NTC",
          TestParameters = "",
          actions = {
            16
          },
          deps = {
            15
          },
          fullName = "Calibration_NTC NTC0_After_Cal",
          outputs = {
            Tmp_Offset_NTC0 = {
              actionIdx = 16,
              actionName = "Calibration_NTC_NTC0_After_Cal",
              returnIdx = 1
            },
            Tmp_Offset_NTC0_Hex = {
              actionIdx = 16,
              actionName = "Calibration_NTC_NTC0_After_Cal",
              returnIdx = 2
            },
            Tmp_Offset_NTC0_Read = {
              actionIdx = 16,
              actionName = "Calibration_NTC_NTC0_After_Cal",
              returnIdx = 3
            }
          },
          subTestName = "NTC0_After_Cal",
          testName = "Calibration_NTC"
        },
        {
          Conditions = "",
          Coverage = "No_Load",
          SamplingGroup = "",
          Technology = "Buck_5V",
          TestParameters = "",
          actions = {
            17
          },
          deps = {
            16
          },
          fullName = "Buck_5V No_Load",
          outputs = {
            PP_VSYS_I_No_Load = {
              actionIdx = 17,
              actionName = "Buck_5V_No_Load",
              returnIdx = 1
            }
          },
          subTestName = "No_Load",
          testName = "Buck_5V"
        },
        {
          Conditions = "",
          Coverage = "Load_200mA_PP5V_AON",
          SamplingGroup = "",
          Technology = "Buck_5V",
          TestParameters = "",
          actions = {
            18
          },
          deps = {
            17
          },
          fullName = "Buck_5V Load_200mA_PP5V_AON",
          outputs = {
            Buck_5V_Output_Current = {
              actionIdx = 18,
              actionName = "Buck_5V_Load_200mA_PP5V_AON",
              returnIdx = 1
            },
            PP5V_AON_V_Load_200mA = {
              actionIdx = 18,
              actionName = "Buck_5V_Load_200mA_PP5V_AON",
              returnIdx = 2
            },
            VSYS_I_Load_200mA = {
              actionIdx = 18,
              actionName = "Buck_5V_Load_200mA_PP5V_AON",
              returnIdx = 3
            },
            VSYS_V_Load_200mA = {
              actionIdx = 18,
              actionName = "Buck_5V_Load_200mA_PP5V_AON",
              returnIdx = 4
            }
          },
          subTestName = "Load_200mA_PP5V_AON",
          testName = "Buck_5V"
        },
        {
          Conditions = "",
          Coverage = "No_Load",
          SamplingGroup = "",
          Technology = "Buck_3V3",
          TestParameters = "",
          actions = {
            19
          },
          deps = {
            18
          },
          fullName = "Buck_3V3 No_Load",
          outputs = {
            PP_VSYS_I_No_Load_3V3 = {
              actionIdx = 19,
              actionName = "Buck_3V3_No_Load",
              returnIdx = 1
            }
          },
          subTestName = "No_Load",
          testName = "Buck_3V3"
        },
        {
          Conditions = "",
          Coverage = "Load_200mA_PP3V3_PDC",
          SamplingGroup = "",
          Technology = "Buck_3V3",
          TestParameters = "",
          actions = {
            20
          },
          deps = {
            19
          },
          fullName = "Buck_3V3 Load_200mA_PP3V3_PDC",
          outputs = {
            Buck_3V3_Output_Current_3V3 = {
              actionIdx = 20,
              actionName = "Buck_3V3_Load_200mA_PP3V3_PDC",
              returnIdx = 1
            },
            PP3V3_AON_V_Load_200mA_3V3 = {
              actionIdx = 20,
              actionName = "Buck_3V3_Load_200mA_PP3V3_PDC",
              returnIdx = 2
            },
            VSYS_I_Load_200mA_3V3 = {
              actionIdx = 20,
              actionName = "Buck_3V3_Load_200mA_PP3V3_PDC",
              returnIdx = 3
            },
            VSYS_V_Load_200mA_3V3 = {
              actionIdx = 20,
              actionName = "Buck_3V3_Load_200mA_PP3V3_PDC",
              returnIdx = 4
            }
          },
          subTestName = "Load_200mA_PP3V3_PDC",
          testName = "Buck_3V3"
        },
        {
          Conditions = "",
          Coverage = "Load_10mA_1V8",
          SamplingGroup = "",
          Technology = "Buck_1V8",
          TestParameters = "",
          actions = {
            21
          },
          deps = {
            20
          },
          fullName = "Buck_1V8 Load_10mA_1V8",
          outputs = {
            PP_VSYS_I_No_Load_1V8 = {
              actionIdx = 21,
              actionName = "Buck_1V8_Load_10mA_1V8",
              returnIdx = 1
            }
          },
          subTestName = "Load_10mA_1V8",
          testName = "Buck_1V8"
        },
        {
          Conditions = "",
          Coverage = "Load_200mA_1V8_AON",
          SamplingGroup = "",
          Technology = "Buck_1V8",
          TestParameters = "",
          actions = {
            22
          },
          deps = {
            21
          },
          fullName = "Buck_1V8 Load_200mA_1V8_AON",
          outputs = {
            Buck_1V8_Output_Current = {
              actionIdx = 22,
              actionName = "Buck_1V8_Load_200mA_1V8_AON",
              returnIdx = 1
            },
            PP1V8_V_Load_200mA = {
              actionIdx = 22,
              actionName = "Buck_1V8_Load_200mA_1V8_AON",
              returnIdx = 2
            },
            VSYS_I_Load_200mA_1V8 = {
              actionIdx = 22,
              actionName = "Buck_1V8_Load_200mA_1V8_AON",
              returnIdx = 3
            },
            VSYS_V_Load_200mA_1V8 = {
              actionIdx = 22,
              actionName = "Buck_1V8_Load_200mA_1V8_AON",
              returnIdx = 4
            }
          },
          subTestName = "Load_200mA_1V8_AON",
          testName = "Buck_1V8"
        },
        {
          Conditions = "",
          Coverage = "I2C_Scan",
          SamplingGroup = "",
          StopOnFail = true,
          Technology = "I2C_Device_Scan",
          TestParameters = "",
          actions = {
            23
          },
          deps = {
            22
          },
          fullName = "I2C_Device_Scan I2C_Scan",
          outputs = {
            ACCEL_Data = {
              actionIdx = 23,
              actionName = "I2C_Device_Scan_I2C_Scan",
              returnIdx = 1
            },
            diags_output = {
              actionIdx = 23,
              actionName = "I2C_Device_Scan_I2C_Scan",
              returnIdx = 2
            }
          },
          subTestName = "I2C_Scan",
          testName = "I2C_Device_Scan"
        },
        {
          Conditions = "",
          Coverage = "PP_VSYS_I",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            24
          },
          deps = {
            23
          },
          fullName = "LED PP_VSYS_I",
          outputs = {
            PP_VSYS_I_No_Load_LED = {
              actionIdx = 24,
              actionName = "LED_PP_VSYS_I",
              returnIdx = 1
            }
          },
          subTestName = "PP_VSYS_I",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "LED_WHITE",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            25
          },
          deps = {
            24
          },
          fullName = "LED LED_WHITE",
          outputs = {
            VBAT_I_LED_WHITE_ON = {
              actionIdx = 25,
              actionName = "LED_LED_WHITE",
              returnIdx = 1
            },
            White_E = {
              actionIdx = 25,
              actionName = "LED_LED_WHITE",
              returnIdx = 2
            }
          },
          subTestName = "LED_WHITE",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "LED_RED",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            26
          },
          deps = {
            24,
            25
          },
          fullName = "LED LED_RED",
          outputs = {
            Red_E = {
              actionIdx = 26,
              actionName = "LED_LED_RED",
              returnIdx = 1
            },
            VBAT_I_LED_RED_ON = {
              actionIdx = 26,
              actionName = "LED_LED_RED",
              returnIdx = 2
            }
          },
          subTestName = "LED_RED",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "LED_GREEN",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            27
          },
          deps = {
            24,
            26
          },
          fullName = "LED LED_GREEN",
          outputs = {
            Green_E = {
              actionIdx = 27,
              actionName = "LED_LED_GREEN",
              returnIdx = 1
            },
            VBAT_I_LED_GREEN_ON = {
              actionIdx = 27,
              actionName = "LED_LED_GREEN",
              returnIdx = 2
            }
          },
          subTestName = "LED_GREEN",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "LED_BLUE",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            28
          },
          deps = {
            24,
            27
          },
          fullName = "LED LED_BLUE",
          outputs = {
            Blue_E = {
              actionIdx = 28,
              actionName = "LED_LED_BLUE",
              returnIdx = 1
            },
            VBAT_I_LED_BLUE_ON = {
              actionIdx = 28,
              actionName = "LED_LED_BLUE",
              returnIdx = 2
            }
          },
          subTestName = "LED_BLUE",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "PP5V_OFF",
          SamplingGroup = "",
          Technology = "LED",
          TestParameters = "",
          actions = {
            29
          },
          deps = {
            28
          },
          fullName = "LED PP5V_OFF",
          outputs = {
          },
          subTestName = "PP5V_OFF",
          testName = "LED"
        },
        {
          Conditions = "",
          Coverage = "FW_RST",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            30
          },
          deps = {
            29
          },
          fullName = "HALFDOME FW_RST",
          outputs = {
          },
          subTestName = "FW_RST",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "WTD_PET",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            31
          },
          deps = {
            30
          },
          fullName = "HALFDOME WTD_PET",
          outputs = {
            WTD_FLG_Path = {
              actionIdx = 31,
              actionName = "HALFDOME_WTD_PET",
              returnIdx = 1
            }
          },
          subTestName = "WTD_PET",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "WTD_DIS",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            32
          },
          deps = {
            31
          },
          fullName = "HALFDOME WTD_DIS",
          outputs = {
          },
          subTestName = "WTD_DIS",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "TEMP_RST",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            33
          },
          deps = {
            32
          },
          fullName = "HALFDOME TEMP_RST",
          outputs = {
          },
          subTestName = "TEMP_RST",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "BTN_RST_EXIT_SHIP",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            34
          },
          deps = {
            33
          },
          fullName = "HALFDOME BTN_RST_EXIT_SHIP",
          outputs = {
            PDC_File = {
              actionIdx = 34,
              actionName = "HALFDOME_BTN_RST_EXIT_SHIP",
              returnIdx = 1
            }
          },
          subTestName = "BTN_RST_EXIT_SHIP",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "ILIM_HIZ",
          SamplingGroup = "",
          Technology = "HALFDOME",
          TestParameters = "",
          actions = {
            35
          },
          deps = {
            34
          },
          fullName = "HALFDOME ILIM_HIZ",
          outputs = {
          },
          subTestName = "ILIM_HIZ",
          testName = "HALFDOME"
        },
        {
          Conditions = "",
          Coverage = "SINE_2P7K_Test",
          SamplingGroup = "",
          Technology = "Buzzer",
          TestParameters = "",
          actions = {
            36
          },
          deps = {
            35
          },
          fullName = "Buzzer SINE_2P7K_Test",
          outputs = {
            PATH = {
              actionIdx = 36,
              actionName = "Buzzer_SINE_2P7K_Test",
              returnIdx = 1
            },
            VBAT_I_SPKEAR_OFF = {
              actionIdx = 36,
              actionName = "Buzzer_SINE_2P7K_Test",
              returnIdx = 2
            },
            VBAT_I_SPKEAR_ON = {
              actionIdx = 36,
              actionName = "Buzzer_SINE_2P7K_Test",
              returnIdx = 3
            },
            retTable = {
              actionIdx = 36,
              actionName = "Buzzer_SINE_2P7K_Test",
              returnIdx = 4
            }
          },
          subTestName = "SINE_2P7K_Test",
          testName = "Buzzer"
        },
        {
          Conditions = "",
          Coverage = "OUTPUT",
          SamplingGroup = "",
          Technology = "NRF_GPIO",
          TestParameters = "",
          actions = {
            37
          },
          deps = {
            36
          },
          fullName = "NRF_GPIO OUTPUT",
          outputs = {
          },
          subTestName = "OUTPUT",
          testName = "NRF_GPIO"
        },
        {
          Conditions = "",
          Coverage = "INPUT",
          SamplingGroup = "",
          Technology = "NRF_GPIO",
          TestParameters = "",
          actions = {
            38
          },
          deps = {
            37
          },
          fullName = "NRF_GPIO INPUT",
          outputs = {
          },
          subTestName = "INPUT",
          testName = "NRF_GPIO"
        },
        {
          Conditions = "",
          Coverage = "VBUS",
          SamplingGroup = "",
          Technology = "ADC_READ",
          TestParameters = "",
          actions = {
            39
          },
          deps = {
            38
          },
          fullName = "ADC_READ VBUS",
          outputs = {
          },
          subTestName = "VBUS",
          testName = "ADC_READ"
        },
        {
          Conditions = "",
          Coverage = "VBST",
          SamplingGroup = "",
          Technology = "ADC_READ",
          TestParameters = "",
          actions = {
            40
          },
          deps = {
            39
          },
          fullName = "ADC_READ VBST",
          outputs = {
          },
          subTestName = "VBST",
          testName = "ADC_READ"
        }
      },
      samplings = {
      },
      teardownActions = {
        {
          dataQuery = true,
          name = "data",
          testIdx = 1
        },
        {
          args = {
            {
              action = {
                actionIdx = 1,
                returnIdx = 4
              }
            }
          },
          filename = "Fixture/Teardown.csv",
          name = "Fixture_Teardown",
          plugins = "*",
          testIdx = 1
        }
      },
      teardownTests = {
        {
          Conditions = "",
          Coverage = "Teardown",
          SamplingGroup = "",
          Technology = "Fixture",
          TestParameters = "",
          actions = {
            1,
            2
          },
          fullName = "Fixture Teardown",
          outputs = {
          },
          subTestName = "Teardown",
          testName = "Fixture"
        }
      },
      testPlanAttribute = {
        limitsHasConditions = false,
        requireConditionValidator = false
      }
    }
  }
}