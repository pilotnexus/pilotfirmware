#include "usart.h"

$model.Usarts:{usart|

/* declare usart configuration  */
static USART_InitTypeDef m_$usart.Name$;

static void rpc_$usart.Name$_configure_clocks()
{
#ifdef STM32F4XX
  RCC_AHB$usart.AHB$PeriphClockCmd( RCC_AHB$usart.RxAHB$Periph_$usart.RxGPIO$, ENABLE);
  RCC_AHB$usart.AHB$PeriphClockCmd( RCC_AHB$usart.TxAHB$Periph_$usart.TxGPIO$, ENABLE);
#else
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_$usart.RxGPIO$, ENABLE);
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_$usart.TxGPIO$, ENABLE);
#endif
  RCC_APB$usart.APB$PeriphClockCmd( RCC_APB$usart.APB$Periph_$usart.Name$, ENABLE);
\}

static void rpc_$usart.Name$_connect_usart_pins()
{
#ifdef STM32F4XX
  GPIO_PinAFConfig($usart.RxGPIO$, $usart.RxPinSource$, GPIO_AF_$usart.Name$);
  GPIO_PinAFConfig($usart.TxGPIO$, $usart.TxPinSource$, GPIO_AF_$usart.Name$);
#endif
\}

static void rpc_$usart.Name$_configure_gpios()
{
  /* configure gpios */
  GPIO_InitTypeDef inputs, outputs;
  GPIO_StructInit(&inputs);
  GPIO_StructInit(&outputs);

  /* configure Rx as input floating */
  inputs.GPIO_Pin = $usart.RxPin$;
#ifdef STM32F4XX
  inputs.GPIO_Mode = GPIO_Mode_AF;
  inputs.GPIO_OType = GPIO_OType_PP;
  inputs.GPIO_PuPd = GPIO_PuPd_UP;
  inputs.GPIO_Speed = GPIO_Speed_50MHz;
#else
  inputs.GPIO_Mode = GPIO_Mode_IN_FLOATING;
#endif
  GPIO_Init($usart.RxGPIO$, &inputs);

  /* configure Tx as output */
  outputs.GPIO_Pin = $usart.TxPin$;
  outputs.GPIO_Speed = GPIO_Speed_50MHz;
#ifdef STM32F4XX
  outputs.GPIO_Mode = GPIO_Mode_AF;
  outputs.GPIO_OType= GPIO_OType_PP;
  outputs.GPIO_PuPd = GPIO_PuPd_UP;
#else
  outputs.GPIO_Mode = GPIO_Mode_AF_PP;
#endif
  GPIO_Init($usart.TxGPIO$, &outputs);
\}

static void rpc_$usart.Name$_configure()
{
  USART_Init($usart.Name$, &m_$usart.Name$);
  USART_Cmd($usart.Name$, ENABLE);
\}

static void rpc_$usart.Name$_configure_init()
{
  /* initialize the USART struct */
  m_$usart.Name$.USART_BaudRate            = 9600;
  m_$usart.Name$.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  m_$usart.Name$.USART_Mode                = USART_Mode_Tx | USART_Mode_Rx;
  m_$usart.Name$.USART_Parity              = USART_Parity_No;
  m_$usart.Name$.USART_StopBits            = USART_StopBits_1;
  m_$usart.Name$.USART_WordLength          = USART_WordLength_8b;

  /* apply the configuration */
  rpc_$usart.Name$_configure();
\}

static void rpc_$usart.Name$_configure_interrupt()
{
  NVIC_InitTypeDef nvic;

  /* enable interrupt */
  nvic.NVIC_IRQChannel                   = $usart.Name$_IRQn;
  nvic.NVIC_IRQChannelPreemptionPriority = 0x00;
  nvic.NVIC_IRQChannelSubPriority        = 0x01;
  nvic.NVIC_IRQChannelCmd                = ENABLE;
  NVIC_Init(&nvic);
   
  /* enable USART interrupt for receive not empty */
  USART_ITConfig($usart.Name$, USART_IT_RXNE, ENABLE);
\}

uint8_t rpc_$usart.Name$_receive_char()
{
  uint8_t recv = (uint8_t) USART_ReceiveData($usart.Name$);

  /* strip the parity bit */
  if (m_$usart.Name$.USART_WordLength == USART_WordLength_8b &&
      m_$usart.Name$.USART_Parity     != USART_Parity_No)
    recv &= 0x7f;

  return recv;
\}

void rpc_$usart.Name$_send_char(char c)
{
  USART_SendData($usart.Name$, c);
  while (USART_GetFlagStatus($usart.Name$, USART_FLAG_TXE) == RESET);
\}

void rpc_$usart.Name$_set_baudrate(int baudrate)
{
  m_$usart.Name$.USART_BaudRate = baudrate;
  rpc_$usart.Name$_configure();
\}

void rpc_$usart.Name$_set_stopbits(uint16_t stopbits)
{
  m_$usart.Name$.USART_StopBits = stopbits;
  rpc_$usart.Name$_configure();
\}

void rpc_$usart.Name$_set_parity(uint16_t parity)
{
  m_$usart.Name$.USART_Parity = parity;
  rpc_$usart.Name$_configure();
\}

void rpc_$usart.Name$_set_wordlength(uint16_t wordlength)
{
  m_$usart.Name$.USART_WordLength = wordlength;
  rpc_$usart.Name$_configure();
\}

void rpc_$usart.Name$_init()
{
  rpc_$usart.Name$_configure_clocks();
  rpc_$usart.Name$_connect_usart_pins();
  rpc_$usart.Name$_configure_gpios();
  rpc_$usart.Name$_configure_init();
  rpc_$usart.Name$_configure_interrupt();
\}

};separator="\n"$
