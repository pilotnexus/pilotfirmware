#
# cpld.qsf auto-generated quartus file for RasPiComm+
#

set_global_assignment -name FAMILY "MAX V"
set_global_assignment -name DEVICE 5M80ZT100C5
set_global_assignment -name TOP_LEVEL_ENTITY top
set_global_assignment -name ORIGINAL_QUARTUS_VERSION "15.1"
set_global_assignment -name PROJECT_CREATION_TIME_DATE "17:24:54  APRIL 24, 2013"
set_global_assignment -name LAST_QUARTUS_VERSION "15.1"
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name DEVICE_FILTER_PIN_COUNT 100
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR "-1"
set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "3.3-V LVTTL"
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "NO HEAT SINK WITH STILL AIR"
set_global_assignment -name USE_CONFIGURATION_DEVICE ON
set_global_assignment -name GENERATE_JAM_FILE ON

# verilog modules
<verilogfiles:{file|set_global_assignment -name VERILOG_FILE <file>};separator="\n">

<! 
set_global_assignment -name VERILOG_FILE can_module.v
set_global_assignment -name VERILOG_FILE rs485_2_module.v
set_global_assignment -name VERILOG_FILE io3_module.v
set_global_assignment -name VERILOG_FILE rpi_module.v
set_global_assignment -name VERILOG_FILE top.v
set_global_assignment -name VERILOG_FILE wiring.v
set_global_assignment -name VERILOG_FILE io16_module.v
!>

set_global_assignment -name RESERVE_ALL_UNUSED_PINS "as input tri-stated"
