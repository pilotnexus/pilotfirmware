/* 
    this file contains defines that are shared between the rpi drivers and the microcontroller
*/

#ifndef RPC_COMMON_BASE_H
#define RPC_COMMON_BASE_H

#include <stdint.h>

/* the number of modules that are available in the  */
#define MODULES_COUNT 4

/* the number of ports for each module */
#define MODULE_PORT_COUNT 2

/* command message payload calc macro */
#define MSG_LEN(x) (0x7F & (x >> 2))

/* we're using byte-wise SPI communication */
typedef uint8_t spidata_t;

/* stm commands */
typedef enum
{
  rpcp_cmd_type_invalid = 0,
  rpcp_cmd_type_eeprom_uid_get,             /* rpi <->  request to send the eeprom uid of the specified module */
  rpcp_cmd_type_eeprom_hid_get,             /* rpi <->  request to send the eeprom hid of the specified module */
  rpcp_cmd_type_eeprom_hid_set,             /* rpi <->  command to set the eeprom hid of the specified module */
  rpcp_cmd_type_eeprom_fid_get,             /* rpi <->  request to get the eeprom fid of the specified module */
  rpcp_cmd_type_eeprom_fid_set,             /* rpi ->  command to set the eeprom fid of the specified module */
  rpcp_cmd_type_usart_set_baudrate,         /* rpi ->  command to set the baudrate of the specified usart */
  rpcp_cmd_type_usart_set_stopbits,         /* rpi ->  command to set the stopbits of the specified usart */
  rpcp_cmd_type_usart_set_wordlength,       /* rpi ->  command to set the wordlength of the specified usart */
  rpcp_cmd_type_usart_set_parity,           /* rpi ->  command to set the parity of the specified usart */
  rpcp_cmd_type_usart_send_break,           /* rpi ->  command to send a break on the specified usart */
  rpcp_cmd_type_input_get_input,            /* rpi <->  request to send back the state of the input */
  rpcp_cmd_type_rtc_get,                    /* rpi <->  messages to request and send the datetime of the rtc */
  rpcp_cmd_type_rtc_set,                    /* rpi ->  command to set the rtc */
  rpcp_cmd_type_bufferstate,                /* rpi <-  message to inform the rpi of the current bufferstate */
  rpcp_cmd_type_input_get_counter,          /* rpi <->  request to send the value of the counter */
  rpcp_cmd_type_input_set_counter,          /* rpi ->  command to set the value of the counter */
  rpcp_cmd_type_gps_set_enable,             /* rpi ->  command to enable / disable the gps */
  rpcp_cmd_type_gps_get_enable,             /* rpi <->  request to send the enabled state of the gps module */
  rpcp_cmd_type_io16_set_direction,         /* rpi ->  command to set direction of io block */
  rpcp_cmd_type_output_set_value,           /* rpi ->  command to set output value */
  rpcp_cmd_type_input_changed,              /* rpi <-  command that informs the rpi that an input changed */
  rpcp_cmd_type_onewire_set_enable,         /* rpi ->  command to enable / disable 1-wire */
  rpcp_cmd_type_onewire_get_enable,         /* rpi <->  request to send the enabled state of the 1-wire module */
  rpcp_cmd_type_gsm_set_enable,             /* rpi <->  command to enable / disable the gsm */
  rpcp_cmd_type_gsm_get_enable,             /* rpi <->  request to send the enabled state of the gsm module */
  rpcp_cmd_type_module_type_get,            /* rpi <->  request to send the module type that the firmware was built for */
  rpcp_cmd_type_slcd_udpate,                /* rpi ->  command that signals the start of an update stream */
  rpcp_cmd_type_slcd_set_resolution,        /* rpi ->  command to set the display resolution */
  rpcp_cmd_type_slcd_get_resolution,        /* rpi <->  request to send the display resolution */
  rpcp_cmd_type_eeprom_userdata_get,        /* rpi <->  request to send custom user data from the eeprom */
  rpcp_cmd_type_eeprom_userdata_set,        /* rpi ->  request to write custom user data to the eeprom */
  rpcp_cmd_type_plc_state_get,              /* rpi <->  request to send the state of the plc */
  rpcp_cmd_type_plc_state_set,              /* rpi ->  command to set the state of the plc */
  rpcp_cmd_type_plc_cycletimes_get,         /* rpi <->  request to send the plc cycle times */
  rpcp_cmd_type_plc_variables_read_config,  /* rpi ->  command to notify the  that the plc variable config stream will be send */
  rpcp_cmd_type_plc_variables_write_config, /* rpi <->  request to send the configured plc variables */
  rpcp_cmd_type_plc_variables_get,          /* rpi <->  request to send the configured plc variables */
  rpcp_cmd_type_plc_variables_set,          /* rpi ->  comand to write the configure plc variables */
  rpcp_cmd_type_lora_set_enable,            /* rpi ->  command to enable / disable lora module */
  rpcp_cmd_type_lora_get_enable,            /* rpi <->  request to send the enabled state of the lora module */
  rpcp_cmd_type_test_run,                   /* rpi <->  request to run internal tests */
  rpcp_cmd_type_plc_variable_get,           /* rpi <-> get plc variable */
  rpcp_cmd_type_plc_variable_set,           /* rpi <-> set plc variable */
  rpcp_cmd_type_fpga_state,                 /* rpi <-> fpga state */
  rpcp_cmd_type_fpga_cmd,                   /* rpi <-> fpga write data */
  rpcp_cmd_type_comm_stats_get,             /* rpi <-> get communication stats */
  rpcp_cmd_type_fwinfo                      /* rpi <-> get fw info */
} rpcp_cmd_type_t;

/* module types */
typedef enum {
  module_type_t_Invalid = -1,
  module_type_t_I8,
  module_type_t_O8,
  module_type_t_IO16,
  module_type_t_GSM,
  module_type_t_CAN,
  module_type_t_CAN_2PORTS,
  module_type_t_RS485,
  module_type_t_RS485_2PORTS,
  module_type_t_RS232,
  module_type_t_ONEWIRE,
  module_type_t_ONEWIRE_2PORTS
} module_type_t;

/* enum that specifies the target of the communication 
   target_t is a combination of module_slot_t and module_port_t */
typedef enum
{
  target_invalid       = 0x00, /* there is no valid target, the following data should be discarded */

  target_module1_port1 = 0x01, /* the target is the first port of the Module in the slot 1  */
  target_module1_port2 = 0x02, /* the target is the second port of the Module in the slot 1 */

  target_module2_port1 = 0x03, /* the target is the first port of the Module in the slot 2  */
  target_module2_port2 = 0x04, /* the target is the second port of the Module in the slot 2 */

  target_module3_port1 = 0x05, /* the target is the first port of the Module in the slot 3  */
  target_module3_port2 = 0x06, /* the target is the second port of the Module in the slot 3 */

  target_module4_port1 = 0x07, /* the target is the first port of the Module in the slot 4  */
  target_module4_port2 = 0x08, /* the target is the second port of the Module in the slot 4 */

  target_plc_read      = 0x60, /* the target is the soft plc read */
  target_plc_write     = 0x61, /* the target is the soft plc write */

  target_base          = 0x70,
  target_base_type     = 0x71,
  target_base_length   = 0x72,
  target_base_reserved = 0x73,
  target_base_crc      = 0x74,
  target_base_data     = 0x75

} target_t;

#define rpcp_cmd_t_data_size 512
#define rpcp_cmd_t_size_without_data 8

/* rpi command struct */
typedef struct {
  char target;                      /* target of the command */
  char type;                        /* type of the command */
  unsigned char length;             /* data block length */
  unsigned char reserved;           /* reserved */
  char data[rpcp_cmd_t_data_size];  /* command data, value depends on type */
  uint32_t crc;                     /* CRC32 checksum */
} rpcp_cmd_t;

typedef enum {
  rpcp_current_cmd_index_target     = 0,
  rpcp_current_cmd_index_type       = 1,
  rpcp_current_cmd_index_length     = 2,
  pilot_current_cmd_index_data_begin = 4
} rpcp_current_cmd_index_t;

/* struct that holds the current rpcp command that is being received */
typedef struct {
  rpcp_cmd_t cmd;                 /* the command we're receiving from the rpi */
  uint32_t index; /* current index of the fillstatus of this command */
  uint32_t length;
  uint8_t cmd_completion;
} rpcp_current_cmd_t;

/* specifies the slot of the module */
typedef enum
{
  module_slot_1 = 0,
  module_slot_2 = 1,
  module_slot_3 = 2,
  module_slot_4 = 3
} module_slot_t;

/* specifies the port, every module has 2 possible ports */
typedef enum
{
  module_port_1 = 0,
  module_port_2 = 1
} module_port_t;

/* macros for creating target_t and converting module_slot_t and module_port_t to target_t */

#define target_t_get_module_slot(target) ((module_slot_t)((target-1)/2))
#define target_t_get_module_port(target) ((module_port_t)((target-1)%2))
#define target_t_from_module_slot_and_port(module,port) ((target_t)(((int)module)*2+1+(int)port))

#define eeprom_encode_module_slot_and_data_index(module_slot,data_index) ((module_slot << 4) | (data_index))
#define eeprom_decode_module_slot(data) (data >> 4)
#define eeprom_decode_data_index(data) (data & 0xF)

typedef enum
{
  stm_bufferstate_not_full,
  stm_bufferstate_full
} stm_bufferstate_t;

/* 
    hours..........0-23
    minutes........0-59
    seconds........0-59
    weekday........1-7
    day of month...1-31
    month..........1-12
    year...........0-99  (2000-2099) */
typedef enum {
  rpcp_rtc_index_hours      = 0,
  rpcp_rtc_index_minutes    = 1,
  rpcp_rtc_index_seconds    = 2,
  rpcp_rtc_index_weekday    = 3,
  rpcp_rtc_index_dayofmonth = 4,
  rpcp_rtc_index_month      = 5,
  rpcp_rtc_index_year       = 6
} rpcp_rtc_index_t;

/* specifies the targetted counter, used as first data byte in rpcp_cmd_type_input_get_counter */
typedef enum {
  rpcp_counter_target_1   = 0,
  rpcp_counter_target_2   = 1,
  rpcp_counter_target_3   = 2,
  rpcp_counter_target_4   = 3,
  rpcp_counter_target_5   = 4,
  rpcp_counter_target_6   = 5,
  rpcp_counter_target_7   = 6,
  rpcp_counter_target_8   = 7,
  rpcp_counter_target_all = 0xff
} rpcp_counter_target_t;

/* helper enum that for rpcp_cmd_type_input_counter_X handling */
typedef enum {
  rpcp_counter_index_target = 0, /* encode the counters target in the first byte */
  rpcp_counter_index_value  = 1  /* encode the counter value in the last 7 bytes */
} rpcp_counter_index_t;

/* specifies the targetted input, used as first data byte in rpcp_cmd_type_input_get_input */
typedef enum {
  rpcp_input_target_1 = 0,
  rpcp_input_target_2 = 1,
  rpcp_input_target_3 = 2,
  rpcp_input_target_4 = 3,
  rpcp_input_target_5 = 4,
  rpcp_input_target_6 = 5,
  rpcp_input_target_7 = 6,
  rpcp_input_target_8 = 7
} rpcp_input_target_t;

/* helper enum for rpcp_cmd_type_input_get_input handling */
typedef enum {
  rpcp_input_index_target = 0, /* encode the input target in the first byte */
  rpcp_input_index_value  = 4  /* encode the input value in the last 4 bytes */
} rpcp_input_index_t;

/* helper enum for rpcp_cmd_type_lora_enable handling */
typedef enum {
  rpcp_lora_enable_index_value = 0 /* encode the enable value (0=disable, 1=enable) in the last byte */
} rpcp_lora_enable_index_t;

/* helper enum for rpcp_cmd_type_gps_enable handling */
typedef enum {
  rpcp_gps_enable_index_value = 0 /* encode the enable value (0=disable, 1=enable) in the last byte */
} rpcp_gps_enable_index_t;

typedef enum {
  rpcp_gsm_enable_index_value = 0 /* encode the enable value (0=disable, 1=enable) in the last byte */
} rpcp_gsm_enable_index_t;

typedef enum {
  rpcp_onewire_enable_index_value = 0 /* encode the enable value (0=disable, 1=enable) in the last byte */
} rpcp_onewire_enable_index_t;

typedef enum {
  rpcp_io16_block_0_to_3,
  rpcp_io16_block_4_to_7,
  rpcp_io16_block_8_to_11,
  rpcp_io16_block_12_to_15
} rpcp_io16_block_t;

typedef enum
{
  rpcp_io16_direction_input,
  rpcp_io16_direction_output
} rpcp_io16_direction_t;

typedef enum
{
  rpcp_io16_set_direction_index_block = 0,
  rpcp_io16_set_direction_index_direction = 2
} rpcp_io16_set_direction_index_t;

typedef enum {
  rpcp_output_target_1  = 0,
  rpcp_output_target_2  = 1,
  rpcp_output_target_3  = 2,
  rpcp_output_target_4  = 3,
  rpcp_output_target_5  = 4,
  rpcp_output_target_6  = 5,
  rpcp_output_target_7  = 6,
  rpcp_output_target_8  = 7,
  rpcp_output_target_9  = 8,
  rpcp_output_target_10 = 9,
  rpcp_output_target_11 = 10,
  rpcp_output_target_12 = 11,
  rpcp_output_target_13 = 12,
  rpcp_output_target_14 = 13,
  rpcp_output_target_15 = 14,
  rpcp_output_target_16 = 15
} rpcp_output_target_t;

typedef enum
{
  rpcp_output_index_target = 0, /* encode the output target in the first byte */
  rpcp_output_index_value = 4,  /* encode the output value in the last 4 bytes */
} rpcp_output_index_t;

typedef enum
{
  rpcp_bufferstate_index_value = 0 /* encode the bufferstate value in the last byte */
} rpcp_bufferstate_index_t;

typedef enum
{
  rpcp_slcd_resolution_index_width = 0, /* encode the width in the first 4 bytes */
  rpcp_slcd_resolution_index_height = 4 /* encode the height in the last 4 bytes */
} rpcp_slcd_resolution_index_t;

typedef enum
{
  rpcp_eeprom_userdata_index_number = 0 /* encode the eeprom user index in the last byte */
} rpcp_eeprom_userdata_index_t;

typedef enum
{
  rpcp_plc_state_stop = 0,
  rpcp_plc_state_run = 1
} rpcp_plc_state_t;

typedef enum
{
  rpcp_plc_state_index = 0 /* encode the plc state in the last byte */
} rpcp_plc_state_index_t;

typedef enum
{
  rpcp_plc_cycletimes_index_min = 0, /* encode the min time in the first 2 bytes (0,1) */
  rpcp_plc_cycletimes_index_max = 2, /* encode the max time in the bytes 2,3 */
  rpcp_plc_cycletimes_index_cur = 4, /* encode the current time in bytes 4,5 */
  rpcp_plc_cycletimes_index_tick = 6,  /* encode the tick in the bytes 6,7 */
  rpcp_plc_cycletimes_index_comm = 8, /* encode the comm time in the bytes 8,9 */
  rpcp_plc_cycletimes_index_read = 10, /* encode the read time in the bytes 10,11 */
  rpcp_plc_cycletimes_index_program = 12, /* encode the program time in bytes 12,13*/
  rpcp_plc_cycletimes_index_write = 14  /* encode the write time in the bytes 14,15 */
} rpcp_plc_cycletimes_index_t;

typedef enum
{
  rpcp_plc_variables_value_index_size = 4 /* encode the size of the returned variables in bytes 5, 6, 7, 8 */
} rpcp_plc_variables_value_index_t;

typedef enum
{
  rpcp_test_run_index_failed_index = 1,
  rpcp_test_run_index_failed_low_count = 2,
  rpcp_test_run_index_failed_high_count = 3,
  rpcp_test_run_index_failed_count = 4,
  rpcp_test_run_index_success_count = 5,
  rpcp_test_run_index_total_count = 6,
  rpcp_test_run_index_result = 7 /* encode the success of the test run reply in the last base */
} rpcp_test_run_index_t;

typedef enum
{
  rpcp_test_run_result_success = 0,       /* no error occurred */
  rpcp_test_run_result_not_supported = 1, /* the image does not support test runs */
  rpcp_test_run_result_failed = 2         /* the test run failed */
} rpcp_test_run_result_t;

#define INT_FROM_BYTES(b) ((b[0] << 8*3) | (b[1] << 8*2) | (b[2] << 8*1) | (b[3] << 8*0))
#define BYTE_FROM_INT(i, c) ((i >> (3-c)*8) & 0xFF)

#define UINT16_FROM_BYTES(b) ((uint16_t)((b[0] << 8) | (b[1])))
#define BYTE_FROM_UINT16(i, c) ((i >> (1-c)*8) & 0xFF)

#define VAR_TO_UINT16(n, f) ((uint16_t) n | (f ? 0x8000 : 0x0) )
#define VAR_GET_NUMBER(v) ((uint16_t) v & ~0x8000)
#define VAR_IS_FORCED(v) (v & 0x8000)

#define EEPROM_UID_LENGTH 8

/* unique factory programmed 64-bit eeprom id */
typedef struct {
  uint8_t uid[EEPROM_UID_LENGTH];
} rpcp_eeprom_uid_t;

/* unique factory programmed 32-bit eeprom id */
typedef uint32_t rpcp_eeprom_base_uid_t;

#define EEPROM_DATA_LENGTH 8
typedef struct {
  uint8_t data[EEPROM_DATA_LENGTH];
} rpcp_eeprom_data_t;

typedef rpcp_eeprom_data_t rpcp_eeprom_hid_t;
#define EEPROM_HID_LENGTH EEPROM_DATA_LENGTH

typedef rpcp_eeprom_data_t rpcp_eeprom_fid_t;
#define EEPROM_FID_LENGTH EEPROM_DATA_LENGTH

#define MODULE_TYPE_LENGTH 8

/* type of a module */
typedef struct {
  uint8_t name[MODULE_TYPE_LENGTH];
} rpcp_module_type_t;

#define EEPROM_USER_DATA_COUNT 12

#endif
