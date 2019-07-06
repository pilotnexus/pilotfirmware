#ifndef PILOT_USART_H
#define PILOT_USART_H

#include "stm32_conf.h"

void _putchar(char c);

void pilot_usart_init(void);
void _putchars(char *c, int length);

#endif
