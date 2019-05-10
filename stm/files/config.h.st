#ifndef CONFIG_H
#define CONFIG_H

#include "iec_std_lib.h"

//PLC located variables
/*
$model.PLC.LocatedVariables.MemoryLocations:{m|unsigned char __attribute__((section(".located$m.Location$Mem"))) located_$m.Location$[$m.Size$] __attribute__((aligned($m.AlignedSize$)));};separator="\n"$
*/

$model.PLC.LocatedVariables.MemoryLocations:{m|unsigned char *located_$m.Location$ = (unsigned char *)$m.StartAddressFormatted$;};separator="\n"$

//bitband calculation:  *((char*)(BITBAND_BASE + ((((int)array)-0x20000000+byte) * 32) + (bit*4)))

//location address declarations
$model.PLC.LocatedVariables.LocatedVariables:{v|$v.LocatedAddressDeclaration$};separator="\n"$

#endif
