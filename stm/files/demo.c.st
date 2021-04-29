#include "demo.h"

#define demo_get_state(state,i) (state & (1 << i))

$model.Demos:{demo|

static void $demo.Name$_configure_clocks()
{
  /* enable gpio clocks for all pins */

#ifdef STM32F4XX
  $demo.Inputs:{p|RCC_AHB$p.AHB$PeriphClockCmd(RCC_AHB$p.AHB$Periph_$p.GPIO$, ENABLE);};separator="\n"$
#else
  $demo.Inputs:{p|RCC_APB$p.APB$PeriphClockCmd(RCC_APB$p.APB$Periph_$p.GPIO$, ENABLE);};separator="\n"$
#endif

#ifdef STM32F4XX
  $demo.Outputs:{p|RCC_AHB$p.AHB$PeriphClockCmd(RCC_AHB$p.AHB$Periph_$p.GPIO$, ENABLE);};separator="\n"$
#else
  $demo.Outputs:{p|RCC_APB$p.APB$PeriphClockCmd(RCC_APB$p.APB$Periph_$p.GPIO$, ENABLE);};separator="\n"$
#endif
\}

static void $demo.Name$_configure_gpios()
{
  GPIO_InitTypeDef inputs;
  inputs.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitTypeDef outputs;
  outputs.GPIO_Speed = GPIO_Speed_50MHz;
  
#ifdef STM32F4XX
  inputs.GPIO_Mode  = GPIO_Mode_IN;
  inputs.GPIO_OType = GPIO_OType_OD;
#else
  inputs.GPIO_Mode = GPIO_Mode_IN_FLOATING;
#endif

$demo.Inputs:{p|
  inputs.GPIO_Pin = $p.Pin$;
  GPIO_Init($p.GPIO$, &inputs);
  };separator="\n"$


#ifdef STM32F4XX
  outputs.GPIO_Mode  = GPIO_Mode_OUT;
  outputs.GPIO_OType = GPIO_OType_PP;
  outputs.GPIO_PuPd  = GPIO_PuPd_UP;
#else
  outputs.GPIO_Mode = GPIO_Mode_Out_PP;
#endif

$demo.Outputs:{p|
  outputs.GPIO_Pin = $p.Pin$;
  GPIO_Init($p.GPIO$, &outputs);
  };separator="\n"$
\}

/* initializes the demo module */
int pilot_$demo.Name$_init()
{
  $demo.Name$_configure_clocks();
  $demo.Name$_configure_gpios();
  return 0;
\}

int pilot_$demo.Name$_check()
{
  return 0;
\}

/* send the state of the input to the rpi */
uint8_t pilot_$demo.Name$_get_state(uint8_t input)
{
  uint8_t state = 0;
  switch (input)
  {
    $demo.Inputs:{input| case $input.Index$: state = GPIO_ReadInputDataBit($input.GPIO$, $input.Pin$); break; };separator="\n"$
  \}
  return state;
\}

/* send the state of the output to the rpi */
uint8_t pilot_$demo.Name$_get_value(uint8_t output)
{
  uint8_t state = 0;
  switch (output)
  {
    $demo.Outputs:{output| case $output.Index$: state = GPIO_ReadOutputDataBit($output.GPIO$, $output.Pin$); break; };separator="\n"$
  \}
  return state;
\}

void pilot_$demo.Name$_set_value(uint8_t output, bool value)
{
  switch (output)
  {
    $demo.Outputs:{output| case $output.Index$: GPIO_WriteBit($output.GPIO$, $output.Pin$, value ? Bit_SET : Bit_RESET); break;};separator="\n"$
  \}
\}

$if(model.PLC)$
void $demo.Name$_plc_read(unsigned char *target)
{
    *target = 0;
    $demo.Inputs:{input| *target |= GPIO_ReadInputDataBit($input.GPIO$, $input.Pin$) << $i0$; };separator="\n"$
\}
$endif$

$if(model.PLC)$
void $demo.Name$_plc_write(unsigned char *target)
{
    $demo.Outputs:{output| GPIO_WriteBit($output.GPIO$, $output.Pin$, (*target & (1 << $i0$)) ? Bit_SET : Bit_RESET); };separator="\n"$
\}
$endif$
};separator="\n"$
