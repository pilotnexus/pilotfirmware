#include "pilot_uart.h"
#include "pilot_config.h"
#include "plc_memory.h"
#include "types.h"
#include <stdarg.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <module.h>
#include <plc.h>
#include "main.h"
#include "printf.h"

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

static uart_internals_t uart_internals = {0};

extern bool uart_echo_on;
extern int32_t plc_state;
extern cycletimes_t cycles;

//DMA channel 2 -> SPI1_RX (MOSI)
static DMA_InitTypeDef UART_DMA_InitStructure_rx;

//DMA channel 3 -> SPI1_TX (MISO)
static DMA_InitTypeDef UART_DMA_InitStructure_tx;

static const unsigned char base64_enc_map[64] =
{
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd',
    'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
    'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', '+', '/'
};
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
  static USART_InitTypeDef usart;
  USART_StructInit(&usart);

  usart.USART_BaudRate            = 921600; //115200;
  usart.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  usart.USART_Mode                = USART_Mode_Tx | USART_Mode_Rx;
  usart.USART_Parity              = USART_Parity_No;
  usart.USART_StopBits            = USART_StopBits_1;
  usart.USART_WordLength          = USART_WordLength_8b;

  USART_Init(USART1, &usart);

  USART_DMACmd(USART1, USART_DMAReq_Rx | USART_DMAReq_Tx, ENABLE);
  USART_Cmd(USART1, ENABLE);
}

static void uart_dma_init() 
{
  /* DMA UART1 RX */
  RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1, ENABLE);      // Enable DMA1 clock

  DMA_DeInit(DMA1_Channel5);                              // Reset DMA1 channe1 to default values;

  UART_DMA_InitStructure_rx.DMA_M2M = DMA_M2M_Disable;            // M2M Disabled- Peripheral mode (requires timer trigger)
  UART_DMA_InitStructure_rx.DMA_Mode = DMA_Mode_Circular;         // Circular mode
  UART_DMA_InitStructure_rx.DMA_Priority = DMA_Priority_High; // High priority
  UART_DMA_InitStructure_rx.DMA_DIR = DMA_DIR_PeripheralSRC;      // Peripheral to Memory 

  UART_DMA_InitStructure_rx.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Byte; // 8-bit Register
  UART_DMA_InitStructure_rx.DMA_PeripheralInc = DMA_PeripheralInc_Disable;            // Always write to same register
  UART_DMA_InitStructure_rx.DMA_PeripheralBaseAddr = (uint32_t)&USART1->DR;           // Output data for GPIO

  UART_DMA_InitStructure_rx.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;         // 8-bit array
  UART_DMA_InitStructure_rx.DMA_MemoryInc = DMA_MemoryInc_Enable;                     // Increment through array
  UART_DMA_InitStructure_rx.DMA_MemoryBaseAddr = (uint32_t)&uart_internals.uart_rx_array;                 // 8-bit destination data

  UART_DMA_InitStructure_rx.DMA_BufferSize = UART_RX_BUFFER_SIZE;           // Size of destination array 
  uart_internals.uart_rx_remain = UART_RX_BUFFER_SIZE;

  DMA_Init(DMA1_Channel5, &UART_DMA_InitStructure_rx);            // Initialize DMA

  // Enable RX channels
  USART_ClearFlag(USART1,USART_FLAG_RXNE);
  //USART_DMACmd(USART1,USART_DMAReq_Rx,ENABLE);
  DMA_Cmd(DMA1_Channel5,ENABLE);

  // set up TX structure
  DMA_DeInit(DMA1_Channel4);                              // Reset DMA1 channe1 to default values;
  UART_DMA_InitStructure_tx.DMA_M2M = DMA_M2M_Disable;            // M2M Disabled- Peripheral mode (requires timer trigger)
  UART_DMA_InitStructure_tx.DMA_Mode = DMA_Mode_Normal;         // Circular mode
  UART_DMA_InitStructure_tx.DMA_Priority = DMA_Priority_High; // High priority
  UART_DMA_InitStructure_tx.DMA_DIR = DMA_DIR_PeripheralDST;      // Memory to Peripheral

  UART_DMA_InitStructure_tx.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Byte; // 8-bit Register
  UART_DMA_InitStructure_tx.DMA_PeripheralInc = DMA_PeripheralInc_Disable;            // Always write to same register
  UART_DMA_InitStructure_tx.DMA_PeripheralBaseAddr = (uint32_t)&USART1->DR;           // Output data for GPIO

  UART_DMA_InitStructure_tx.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;         // 8-bit array
  UART_DMA_InitStructure_tx.DMA_MemoryInc = DMA_MemoryInc_Enable;                     // Increment through array

  DMA_Init(DMA1_Channel4, &UART_DMA_InitStructure_tx);            // Initialize DMA

  // TC and TE interrupts
  NVIC_InitTypeDef NVIC_InitStructure_tx;
  NVIC_InitStructure_tx.NVIC_IRQChannel = DMA1_Channel4_IRQn;
  NVIC_InitStructure_tx.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure_tx.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure_tx.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure_tx);
}

static void uart_dma_tx()
{
  //DMA_Cmd(DMA1_Channel4,DISABLE);

  USART_DMACmd(USART1, USART_DMAReq_Tx, ENABLE);

  DMA1_Channel4->CPAR = (uint32_t)&USART1->DR;           // 1. Write USART_DR
  DMA1_Channel4->CMAR = (uint32_t)&uart_internals.uart_tx_array[uart_internals.uart_tx_start]; // 2. Write Memory address
  DMA1_Channel4->CNDTR = (uart_internals.uart_tx_current_end-uart_internals.uart_tx_start); //3. Set number of bytes to transfer

  DMA1_Channel4->CCR &= DMA_DIR_PeripheralDST | DMA_Mode_Normal |
                       DMA_PeripheralInc_Disable | DMA_MemoryInc_Enable |
                       DMA_Priority_Low | DMA_M2M_Disable;

  // Enable USART TX DMA request
  DMA_ITConfig(DMA1_Channel4, DMA_IT_TC | DMA_IT_TE, ENABLE); // 5. Configure DMA interrupt generation
  USART_ClearFlag(USART1, USART_FLAG_TC); // 6. Clear TC bit in SR register
  DMA_Cmd(DMA1_Channel4,ENABLE); // 7. Activate channel
}

/* initializes the usart hardwired to the raspberry pi 
   needs to be called before printf() or _putchar() */
void pilot_usart_init()
{
  pilot_usart_configure_clocks();
#ifdef STM32F4XX
  pilot_usart_connect_usart_pins();
#endif
  pilot_usart_configure_gpios();
  pilot_usart_configure_usart();

  uart_internals.uart_rx_remain = UART_RX_BUFFER_SIZE;
  uart_internals.transmitting = false;
  uart_internals.uart_tx_start = 0;
  uart_internals.uart_tx_end = 0;
  uart_dma_init();
}


/* sends the character to the raspberry pi 
   call pilot_usart_init() before calling this function */
bool _putchar(char c)
{
  __disable_irq();
  uint32_t nextindex = uart_internals.uart_tx_end + 1;
  if (nextindex >= UART_TX_BUFFER_SIZE) 
    nextindex = 0;

  if (nextindex == uart_internals.uart_tx_start) //error! OVERFLOW
  {
    uart_internals.send2rpiqueue_overflow_count++; // TODO - this is the SPI overflow counter, maybe make a separate for UART
  __enable_irq();
    return false;
  }
  else
  {
    uart_internals.uart_tx_array[uart_internals.uart_tx_end] = c; // set data to current index
    uart_internals.uart_tx_end = nextindex; //and progress to the next index

    __enable_irq();
    return true;
  }

  //USART_SendData(USART1, c);
  //while (USART_GetFlagStatus(USART1, USART_FLAG_TXE) == RESET);
}

bool _putchars(char *c, int length)
{
  int i;
  for (i = 0; i < length; i++)
    _putchar(c[i]);

  return true;
}

/*
 * enqueue a buffer in base64 format
 */
int base64_encode_send( const uint8_t *src, size_t slen )
{
    size_t i, n;
    int C1, C2, C3;

    if( slen == 0 )
        return( 0 );

    n = (slen << 3) / 6;

    switch( (slen << 3) - (n * 6) )
    {
        case  2: n += 3; break;
        case  4: n += 2; break;
        default: break;
    }

    n = (slen / 3) * 3;

    for( i = 0; i < n; i += 3 )
    {
        C1 = *src++;
        C2 = *src++;
        C3 = *src++;

        _putchar(base64_enc_map[(C1 >> 2) & 0x3F]);
        _putchar(base64_enc_map[(((C1 &  3) << 4) + (C2 >> 4)) & 0x3F]);
        _putchar(base64_enc_map[(((C2 & 15) << 2) + (C3 >> 6)) & 0x3F]);
        _putchar(base64_enc_map[C3 & 0x3F]);
    }

    if( i < slen )
    {
        C1 = *src++;
        C2 = ((i + 1) < slen) ? *src++ : 0;

        _putchar(base64_enc_map[(C1 >> 2) & 0x3F]);
        _putchar(base64_enc_map[(((C1 & 3) << 4) + (C2 >> 4)) & 0x3F]);

        if( (i + 1) < slen )
             _putchar(base64_enc_map[((C2 & 15) << 2) & 0x3F]);
        else _putchar('=');

        _putchar('=');
    }

    return( 0 );
}

//stream encoding variables
uint8_t C1, C2, C3, b64_step;

void base64_encode_byte(uint8_t c)
{
    switch (b64_step)
    {
        case 0:
          C1 = c;
          _putchar(base64_enc_map[(C1 >> 2) & 0x3F]);
          b64_step++;
          break;
        case 1:
          C2 = c;
          _putchar(base64_enc_map[(((C1 &  3) << 4) + (C2 >> 4)) & 0x3F]);
          b64_step++;
          break;
        case 2:
          C3 = c;
          _putchar(base64_enc_map[(((C2 & 15) << 2) + (C3 >> 6)) & 0x3F]);
          _putchar(base64_enc_map[C3 & 0x3F]);
          b64_step = 0;
          break;
    }
}

void base64_end_encode()
{

    switch(b64_step)
    {
      case 1:
        C2 = 0; C3 = 0;
        _putchar(base64_enc_map[(((C1 &  3) << 4) + (C2 >> 4)) & 0x3F]);
        _putchar('=');
        _putchar('=');
      break;
      case 2:
        C3 = 0;
        _putchar(base64_enc_map[(((C2 & 15) << 2) + (C3 >> 6)) & 0x3F]);
        _putchar('=');
      break;
    }

    b64_step = 0;
}


void send_var_debug_data(uint64_t us) 
{
  int size = 0, i, j;
  uint8_t buf[MAX_PLC_VAR_LEN];
  uint8_t *us_ptr = (uint8_t *)&us;
  uint16_t varcount=0;

  for (i = 0; i < uart_internals.uart_mode; i++)
  {
    size = plc_read_from_variable(uart_internals.uart_var_num, 0, buf, 0);
    if (size == 0)
    {
      uart_internals.uart_var_num = 0;
      break;
    }
    else if (size > 0) 
    {
      if (varcount==0)
      {
        _putchar('&'); //start of message
        for (j = 0; j < sizeof(us); j++)
          base64_encode_byte(*(us_ptr+j));
      }

      //encode varnumber
      base64_encode_byte(uart_internals.uart_var_num & 0xFF);
      base64_encode_byte(uart_internals.uart_var_num >> 8);
      //encode variable
      for (j = 0; j < size; j++)
        base64_encode_byte(buf[j]);

      uart_internals.uart_var_num++; //next variable
      varcount++;
    }
  }

  if (varcount > 0) //we have transmitted something
  {
    base64_end_encode();
    _putchar('\n'); //end of line
  }
}

void send_module_debug_data(uint64_t cycle, uint64_t us) 
{
  int i;
  uint8_t *p;

  //transmit module debug data
  _putchar('*'); //start debug message

  //send cycle
  p = (uint8_t *)&cycle;
  for (i=0;i<sizeof(cycle);i++)
    base64_encode_byte(*p++);

  //send us
  p = (uint8_t *)&us;
  for (i=0;i<sizeof(us);i++)
    base64_encode_byte(*p++);

  //send current cycle time
  p = (uint8_t *)&cycles.cycle_current;
  for (i=0;i<2;i++)
    base64_encode_byte(*p++);

  //send plc state
  p = (uint8_t *)&plc_state;
  for (i=0;i<4;i++)
    base64_encode_byte(*p++);

  //send module state 
  p = (uint8_t *)get_module_info();
  for (i=0;i<sizeof(modules_t);i++)
    base64_encode_byte(*p++);

  //send module memory map
  p = (uint8_t *)_get_plc_mem_devices_struct();
  for (i=0;i<sizeof(plc_dev_t);i++)
    base64_encode_byte(*p++);

  base64_end_encode();

  _putchar('\n'); //end debug message

  uart_internals.debug_cycle_skip_count = 0;
}

bool pilot_uart_send_module_status(uint8_t module_nr, int status)
{
  char buf[30];
  if (module_nr < 4) //TODO: replace with dynamic module count
  {
    _putchars(buf, snprintf(buf, 30, ":M%d=%d\r\n", module_nr+1, status));
    return true;
  }
  return false;
}

bool pilot_uart_send_plc_state()
{
  char buf[30];
  _putchars(buf, snprintf(buf, 30, ":S=%d\r\n", plc_state));
  return true;
}

void process_uart_message()
{
  bool isOk = false;

  if (memcmp(uart_internals.cmd_rx_buf, "ECHO=", 5) == 0)
  { //echo mode
     if (memcmp(&uart_internals.cmd_rx_buf[5], "ON", 2) == 0)
     {
       uart_echo_on = true;
       isOk = true;
     }
     else if (memcmp(&uart_internals.cmd_rx_buf[5], "OFF", 3) == 0)
       {
         uart_echo_on = false;
         isOk = true;
       }
  }
  else if (uart_internals.cmd_rx_buf[0] == 'M')
  {
    uint8_t module_nr = uart_internals.cmd_rx_buf[1] - 0x30;
    if (uart_internals.cmd_rx_buf[2] == '?') 
    {
      isOk = pilot_uart_send_module_status(module_nr-1, pilot_get_module_status(module_nr-1));
    }
    else if (uart_internals.cmd_rx_buf[2] == '=')
    {
      //parse input, currently only one digit
      int new_module_status = uart_internals.cmd_rx_buf[3] - 0x30; 
      pilot_set_module_status(module_nr-1, new_module_status);
      isOk = true;
    }
  } 
  else if (uart_internals.cmd_rx_buf[0] == 'S')
  {
    if (uart_internals.cmd_rx_buf[1] == '?') 
    {
      isOk = pilot_uart_send_plc_state();
    }
    else if (uart_internals.cmd_rx_buf[1] == '=')
    {
      //TODO: parse input, currently only one digit
      int32_t new_plc_status = uart_internals.cmd_rx_buf[2] - 0x30; 
      pilot_set_plc_state(new_plc_status);
      isOk = true;
    }
  }
  
  if (!isOk)
    send_uart_data((uint8_t *)"ERR\r\n", 6);
}

void pilot_uart_comm(uint64_t cycle, uint64_t us) 
{
  //RX
  int remaining = 0, i=0;
  int cndtr = DMA1_Channel5->CNDTR;

  __disable_irq();
  while (uart_internals.uart_rx_remain != cndtr)
  {
    remaining = UART_RX_BUFFER_SIZE - uart_internals.uart_rx_remain;

    if (uart_echo_on)
      _putchar(uart_internals.uart_rx_array[remaining]);
    
    if (uart_internals.uart_rx_array[remaining] != '\n') //ignore this
    {
      if (uart_internals.uart_rx_array[remaining] == '\r') //msg complete
      {
        process_uart_message();
        uart_internals.cmd_rx_buf_index = 0;
      } 
      else if (uart_internals.cmd_rx_buf_index < UART_RX_MSG_SIZE)
      {
        uart_internals.cmd_rx_buf[uart_internals.cmd_rx_buf_index++] = uart_internals.uart_rx_array[remaining];
      }
      else
      { //overflow, reset position?
        uart_internals.cmd_rx_buf_index = 0;
      }
    }

    uart_internals.uart_rx_remain--; 
    if (uart_internals.uart_rx_remain == 0)
    {
      uart_internals.uart_rx_remain = UART_RX_BUFFER_SIZE;
    }
  } 
  __enable_irq();

  //TX
  if (uart_internals.transmitting && DMA_GetFlagStatus(DMA1_FLAG_TC4) == SET || DMA_GetFlagStatus(DMA1_FLAG_TE4)) {
    //DMA_Cmd(DMA1_Channel4, DISABLE);  //disable DMA
    DMA1_Channel4->CCR &= ~DMA_CCR1_EN;      // disable DMA
    DMA_ClearFlag(DMA1_FLAG_TE4);
  }

  if(!(DMA1_Channel4->CCR & DMA_CCR1_EN))
  {
    uart_internals.transmitting = false;
  }

  if (!uart_internals.transmitting) //not transmitting
  {
    if (uart_internals.uart_mode == 1) //uart module debug mode
    {
      send_module_debug_data(cycle, us);
    }
    else if (uart_internals.uart_mode > 1) //uart module and vars debug mode
    {
      switch (uart_internals.uart_mode_state)
      {
        case 0:
          send_module_debug_data(cycle, us);
          uart_internals.uart_mode_state = 1;
        break;
        case 1:
          send_var_debug_data(us);
          uart_internals.uart_mode_state = 0;
        break;
      }
    }
  }
  else
  { //we skip this cycle since we are still transmitting
    uart_internals.debug_cycle_skip_count++; 
  }

  //No DMA transfer in progress and data in buffer
  //if (DMA_GetFlagStatus(DMA1_FLAG_TC4) == RESET && (uart_internals.uart_tx_start != uart_internals.uart_tx_end))
  if (!uart_internals.transmitting && (uart_internals.uart_tx_start != uart_internals.uart_tx_end))
  { 

    //freebuff = _internals.uart_tx_start < _internals.uart_tx_end ? 
    //                                UART_TX_BUFFER_SIZE - (_internals.uart_tx_end-_internals.uart_tx_start) :
    //                                (_internals.uart_tx_start - _internals.uart_tx_end);
    //if (freebuff < _internals.stats.tx_buffer_min)
    //  _internals.stats.tx_buffer_min = freebuff;

    /* channel disabled and there is data to send */
    //if (!(DMA1_Channel4->CCR & DMA_CCR1_EN) && uart_internals.uart_tx_start != uart_internals.uart_tx_end)
    {
      if (uart_internals.uart_tx_start < uart_internals.uart_tx_end) //data to send (no wraparound)
        uart_internals.uart_tx_current_end = uart_internals.uart_tx_end;
      else if (uart_internals.uart_tx_start > uart_internals.uart_tx_end) //wraparound, just read to end
        uart_internals.uart_tx_current_end = UART_TX_BUFFER_SIZE;


      DMA1_Channel4->CPAR = (uint32_t)&USART1->DR;           // 1. Write USART_DR
      DMA1_Channel4->CMAR = (uint32_t)&uart_internals.uart_tx_array[uart_internals.uart_tx_start]; // 2. Write Memory address
      DMA1_Channel4->CNDTR = (uart_internals.uart_tx_current_end-uart_internals.uart_tx_start); //3. Set number of bytes to transfer

      DMA1_Channel4->CCR &= DMA_DIR_PeripheralDST | DMA_Mode_Normal |
                           DMA_PeripheralInc_Disable | DMA_MemoryInc_Enable |
                           DMA_Priority_Low | DMA_M2M_Disable;

       // Enable USART TX DMA request
       DMA_ITConfig(DMA1_Channel4, DMA_IT_TC | DMA_IT_TE, ENABLE); // 5. Configure DMA interrupt generation
       USART_ClearFlag(USART1, USART_FLAG_TC); // 6. Clear TC bit in SR register
       //DMA_Cmd(DMA1_Channel4,ENABLE); // 7. Activate channel

       DMA1_Channel4->CCR |= DMA_CCR1_EN;       // enable DMA
       uart_internals.transmitting = true;
    }
  }
}

//called by interrupt handler when TX transfer is completed
void pilot_uart_transmit_done()
{
  if (DMA_GetITStatus(DMA1_IT_TE4) != RESET) {
    DMA_ClearITPendingBit(DMA1_IT_TE4); //mark interrupt as done
  }
  if (DMA_GetITStatus(DMA1_IT_TC4) != RESET) {
    DMA_ClearITPendingBit(DMA1_IT_TC4); //mark interrupt as done
    uart_internals.uart_tx_start = uart_internals.uart_tx_current_end == UART_TX_BUFFER_SIZE ? 0 : uart_internals.uart_tx_current_end;

    DMA_Cmd(DMA1_Channel4, DISABLE);  //disable DMA

    uart_internals.transmitting = false;
    //check if we still data to send, e.g. a circular buffer wraparound
    //if (uart_internals.uart_tx_start != uart_internals.uart_tx_end) {
    //  pilot_setup_uart_tx();
    //}
  }
}

int pilot_uart_mode_get()
{
  return uart_internals.uart_mode;

}

void pilot_uart_mode_set(int mode)
{
  uart_internals.uart_mode = mode;
  void pilot_usart_init();
}

void send_uart_data(uint8_t *buf, int len)
{
  _putchar(':'); //end debug message
  for (int i=0; i < len; i++)
    _putchar(buf[i]);
  _putchar('\r'); //end debug message
  _putchar('\n'); //end debug message
}

/* END Rpi functions */
///////////////////////////////////////
