#ifndef PILOT_COMM_H
#define PILOT_COMM_H

#include <string.h>
#include "common_base.h"
#include "stm32f10x_dma.h"

#define get_spi_data(target, data) ((target << 8) | (data))

void pilot_comm_init(void);
static void pilot_setup_spi_tx();
void pilot_handle_received_data(void);
void pilot_comm_increment_cmd_timeout(void);
void pilot_comm_enqueue_usart(uint16_t data);
void pilot_comm_spi_tx_done(void);
void pilot_comm_send(target_t target, char* buffer, int length);
void pilot_comm_send_cmd(pilot_cmd_t *cmd);
void pilot_comm_send_input_changed(module_slot_t slot);
void pilot_comm_send_subscribed_plc_variables(pilot_cmd_t *cmd);

void pilot_rpi_plc_state_get();

void pilot_comm_set_baudrate(module_slot_t slot, module_port_t port, int baudrate);
void pilot_comm_set_stopbits(module_slot_t slot, module_port_t port, uint16_t stopbits);
void pilot_comm_set_parity(module_slot_t slot, module_port_t port, uint16_t parity);
void pilot_comm_set_wordlength(module_slot_t slot, module_port_t port, uint16_t wordlength);

int pilot_uart_mode_get();
void pilot_uart_mode_set(int mode);
#endif
