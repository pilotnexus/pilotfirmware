#ifndef __RPC_SPI_H__
#define __RPC_SPI_H__

#include "stm32_conf.h"
#include <stdbool.h>

/* all spi devices */
typedef enum {
  spi_id_invalid = -1$if(model.SPIs)$,$endif$
  $model.SPIs:{spi|spi_id_$i$ /* $spi.Name$, ($spi.GPIO$: clk=$spi.ClkPin$, mosi=$spi.MosiPin$), nss: ($spi.NssPin.GPIO$ $spi.NssPin.Pin$) */}; separator = ",\n"$
} spi_id_t;

/* possible states of the chip select */
typedef enum {
  chip_select_enable  = 0,
  chip_select_disable = 1
} chip_select_t;

/* one-time setup */
void rpcp_spi_setup();

/* set the chip select */
bool rpcp_spi_set_cs(spi_id_t spi_id, chip_select_t cs);

/* sends data only */
void rpcp_spi_send(spi_id_t spi_id, uint16_t mosi);

/* data exchange returns miso */
uint16_t rpcp_spi_dataexchange(spi_id_t spi_id, uint16_t mosi);

#endif
