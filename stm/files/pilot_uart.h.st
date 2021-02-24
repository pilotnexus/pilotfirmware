#ifndef PILOT_UART_H
#define PILOT_UART_H

#include <stdbool.h>
#include "stm32_conf.h"
#include "stm32f10x_dma.h"

#define UART_RX_BUFFER_SIZE 1024  
#define UART_TX_BUFFER_SIZE 1024

typedef struct {
  //UART DMA
  uint8_t uart_rx_array[UART_RX_BUFFER_SIZE];
  uint32_t uart_rx_remain;

  uint8_t uart_tx_array[UART_TX_BUFFER_SIZE];
  uint32_t uart_tx_start, uart_tx_end, uart_tx_current_end;

  int send2rpiqueue_overflow_count;
  bool transmitting;

  uint8_t uart_mode;
  uint8_t uart_mode_state;
  uint16_t uart_var_num;
  uint32_t debug_cycle_skip_count;
} uart_internals_t;

void pilot_usart_init(void);
void pilot_uart_comm();
bool _putchar(char c);
bool _putchars(char *c, int length);
void pilot_setup_uart_tx();

#endif

