#ifndef __PILOT_ONEWIRE_H__
#define __PILOT_ONEWIRE_H__

#include "stm32_conf.h"

$model.OneWires: {ow|
void pilot_$ow.Name$_init(void);
void pilot_$ow.Name$_set_enable(int enable);
int pilot_$ow.Name$_get_enable(void);

};separator="\n"$
#endif
