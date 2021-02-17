#include "module.h"

modules_t module_info, previous_module_info;

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

int8_t pilot_module_status_changed(uint8_t slot)
{
  int8_t changed = 0;

  switch(slot)
  {
    $model.Modules:{module|
    case $module.slot$:
      if (module_info.m$module.Slot$_status > 0 && previous_module_info.m$module.Slot$_status == 0)
        changed = 1;
      else if (module_info.m$module.Slot$_status == 0 && previous_module_info.m$module.Slot$_status > 0)
        changed = -1; 
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

