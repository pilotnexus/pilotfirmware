#ifndef pilot_usart_H
#define pilot_usart_H

#include "stm32_conf.h"

void rpcp_pilot_usart_init(void);
void rpcp_pilot_usart_send_string(char *msg);
void rpcp_pilot_usart_send_char(char c);
void rpcp_pilot_usart_send_chars(char *c, int length);
void rpcp_pilot_usart_send_byte_as_hex(uint8_t b);
void rpcp_pilot_usart_send_bytes_as_hex(uint8_t *b, int32_t length);
void rpcp_pilot_usart_send_formatted_string(const char *format, ...);

#endif
