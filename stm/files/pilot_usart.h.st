#ifndef pilot_usart_H
#define pilot_usart_H

#include "stm32_conf.h"

void pilot_usart_init(void);
void pilot_usart_send_string(char *msg);
void pilot_usart_send_char(char c);
void pilot_usart_send_chars(char *c, int length);
void pilot_usart_send_byte_as_hex(uint8_t b);
void pilot_usart_send_bytes_as_hex(uint8_t *b, int32_t length);
void pilot_usart_send_formatted_string(const char *format, ...);

#endif
