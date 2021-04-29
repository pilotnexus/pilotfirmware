#include "o8.h"

#define o8_get_state(state,i) (state & (1 << i))

$model.o8s:{o8|

static void pilot_$o8.Name$_configure_clocks()
{
  /* enable gpio clocks for all pins */

#ifdef STM32F4XX
  $o8.Outputs:{p|RCC_AHB$p.AHB$PeriphClockCmd(RCC_AHB$p.AHB$Periph_$p.GPIO$, ENABLE);};separator="\n"$
#else
  $o8.Outputs:{p|RCC_APB$p.APB$PeriphClockCmd(RCC_APB$p.APB$Periph_$p.GPIO$, ENABLE);};separator="\n"$
#endif
\}

static void pilot_$o8.Name$_configure_gpios()
{
  GPIO_InitTypeDef outputs;

  outputs.GPIO_Speed = GPIO_Speed_50MHz;

#ifdef STM32F4XX
  outputs.GPIO_Mode  = GPIO_Mode_OUT;
  outputs.GPIO_OType = GPIO_OType_PP;
  outputs.GPIO_PuPd  = GPIO_PuPd_UP;
#else
  outputs.GPIO_Mode = GPIO_Mode_Out_PP;
#endif

$o8.Outputs:{p|
  outputs.GPIO_Pin = $p.Pin$;
  GPIO_Init($p.GPIO$, &outputs);
  };separator="\n"$
\}

/* initializes the o8 module */
int pilot_$o8.Name$_init()
{
  pilot_$o8.Name$_configure_clocks();
  pilot_$o8.Name$_configure_gpios();
  return 0;
\}

int pilot_$o8.Name$_check()
{
  return 0;
\}


/* send the state of the output to the rpi */
uint8_t pilot_$o8.Name$_get_value(uint8_t output)
{
  uint8_t state = 0;
  switch (output)
  {
    $o8.Outputs:{output| case $output.Index$: state = GPIO_ReadOutputDataBit($output.GPIO$, $output.Pin$); break; };separator="\n"$
  \}
  return state;
\}

void pilot_$o8.Name$_set_value(uint8_t output, bool value)
{
  switch (output)
  {
    $o8.Outputs:{output| case $output.Index$: GPIO_WriteBit($output.GPIO$, $output.Pin$, value ? Bit_SET : Bit_RESET); break;};separator="\n"$
  \}
\}

$if(model.PLC)$
void $o8.Name$_plc_write(unsigned char *target)
{
    $o8.Outputs:{output| GPIO_WriteBit($output.GPIO$, $output.Pin$, (*target & (1 << $i0$)) ? Bit_SET : Bit_RESET); };separator="\n"$
\}
$endif$

};separator="\n"$
