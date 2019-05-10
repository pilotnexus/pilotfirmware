#include <stdint.h>

#ifndef RPC_PLC_H
#define RPC_PLC_H

/* for set_plc_variable */
#define PLC_VAR_FORCE_BIT     0x8000
#define PLC_VAR_UNFORCE_BIT   0x4000

/*for get_plc_variable*/
#define PLC_VAR_SUBSCRIBE_BIT     0x8000
#define PLC_VAR_UNSUBSCRIBE_BIT   0x4000

void plc_loop(void);
int configure_plc_read_variables(uint16_t *variables, int count);
int read_plc_variables(uint8_t *buffer);
void configure_plc_write_variables(uint16_t *variables, int count);
void write_plc_variables(uint8_t *buffer, int count);
void init_plc_modules();
int read_from_plc_variable(uint16_t number, uint8_t *buffer, int index);
int write_to_plc_variable(uint16_t varnumber, uint8_t *buffer, int index);
int find_next_updated_variable();
void plc_port_config(uint8_t slot, uint8_t port, uint16_t baud);

void plc_tick();
#endif