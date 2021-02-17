#include "plc.h"
#include "plc_memory.h"

extern plc_dev_t plc_mem_devices;

extern void plc_mem_to_var();
extern void plc_var_to_mem();

void plc_read_inputs()
{
  plc_check_modules();
  plc_dev_to_mem();
  plc_mem_to_var();
}

void plc_write_outputs() 
{
  plc_var_to_mem();
  plc_mem_to_dev();
}

void plc_internal_init(int *plc_state, void (*main_loop)(void *)) 
{
  plc_init_dev();
  plc_init(main_loop);
}

#ifndef EXTERNAL_PLC

void config_run__() {}
void config_init__() {}

void plc_init(void (*main_loop)(void *)) 
{
  main_loop(0);
}

void plc_run(void *state, uint64_t tick)
{
  config_run__(tick);
}

void plc_mem_to_var() {}
void plc_var_to_mem() {}


int plc_configure_read_variables(uint16_t *variables, int count)
{
  return 0;
}

int plc_configure_write_variables(uint16_t *variables, int count)
{
  return 0;
}

int plc_read_variables(uint8_t *buffer)
{
  return 0;
}

void plc_write_variables(uint8_t *buffer, int count)
{
}

int plc_read_from_variable(uint16_t number, uint8_t subvalue, uint8_t *buffer, int size)
{
  return 0;
}

int plc_write_to_variable(uint16_t varnumber, uint8_t subvalue, uint8_t *buffer, int size)
{
  return 0;
}

uint8_t plc_read_config_from_variable(uint16_t number, uint8_t config)
{
  return 0;
}

uint8_t plc_write_config_to_variable(uint16_t number, uint8_t config, uint8_t value)
{
  return 0;
}

uint32_t plc_get_updated_variables(uint8_t *data, uint32_t size)
{
  return 0;
}

void plc_port_config(uint8_t slot, uint8_t port, uint16_t baud)
{}

int plc_fw_version(uint8_t part, uint8_t *buf, uint32_t buf_size)
{
  return 0;
}

#endif
