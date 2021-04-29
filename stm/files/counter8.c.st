#include "counter8.h"

typedef struct {
  uint64_t counters[COUNTERS_COUNT]; /* the counters value */
} internals_counter_t;

static internals_counter_t _internals = {0};

$model.counter8s:{counter8|

static void pilot_$counter8.Name$_configure_clocks()
{
#ifdef STM32F4XX
  /* enable gpio clocks for all pins */
  $counter8.Inputs:{p|RCC_AHB$p.AHB$PeriphClockCmd(RCC_AHB$p.AHB$Periph_$p.GPIO$, ENABLE);};separator="\n"$

  /* enable syscfg clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_SYSCFG, ENABLE);

#else

  /* enable the gpio clocks for all pins */
  $counter8.Inputs:{p|RCC_APB$p.APB$PeriphClockCmd(RCC_APB$p.APB$Periph_$p.GPIO$, ENABLE);};separator="\n"$

#endif

\}

static void pilot_$counter8.Name$_configure_gpios()
{
  GPIO_InitTypeDef inputs;

#ifdef STM32F4XX
  inputs.GPIO_Mode  = GPIO_Mode_IN;
  inputs.GPIO_OType = GPIO_OType_OD;
#else
  inputs.GPIO_Mode = GPIO_Mode_IN_FLOATING;
#endif

  inputs.GPIO_Speed = GPIO_Speed_50MHz;

$counter8.Inputs:{p|
  inputs.GPIO_Pin = $p.Pin$;
  GPIO_Init($p.GPIO$, &inputs);
  };separator="\n"$
\}

static void pilot_$counter8.Name$_configure_exti()
{
  EXTI_InitTypeDef exti;

$counter8.Inputs:{p|
  /* connect exti line */
#ifdef STM32F4XX
  SYSCFG_EXTILineConfig(EXTI_PortSource$p.GPIO$, $p.ExtiPinSource$);
#else
  GPIO_EXTILineConfig(GPIO_PortSource$p.GPIO$, $p.GpioPinSource$);
#endif

  /* configure the exti line */
  exti.EXTI_Line    = $p.ExtiLine$;
  exti.EXTI_Mode    = EXTI_Mode_Interrupt;
  exti.EXTI_Trigger = EXTI_Trigger_Rising_Falling;
  exti.EXTI_LineCmd = ENABLE;
  EXTI_Init(&exti);
};separator="\n"$

\}

static void pilot_$counter8.Name$_configure_nvic()
{
  /* enable and set EXTI Line Interrupt */
  NVIC_InitTypeDef nvic;

$counter8.Inputs:{p|
  nvic.NVIC_IRQChannel                   = $p.ExtiIrqChannel$;
  nvic.NVIC_IRQChannelPreemptionPriority = 0x00;
  nvic.NVIC_IRQChannelSubPriority        = 0x0F;
  nvic.NVIC_IRQChannelCmd                = ENABLE;
  NVIC_Init(&nvic);
};separator="\n"$

\}

/* initializes the counter8 module */
int pilot_$counter8.Name$_init()
{
  pilot_$counter8.Name$_configure_clocks();
  pilot_$counter8.Name$_configure_gpios();
  pilot_$counter8.Name$_configure_exti();
  pilot_$counter8.Name$_configure_nvic();
  return 0;
\}

int pilot_$counter8.Name$_check()
{
  return 0;
\}

/* fills the supplied cmd */
void pilot_$counter8.Name$_get_counter_cmd(pilot_cmd_t* cmd, int counter_index)
{
  uint64_t counter_value = _internals.counters[counter_index];

  /* clear the cmd */
  memset(cmd, 0, sizeof(pilot_cmd_t));

  cmd->target = target_t_from_module_slot_and_port((module_slot_t)$counter8.Slot$, module_port_1);
  cmd->type   = pilot_cmd_type_input_get_counter;

  /* the first data byte is set to the counter_index */
  cmd->data[pilot_counter_index_target] = (spidata_t)counter_index; 

  /* encode the counter value in the last 7 bytes */
  cmd->data[pilot_counter_index_value + 0] = (counter_value >> (6*8)) & 0xFF;
  cmd->data[pilot_counter_index_value + 1] = (counter_value >> (5*8)) & 0xFF;
  cmd->data[pilot_counter_index_value + 2] = (counter_value >> (4*8)) & 0xFF;
  cmd->data[pilot_counter_index_value + 3] = (counter_value >> (3*8)) & 0xFF;
  cmd->data[pilot_counter_index_value + 4] = (counter_value >> (2*8)) & 0xFF;
  cmd->data[pilot_counter_index_value + 5] = (counter_value >> (1*8)) & 0xFF;
  cmd->data[pilot_counter_index_value + 6] = (counter_value >> (0*8)) & 0xFF;
  cmd->length = MSG_LEN(8);
\}

void pilot_$counter8.Name$_set_counter(int counter_index, uint64_t value)
{
  _internals.counters[counter_index] = value;
\}

/* increment the counter */
void pilot_$counter8.Name$_increment_counter(int counter_index)
{
  _internals.counters[counter_index]++;
\}

};separator="\n"$

void pilot_counter8_set_counter(pilot_cmd_t* cmd)
{
  int i;
  pilot_counter_target_t counter_target;
  uint64_t counter_value = 0;

  counter_target = (pilot_counter_target_t)cmd->data[pilot_counter_index_target];  /* get the targetted counter */

  /* get the new value of the counter */
  counter_value = (((uint64_t)cmd->data[pilot_counter_index_value + 0]) << 6*8)
                | (((uint64_t)cmd->data[pilot_counter_index_value + 1]) << 5*8)
                | (((uint64_t)cmd->data[pilot_counter_index_value + 2]) << 4*8)
                | (((uint64_t)cmd->data[pilot_counter_index_value + 3]) << 3*8)
                | (((uint64_t)cmd->data[pilot_counter_index_value + 4]) << 2*8)
                | (((uint64_t)cmd->data[pilot_counter_index_value + 5]) << 1*8)
                | (((uint64_t)cmd->data[pilot_counter_index_value + 6]) << 0*8);

  /* if we're setting all counters */
  if (counter_target == pilot_counter_target_all)
  {
    for (i = 0; i < COUNTERS_COUNT; i++)
    {
      _internals.counters[i] = counter_value;
    }
  }
  /* if we're setting a single counter, do a sanity check */
  else if ((int)counter_target >= 0 && counter_target < COUNTERS_COUNT)
  {
    _internals.counters[counter_target] = counter_value;
  }
}

