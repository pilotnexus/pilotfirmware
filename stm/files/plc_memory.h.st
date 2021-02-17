
#include "stdint.h"
#include "stm32f10x.h"
#include "stm32f10x.h"

#ifndef PLC_MEMORY_H
#define PLC_MEMORY_H

typedef struct {
} plc_dev_t;

void plc_init_dev();
void plc_check_modules();
void plc_dev_to_mem();
void plc_mem_to_dev();
plc_dev_t * _get_plc_mem_devices_struct();

#endif