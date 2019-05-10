#ifndef __RPC_ONEWIRE_H__
#define __RPC_ONEWIRE_H__

#include "stm32_conf.h"

$model.OneWires: {ow|
void rpc_$ow.Name$_init(void);
void rpc_$ow.Name$_set_enable(int enable);
int rpc_$ow.Name$_get_enable(void);

};separator="\n"$
#endif
