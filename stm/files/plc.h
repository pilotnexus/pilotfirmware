#include <stdint.h>
#include "module.h"

#ifndef RPC_PLC_H
#define RPC_PLC_H

// opt:
//     bit 7  : 1 - no struct follows, 0 - another struct at the end of this one
//     bit 4-6: value type: 00 - current value, 01 - changed value, 10 - forced value, 11 - config value
//     bit 0-3: length of value
#define GET_VAR_FOLLOWS(opt) (opt & 0x80)
#define GET_VAR_SUB(opt) ((opt >> 4) & 0x7)
#define GET_VAR_LEN(opt) (opt & 0xF)
#define SET_VAR_FOLLOWS(f) (f << 7)
#define SET_VAR_SUB(sub) ((sub & 0x7) << 4)
#define SET_VAR_LEN(len) (len & 0xF)

#define MSG_PLC_VAR_HEADER_LEN 3 //opt + number size
#define MAX_PLC_VAR_LEN 8

typedef struct __attribute__((__packed__)) {
  uint8_t config;
  uint16_t number;
  uint8_t value;
} msg_plc_var_config_t;

typedef struct __attribute__((__packed__)) {
  uint16_t number;
  uint16_t subvalue;
  uint8_t value[MAX_PLC_VAR_LEN];
} plc_var_t;

typedef struct __attribute__((__packed__)) {
  uint8_t opt;
  uint16_t number;
  uint8_t value[MAX_PLC_VAR_LEN];
} msg_plc_var_t;

void plc_init(void (*main_loop)());
void plc_internal_init(int *plc_state, void (*main_loop)(void *));
void plc_read_inputs();
void plc_write_outputs();
void plc_run(void *state, uint64_t tick_us);
void plc_init_modules(void);
void plc_mem_to_var();
void plc_var_to_mem();
uint8_t plc_read_config_from_variable(uint16_t number, uint8_t config);
uint8_t plc_write_config_to_variable(uint16_t number, uint8_t config, uint8_t value);
int plc_read_from_variable(uint16_t number, uint8_t subvalue, uint8_t *buffer, int index);
int plc_write_to_variable(uint16_t number, uint8_t subvalue, uint8_t *buffer, int index);
uint32_t plc_get_updated_variables(uint8_t *data, uint32_t size);
void plc_port_config(uint8_t slot, uint8_t port, uint16_t baud);
int plc_fw_version(uint8_t part, uint8_t *buf, uint32_t buf_size);
#endif