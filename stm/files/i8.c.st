#include "i8.h"

#define i8_get_state(state,i) (state & (1 << i))

$model.I8s:{i8|

static void $i8.Name$_configure_clocks()
{
  /* enable gpio clocks for all pins */

#ifdef STM32F4XX
  $i8.Inputs:{p|RCC_AHB$p.AHB$PeriphClockCmd(RCC_AHB$p.AHB$Periph_$p.GPIO$, ENABLE);};separator="\n"$
#else
  $i8.Inputs:{p|RCC_APB$p.APB$PeriphClockCmd(RCC_APB$p.APB$Periph_$p.GPIO$, ENABLE);};separator="\n"$
#endif
\}

static void $i8.Name$_configure_gpios()
{
  GPIO_InitTypeDef inputs;

  inputs.GPIO_Speed = GPIO_Speed_50MHz;

#ifdef STM32F4XX
  inputs.GPIO_Mode  = GPIO_Mode_IN;
  inputs.GPIO_OType = GPIO_OType_OD;
#else
  inputs.GPIO_Mode = GPIO_Mode_IN_FLOATING;
#endif

$i8.Inputs:{p|
  inputs.GPIO_Pin = $p.Pin$;
  GPIO_Init($p.GPIO$, &inputs);
  };separator="\n"$
\}

/* initializes the i8 module */
void pilot_$i8.Name$_init()
{
  $i8.Name$_configure_clocks();
  $i8.Name$_configure_gpios();
\}

/* send the state of the input to the rpi */
uint8_t $i8.Name$_get_state(uint8_t input)
{
  uint8_t state = 0;
  switch (input)
  {
    $i8.Inputs:{input| case $input.Index$: state = GPIO_ReadInputDataBit($input.GPIO$, $input.Pin$); break; };separator="\n"$
  \}
  return state;
\}

$if(model.PLC)$
void $i8.Name$_plc_read(unsigned char *target)
{
    *target = 0;
    $i8.Inputs:{input| *target |= GPIO_ReadInputDataBit($input.GPIO$, $input.Pin$) << $i0$; };separator="\n"$
\}
$endif$

};separator="\n"$
