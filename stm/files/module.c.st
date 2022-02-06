#include "module.h"
#include "common_base.h"
#include "pilot_comm.h"
#include "pilot_uart.h"
#include "delay.h"
#include "ia8.h"
#include "pwm.h"
#include "i8.h"
#include "o8.h"
#include "demo.h"
#include "gps.h"
#include "gsm.h"
#include "counter8.h"
#include "io16.h"
#include "onewire.h"
#include "aio20.h"
#include "fpga.h"
#include "slcd.h"
#include "usart.h"

modules_t module_info, previous_module_info;

int try_init(int (*init)()) {
  int status;
  int tries = 0;

  /* initialize the io16 */
  do {
    if (tries > 0)
      pilot_delay_ms(10);
    status = init();
    tries++;
  }
  while (status != 0 && tries < 100);
  return status;
}

void pilot_modules_init()
{
  $model.Modules:{module|module_info.m$module.Slot$_status = pilot_module_init($module.Slot$);};separator="\n"$
}

//blanket implementations
int pilot_None_0_init() { return 0; }
int pilot_None_1_init() { return 0; }
int pilot_None_2_init() { return 0; }
int pilot_None_3_init() { return 0; }

int32_t pilot_module_init(uint8_t slot)
{
  switch(slot)
  {
    $model.Modules:{module|
    case $module.slot$:
      return try_init(pilot_$module.Name$_$module.Slot$_init);
      break; };separator="\n"$
  }
  return 0;
}

int32_t pilot_get_module_status(uint8_t slot)
{
  switch(slot)
  {
    $model.Modules:{module|
    case $module.slot$:
      return module_info.m$module.Slot$_status;
      break; };separator="\n"$
  }
  return 0;
}

void pilot_set_module_status(uint8_t slot, int32_t value)
{
  switch(slot)
  {
    $model.Modules:{module|
    case $module.slot$:
      module_info.m$module.Slot$_status = value;
      break;};separator="\n"$
  }
}

void send_module_status(uint8_t slot, int status)
{
  pilot_cmd_t cmd; 
  cmd.type = pilot_cmd_type_module_status_get;
  cmd.target = target_t_from_module_slot_and_port(slot,module_port_1);

  memcpy(cmd.data, &status, 4);
  cmd.length = MSG_LEN(4);
  pilot_comm_send_cmd(&cmd);

  //send to uart
  pilot_uart_send_module_status(slot, status);
}

int8_t pilot_module_status_changed(uint8_t slot)
{
  int8_t changed = 0;

  switch(slot)
  {
    $model.Modules:{module|
    case $module.slot$:
      if (module_info.m$module.Slot$_status != 0 && previous_module_info.m$module.Slot$_status == 0)
      {
        changed = 1;
        send_module_status($module.Slot$, module_info.m$module.Slot$_status);
      \}
      else if (module_info.m$module.Slot$_status == 0 && previous_module_info.m$module.Slot$_status != 0)
      {
        //trying to reinitialize
        module_info.m$module.Slot$_status = pilot_module_init($module.Slot$);
        
        //successful?
        if (module_info.m$module.Slot$_status == 0)
        {
            changed = -1; 
            send_module_status($module.Slot$, module_info.m$module.Slot$_status);
        \}
      \}

      previous_module_info.m$module.Slot$_status = module_info.m$module.Slot$_status;
      break;
    };separator="\n"$
  }

  return changed;
}

modules_t * get_module_info()
{
  return &module_info;
}

