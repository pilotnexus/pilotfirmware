#ifndef TYPES_H
#define TYPES_H

#include "common_base.h"
#include "stm.h"

#define RX_BUFFER_SIZE 1024
#define RX_BUFFER_BYTESIZE RX_BUFFER_SIZE*2

#define TX_BUFFER_SIZE 512
#define TX_BUFFER_BYTESIZE TX_BUFFER_SIZE*2

/* size needs always to be multiple of 4 */
typedef struct {
  uint16_t tx_buffer_min;
  uint16_t rx_buffer_min;
  uint32_t crc_errors;
} stats_t;

/* struct that holds private members */
typedef struct {
  // spidata_t rpiqueue_bufferstate[MODULES_COUNT * MODULE_PORT_COUNT]; /* holds the bufferstatus flags of the modules */
  stm_bufferstate_t bufferstate;
  pilot_current_cmd_t current_cmd; /* holds the current command that is being received from the rpi */
  volatile int current_cmd_timeout_counter;
  int current_cmd_overflow;
  int has_rpi_cmd_timed_out; /* is set if the current command has timed out */
  uint16_t spi_rx_array[RX_BUFFER_SIZE];
  uint32_t spi_rx_remain;
  
  uint16_t spi_tx_array[TX_BUFFER_SIZE];
  uint32_t spi_tx_start, spi_tx_end, spi_tx_current_end;

  int send2rpiqueue_overflow_count;
  int send2rpiqueue_usart_overflow_count;

  stats_t stats;
  //pilot_plc_vars_t plc;
} internals_t;

#endif
