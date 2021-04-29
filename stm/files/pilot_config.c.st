#include "pilot_config.h"
#include "pilot_uart.h"
#include "rtc.h"
#include "pilot_comm.h"

// plc_state
int32_t plc_state;

// uart_echo_on
bool uart_echo_on=true;

int32_t pilot_get_plc_state()
{
  return plc_state;
}

void pilot_set_plc_state(int32_t state)
{
  plc_state = state;
  pilot_rpi_plc_state_get();   //send state over SPI
  pilot_uart_send_plc_state(); //send state over UART
}

void pilot_config_init()
{
}

void pilot_loop_pre_init() {
}

void pilot_loop_head() {
}

void pilot_loop_tail() {
}