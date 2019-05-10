#ifndef GPIO_CONFIG_H
#define GPIO_CONFIG_H

/* gpio board used for communication */
#define GPIO_Pin_BOARD GPIOB

/* gpio pins used for communication */
#define GPIO_Pin_DATA_M2R GPIO_Pin_2 /* output pin used to signal rpi that we want to begin/end a new transmission */

#endif
