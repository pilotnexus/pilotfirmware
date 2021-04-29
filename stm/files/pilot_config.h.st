#ifndef PILOT_CONFIG_H
#define PILOT_CONFIG_H

#include "stdint.h"

int32_t pilot_get_plc_state();
void pilot_set_plc_state(int32_t state);

void pilot_config_init();
void pilot_loop_pre_init();
void pilot_loop_head();
void pilot_loop_tail();

#endif