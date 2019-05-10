#include "pwm.h"

$model.Pwms:{pwm|

static void $pwm.Name$_configure_clock()
{
#ifdef STM32F4XX
  RCC_AHB$pwm.AHB$PeriphClockCmd(RCC_AHB$pwm.AHB$Periph_$pwm.GPIO$, ENABLE);
#else
  RCC_APB$pwm.APB$PeriphClockCmd(RCC_APB$pwm.APB$Periph_$pwm.GPIO$, ENABLE);
#endif
\}

static void $pwm.Name$_configure_gpio()
{
  GPIO_InitTypeDef gpio;

  gpio.GPIO_Pin   = GPIO_Pin_13;
#ifdef STM32F4XX
  gpio.GPIO_Mode  = GPIO_Mode_AF;
  gpio.GPIO_Speed = GPIO_Speed_100MHz;
  gpio.GPIO_OType = GPIO_OType_PP;
  gpio.GPIO_PuPd  = GPIO_PuPd_UP;
#else
  gpio.GPIO_Mode = GPIO_Mode_AF_PP;
  gpio.GPIO_Speed = GPIO_Speed_50MHz;
#endif
  
  /* apply the settings */
  GPIO_Init($pwm.GPIO$, &gpio);

#ifdef STM32F4XX
  /* configure the alternate function timer 1 for this gpio */
  GPIO_PinAFConfig($pwm.GPIO$, $pwm.PinSource$, GPIO_AF_$pwm.TIM$);
#endif
\}

static void $pwm.Name$_configure_tim()
{
  uint16_t timerPeriod, channel1Pulse;
  TIM_TimeBaseInitTypeDef time_base;
  TIM_OCInitTypeDef time_c;

  /* Compute the value to be set in ARR register to generate signal frequency at 100 Khz */
  timerPeriod = (SystemCoreClock / 500000 ) -1;

  /* Compute CCR1 value to generate a duty cycle at 50% for channel 1 and 1N */
  channel1Pulse = (uint16_t) (((uint32_t) 5 * (timerPeriod - 1)) / 10);

  /* enable $pwm.TIM$ clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_$pwm.TIM$, ENABLE);

  /* create the base settings */
  time_base.TIM_Prescaler         = 0;
  time_base.TIM_CounterMode       = TIM_CounterMode_Up;
  time_base.TIM_Period            = timerPeriod;
  time_base.TIM_ClockDivision     = 0;
  time_base.TIM_RepetitionCounter = 0;

  /* apply the Time Base settings */
  TIM_TimeBaseInit($pwm.TIM$, &time_base);

  /* create the settings for channel 1 */
  time_c.TIM_OCMode       = TIM_OCMode_PWM1;
  time_c.TIM_OutputState  = TIM_OutputState_Enable;
  time_c.TIM_OutputNState = TIM_OutputNState_Enable;
  time_c.TIM_Pulse        = channel1Pulse;
  time_c.TIM_OCPolarity   = TIM_OCPolarity_Low;
  time_c.TIM_OCNPolarity  = TIM_OCNPolarity_High;
  time_c.TIM_OCIdleState  = TIM_OCIdleState_Set;
  time_c.TIM_OCNIdleState = TIM_OCIdleState_Reset;

  /* apply the Channel1 settings */
  TIM_OC1Init($pwm.TIM$, &time_c);

  /* enable the $pwm.TIM$ counter */
  TIM_Cmd($pwm.TIM$, ENABLE);

  /* enable the $pwm.TIM$ main output */
  TIM_CtrlPWMOutputs($pwm.TIM$, ENABLE);
\}

void $pwm.Name$_init()
{
  $pwm.Name$_configure_clock();
  $pwm.Name$_configure_gpio();
  $pwm.Name$_configure_tim();
\}

};separator="\n"$