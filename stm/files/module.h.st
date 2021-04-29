#include "stdint.h"

#ifndef MODULE_H
#define MODULE_H

/* module status */
typedef struct __attribute__((__packed__)) {
$model.Modules:{module|
  int32_t m$module.Slot$_status;
};separator="\n"$
} modules_t;

void pilot_modules_init();
int32_t pilot_module_init(uint8_t slot);
void send_module_status(uint8_t slot, int status);
int32_t pilot_get_module_status(uint8_t slot);
void pilot_set_module_status(uint8_t slot, int32_t value);
int8_t pilot_module_status_changed(uint8_t slot);
modules_t * get_module_info();
#endif