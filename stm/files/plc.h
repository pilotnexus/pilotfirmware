#include <stdint.h>

#ifndef RPC_PLC_H
#define RPC_PLC_H

/* for set_plc_variable */
#define PLC_VAR_FORCE_BIT     0x8000
#define PLC_VAR_UNFORCE_BIT   0x4000

/*for get_plc_variable*/
#define PLC_VAR_SUBSCRIBE_BIT     0x8000
#define PLC_VAR_UNSUBSCRIBE_BIT   0x4000

plc_internal_init();
void plc_init();
void plc_internal_init();
void plc_read_inputs();
void plc_write_outputs();
void plc_run(uint64_t tick_us);
void plc_init_modules(void);
void plc_mem_to_var();
void plc_var_to_mem();
int plc_configure_read_variables(uint16_t *variables, int count);
int plc_read_variables(uint8_t *buffer);
int plc_configure_write_variables(uint16_t *variables, int count);
void plc_write_variables(uint8_t *buffer, int count);
int plc_read_from_variable(uint16_t number, uint8_t *buffer, int index);
int plc_write_to_variable(uint16_t varnumber, uint8_t *buffer, int index);
int plc_find_next_updated_variable();
void plc_port_config(uint8_t slot, uint8_t port, uint16_t baud);

#endif