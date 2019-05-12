#include "pilot_usart.h"
#include "types.h"
#include <stdarg.h>
#include <stdio.h>
#include <errno.h>

/* raspberry pi serial port uses USART1 */

/* forward declaration of private functions */
static void pilot_usart_configure_clocks(void);
static void pilot_usart_configure_gpios(void);
static void pilot_usart_configure_usart(void);

#define GPIO_pilot_usart         GPIOA
#define GPIO_Pin_pilot_usart_Rx  GPIO_Pin_10
#define GPIO_Pin_pilot_usart_Tx  GPIO_Pin_9
#define GPIO_Pin_pilot_usart_Rx_Source GPIO_PinSource10
#define GPIO_Pin_pilot_usart_Tx_Source GPIO_PinSource9

///////////////////////////////////////
/* START Rpi functions */

/* called by pilot_usart_init() */
static void pilot_usart_configure_clocks()
{
#ifdef STM32F4XX
  /* enable GPIO clock */
  RCC_AHB1PeriphClockCmd( RCC_AHB1Periph_GPIOA, ENABLE );

  /* enable USART clock */
  RCC_APB2PeriphClockCmd( RCC_APB2Periph_USART1 , ENABLE );
#else
  RCC_APB2PeriphClockCmd( RCC_APB2Periph_GPIOA | RCC_APB2Periph_USART1 | RCC_APB2Periph_AFIO, ENABLE );
#endif
}

#ifdef STM32F4XX
static void pilot_usart_connect_usart_pins()
{
  GPIO_PinAFConfig( GPIO_pilot_usart, GPIO_Pin_pilot_usart_Tx_Source, GPIO_AF_USART1);
  GPIO_PinAFConfig( GPIO_pilot_usart, GPIO_Pin_pilot_usart_Rx_Source, GPIO_AF_USART1);
}
#endif

caddr_t _sbrk(int incr)
{
	extern char _ebss; // Defined by the linker
	static char *heap_end;
	char *prev_heap_end;
	if (heap_end == 0)
	{
		heap_end = &_ebss;
	}
	prev_heap_end = heap_end;
	char * stack = (char*) __get_MSP();
	if (heap_end + incr > stack)
	{
		errno = ENOMEM;
		return (caddr_t) -1;
	}
	heap_end += incr;
	return (caddr_t) prev_heap_end;
}

/* called by pilot_usart_init() */
static void pilot_usart_configure_gpios()
{
  GPIO_InitTypeDef inputs, outputs;

  GPIO_StructInit(&inputs);
  GPIO_StructInit(&outputs);

  /* configure Rx as input floating */
  inputs.GPIO_Pin = GPIO_Pin_pilot_usart_Rx;
  inputs.GPIO_Speed = GPIO_Speed_50MHz;
#ifdef STM32F4XX
  inputs.GPIO_Mode = GPIO_Mode_AF;
  inputs.GPIO_OType = GPIO_OType_PP;
  inputs.GPIO_PuPd = GPIO_PuPd_UP;
#else
  inputs.GPIO_Mode = GPIO_Mode_IN_FLOATING;
#endif
  GPIO_Init(GPIO_pilot_usart, &inputs);

  /* configure Tx as output alternate function */
  outputs.GPIO_Pin = GPIO_Pin_pilot_usart_Tx;
  outputs.GPIO_Speed = GPIO_Speed_50MHz;
#ifdef STM32F4XX
  outputs.GPIO_Mode = GPIO_Mode_AF;
  outputs.GPIO_OType = GPIO_OType_PP;
  outputs.GPIO_PuPd = GPIO_PuPd_UP;
#else
  outputs.GPIO_Mode = GPIO_Mode_AF_PP;
#endif

  GPIO_Init(GPIO_pilot_usart, &outputs);
}

/* called by pilot_usart_init() */
static void pilot_usart_configure_usart()
{
  USART_InitTypeDef usart;
  USART_StructInit(&usart);

  usart.USART_BaudRate            = 115200;
  usart.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  usart.USART_Mode                = USART_Mode_Tx | USART_Mode_Rx;
  usart.USART_Parity              = USART_Parity_No;
  usart.USART_StopBits            = USART_StopBits_1;
  usart.USART_WordLength          = USART_WordLength_8b;

  USART_Init(USART1, &usart);

  USART_Cmd(USART1, ENABLE);
}

/* initializes the usart hardwired to the raspberry pi 
   needs to be called before pilot_usart_send_string() or pilot_usart_send_char() */
void pilot_usart_init()
{
  pilot_usart_configure_clocks();
#ifdef STM32F4XX
  pilot_usart_connect_usart_pins();
#endif
  pilot_usart_configure_gpios();
  pilot_usart_configure_usart();
}

/* sends the zero terminated string to the raspberry pi 
   call pilot_usart_init() before calling this function */
void pilot_usart_send_string(char* msg)
{
  int i=0;
  while (msg[i] != 0)
  {    
    USART_SendData(USART1, msg[i++]);
    while (USART_GetFlagStatus(USART1, USART_FLAG_TXE) == RESET);
  }
}

/* sends the zero terminated string to the raspberry pi 
   call pilot_usart_init() before calling this function */
void pilot_usart_send_formatted_string(const char *format, ...)
{
	va_list args;
	static char buffer[100];

	va_start(args, format);
	vsnprintf(buffer, sizeof buffer, format, args);
	va_end(args);
	pilot_usart_send_string(buffer);
}

/* sends the character to the raspberry pi 
   call pilot_usart_init() before calling this function */
void pilot_usart_send_char(char c)
{
  USART_SendData(USART1, c);
  while (USART_GetFlagStatus(USART1, USART_FLAG_TXE) == RESET);
}

void pilot_usart_send_chars(char *c, int length)
{
  int i;
  for (i = 0; i < length; i++)
    pilot_usart_send_char(c[i]);
}

#define digit2hex(num) ((char)((num < 0xA) ? 0x30 + num : 0x41 - 0xA + num))

void pilot_usart_send_byte_as_hex(uint8_t b)
{
  uint8_t p1, p2;

  /* first nibble */
  p1 = (b >> 4) & 0x0F;

  /* second nibble */
  p2 = b & 0x0F;

  pilot_usart_send_string("0x");
  pilot_usart_send_char(digit2hex(p1));
  pilot_usart_send_char(digit2hex(p2));
}

void pilot_usart_send_bytes_as_hex(uint8_t *b, int32_t length)
{
  int i;
  for (i = 0; i < length; i++)
  {
    pilot_usart_send_byte_as_hex(b[i]);
    pilot_usart_send_char(' ');
  }
}

/* END Rpi functions */
///////////////////////////////////////
