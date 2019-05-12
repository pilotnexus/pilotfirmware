#ifndef __pilot_SLCD_H__
#define __pilot_SLCD_H__

#include <stdint.h>
#include "spi.h"

typedef struct {
  int width;
  int height;
} slcd_resolution_t;

$model.SLCDs:{slcd|

/* initialize the slcd */
void pilot_$slcd.Name$_init();

/* sets the resolution of the display */
void pilot_$slcd.Name$_set_resolution(const slcd_resolution_t *resolution);

/* gets the resolution of the display */
void pilot_$slcd.Name$_get_resolution(slcd_resolution_t *resolution);

/* update the display with the contents of the display buffer */
void pilot_$slcd.Name$_update_buffer_start();

/* update a single display buffer byte */
void pilot_$slcd.Name$_update_buffer_data(uint8_t data);

}; separator="\n"$

#endif
