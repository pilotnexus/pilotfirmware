#include "plc.h"
#include <limits.h> //for UINT_MAX

void config_run__(unsigned long tick);
void config_init__(void);

unsigned long long __tick = 0ULL;

/* cycle time */
unsigned int cycle_current = 0; // time for the full cycle
unsigned int cycle_current_comm = 0; //time until comm done
unsigned int cycle_current_read = 0; //time until read
unsigned int cycle_current_program = 0; //time for program
unsigned int cycle_current_write = 0; //time until write

unsigned int cycle_min = UINT_MAX;
unsigned int cycle_max = 0;

// plc_state
int plc_state = 0;

void plc_loop(void)
{}

void plc_tick(void)
{}

int configure_plc_read_variables(uint16_t *variables, int count)
{
  return 0;
}

int read_plc_variables(uint8_t *buffer)
{
  return 0;
}

void configure_plc_write_variables(uint16_t *variables, int count)
{}

void write_plc_variables(uint8_t *buffer, int count)
{
}

void init_plc_modules()
{}

int read_from_plc_variable(uint16_t number, uint8_t *buffer, int index)
{
  return 0;
}

int write_to_plc_variable(uint16_t varnumber, uint8_t *buffer, int index)
{
  return 0;
}

int find_next_updated_variable()
{
return 0;
}

void plc_port_config(uint8_t slot, uint8_t port, uint16_t baud)
{}

