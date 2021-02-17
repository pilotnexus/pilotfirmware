
#include "plc_memory.h"
#include "string.h"

#include "stm32f10x.h"
#include "stm32f10x.h"
#include "stm32f10x.h"

// Memory mapped device instance
volatile plc_dev_t __attribute__((section(".plc_mem_devices"))) plc_mem_devices = { };

void plc_init_dev()
{
}

void plc_check_modules()
{
}

void plc_dev_to_mem()
{
}

void plc_mem_to_dev()
{
}

plc_dev_t * _get_plc_mem_devices_struct() {
  return (plc_dev_t *) &plc_mem_devices;
}