#include "onewire.h"

$model.OneWires: {ow|

void rpc_$ow.Name$_init_clocks()
{
  /* enable the gpio clocks */
#ifdef STM32F4XX
  RCC_AHB$ow.AHB$PeriphClockCmd(RCC_AHB$ow.AHB$Periph_$ow.EnableGpio$, ENABLE);
#else
  RCC_APB$ow.APB$PeriphClockCmd(RCC_APB$ow.APB$Periph_$ow.EnableGpio$, ENABLE);
#endif
\}

void rpc_$ow.Name$_init_gpio()
{
  GPIO_InitTypeDef gpio;

  /* configure ENABLE pin as Output  */
  gpio.GPIO_Pin = $ow.EnablePin$;
#ifdef STM32F4XX
  gpio.GPIO_Mode = GPIO_Mode_OUT;
  gpio.GPIO_OType = GPIO_OType_PP;
  gpio.GPIO_PuPd = GPIO_PuPd_UP;
  gpio.GPIO_Speed = GPIO_Speed_100MHz;
#else
  gpio.GPIO_Mode = GPIO_Mode_Out_PP;
  gpio.GPIO_Speed = GPIO_Speed_50MHz;
#endif
  GPIO_Init($ow.EnableGpio$, &gpio);

\}

void rpc_$ow.Name$_init() 
{
  /* enable the clocks */
  rpc_$ow.Name$_init_clocks();

  /* initialize the ENABLE pin */
  rpc_$ow.Name$_init_gpio();

  /* enable the one wire module */
  rpc_$ow.Name$_set_enable(1);
\}

void rpc_$ow.Name$_set_enable(int enable)
{
  GPIO_WriteBit($ow.EnableGpio$, $ow.EnablePin$, enable ? Bit_SET : Bit_RESET);
\}

int rpc_$ow.Name$_get_enable()
{
  return (GPIO_ReadOutputDataBit($ow.EnableGpio$, $ow.EnablePin$) == Bit_SET) ? 1 : 0;
\}

};separator="\n"$
