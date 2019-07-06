#include "plc.h"


void plc_init_modules() 
{}

void plc_read_inputs()
{}

void plc_write_outputs()
{}

#ifndef EXTERNAL_PLC

void config_run__() {}
void config_init__() {}

void plc_init() {}

void plc_run(unsigned long tick)
{
  config_run__(tick);
}

/* Implementation for multi-read/write vars */
int plc_configure_read_variables(uint16_t *variables, int count)
{
  return 0;
}

void plc_configure_write_variables(uint16_t *variables, int count)
{}

int plc_read_variables(uint8_t *buffer)
{
  return 0;
}

void plc_write_variables(uint8_t *buffer, int count)
{
}

int plc_read_from_variable(uint16_t number, uint8_t *buffer, int index)
{
  return 0;
}

int plc_write_to_variable(uint16_t varnumber, uint8_t *buffer, int index)
{
  return 0;
}

int plc_find_next_updated_variable()
{
  return -1;
}

void plc_port_config(uint8_t slot, uint8_t port, uint16_t baud)
{}

#endif