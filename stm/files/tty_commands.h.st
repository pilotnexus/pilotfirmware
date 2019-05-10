/*
   this file contains defines and functions used for communication between the raspberry pi driver and the  prototype implementation
   it is shared between the drivers and stm32f
*/

#ifndef TTY_COMMANDS_H
#define TTY_COMMANDS_H

/* usart baudrate command values */
typedef enum
{
  rpcp_cmd_baudrate_9600,
  rpcp_cmd_baudrate_19200,
  rpcp_cmd_baudrate_38400,
  rpcp_cmd_baudrate_57600,
  rpcp_cmd_baudrate_115200,
  rpcp_cmd_baudrate_230400,
  rpcp_cmd_baudrate_250000
} rpcp_cmd_baudrate_t;

/* usart stopbit command values */
typedef enum
{
  rpcp_cmd_stopbits_1,
  rpcp_cmd_stopbits_2
} rpcp_cmd_stopbits_t;

/* usart wordlength command values */
typedef enum
{
  rpcp_cmd_wordlength_8,
  rpcp_cmd_wordlength_9
} rpcp_cmd_wordlength_t;

/* usart parity command values */
typedef enum
{
  rpcp_cmd_parity_none,
  rpcp_cmd_parity_even,
  rpcp_cmd_parity_odd
} rpcp_cmd_parity_t;

static rpcp_cmd_baudrate_t rpc_stm_proto_int_to_baudrate(int value)
{
  rpcp_cmd_baudrate_t baudrate;

  switch (value)
  {
    case 9600: baudrate   = rpcp_cmd_baudrate_9600; break;
    case 19200: baudrate  = rpcp_cmd_baudrate_19200; break;
    case 38400: baudrate  = rpcp_cmd_baudrate_38400; break;
    case 57600: baudrate  = rpcp_cmd_baudrate_57600; break;
    case 115200: baudrate = rpcp_cmd_baudrate_115200; break;
    case 230400: baudrate = rpcp_cmd_baudrate_230400; break;
    case 250000: baudrate = rpcp_cmd_baudrate_250000; break;
    default: baudrate     = rpcp_cmd_baudrate_9600; break;
  }

  return baudrate;
}

#endif
