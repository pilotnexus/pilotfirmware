/* this file defines commands used by the rpi<-> communication */

#ifndef RPC_STM_H
#define RPC_STM_H

#include "common_base.h"

/* macros for manipulating spidata_t */
#define spi_header_t_get_target_t(header) (target_t)header

#endif
