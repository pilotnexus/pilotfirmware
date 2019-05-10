#include "test.h"
#include "delay.h"
#include <stdio.h>
#include <stm32_conf.h>

$if(model.IsTest)$

/* output delay in ms */
#define OUTPUT_DELAY 1

static void rpcp_test_clocks_init()
{
  /* initialize the clocks */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOC, ENABLE);
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOD, ENABLE);
}

static void rpcp_test_gpios_init_input(GPIO_TypeDef *gpioX, uint16_t pin)
{
  GPIO_InitTypeDef inputs;
  inputs.GPIO_Pin = pin;
  inputs.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_Init(gpioX, &inputs);
}

static void rpcp_test_gpios_init_output(GPIO_TypeDef *gpioX, uint16_t pin)
{
  GPIO_InitTypeDef outputs;
  outputs.GPIO_Pin = pin;
  outputs.GPIO_Speed = GPIO_Speed_50MHz;
  outputs.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(gpioX, &outputs);

  /* start with the output on low */
  GPIO_WriteBit(gpioX, pin, Bit_RESET);
}

static void rpcp_test_gpios_init()
{
  /* initializes the outputs */
  rpcp_test_gpios_init_output(GPIOA, GPIO_Pin_0);
  rpcp_test_gpios_init_output(GPIOA, GPIO_Pin_1);
  rpcp_test_gpios_init_output(GPIOA, GPIO_Pin_2);
  rpcp_test_gpios_init_output(GPIOA, GPIO_Pin_3);
  rpcp_test_gpios_init_output(GPIOA, GPIO_Pin_4);
  rpcp_test_gpios_init_output(GPIOA, GPIO_Pin_8);
  rpcp_test_gpios_init_output(GPIOA, GPIO_Pin_11);
  rpcp_test_gpios_init_output(GPIOA, GPIO_Pin_12);
  rpcp_test_gpios_init_output(GPIOB, GPIO_Pin_0);

  /* initialize the inputs */
  rpcp_test_gpios_init_input(GPIOB, GPIO_Pin_1);
  rpcp_test_gpios_init_input(GPIOB, GPIO_Pin_5);
  rpcp_test_gpios_init_input(GPIOB, GPIO_Pin_6);
  rpcp_test_gpios_init_input(GPIOB, GPIO_Pin_7);
  rpcp_test_gpios_init_input(GPIOB, GPIO_Pin_8);
  rpcp_test_gpios_init_input(GPIOB, GPIO_Pin_9);
  rpcp_test_gpios_init_input(GPIOB, GPIO_Pin_10);

  /* test module slot 3 & 4 */

  /* initialize the outputs */
  rpcp_test_gpios_init_output(GPIOB, GPIO_Pin_11);
  rpcp_test_gpios_init_output(GPIOB, GPIO_Pin_12);
  rpcp_test_gpios_init_output(GPIOB, GPIO_Pin_13);
  rpcp_test_gpios_init_output(GPIOB, GPIO_Pin_14);
  rpcp_test_gpios_init_output(GPIOB, GPIO_Pin_15);
  rpcp_test_gpios_init_output(GPIOC, GPIO_Pin_4);
  rpcp_test_gpios_init_output(GPIOC, GPIO_Pin_5);
  rpcp_test_gpios_init_output(GPIOC, GPIO_Pin_6);
  rpcp_test_gpios_init_output(GPIOC, GPIO_Pin_7);

  /* inputs for test */
  rpcp_test_gpios_init_input(GPIOC, GPIO_Pin_8);
  rpcp_test_gpios_init_input(GPIOC, GPIO_Pin_9);
  rpcp_test_gpios_init_input(GPIOC, GPIO_Pin_10);
  rpcp_test_gpios_init_input(GPIOC, GPIO_Pin_11);
  rpcp_test_gpios_init_input(GPIOC, GPIO_Pin_12);
  rpcp_test_gpios_init_input(GPIOC, GPIO_Pin_13);
  rpcp_test_gpios_init_input(GPIOD, GPIO_Pin_2);
}

void rpcp_test_init()
{
  /* initialize the clocks */
  rpcp_test_clocks_init();

  /* initialize the gpios */
  rpcp_test_gpios_init();
}

typedef enum {
  pin_result_success = 0,
  pin_result_failed_low = 1,
  pin_result_failed_high = 2
} pin_result_t;

static pin_result_t rpcp_test_pins(GPIO_TypeDef* GPIOx_output, uint16_t GPIO_Pin_output,
                                   GPIO_TypeDef* GPIOx_input,  uint16_t GPIO_Pin_input)
{
  pin_result_t result = pin_result_success;

  /* set the output low */
  GPIO_WriteBit(GPIOx_output, GPIO_Pin_output, Bit_RESET);

  /* wait for the output to settle */
  rpcp_delay_ms(OUTPUT_DELAY);

  /* check if the input matches the output */
  if (GPIO_ReadInputDataBit(GPIOx_input, GPIO_Pin_input) != 0)
    result = pin_result_failed_low;
  else
  {
    /* set the output high */
    GPIO_WriteBit(GPIOx_output, GPIO_Pin_output, Bit_SET);

    /* wait for the output to settle */
    rpcp_delay_ms(OUTPUT_DELAY);

    /* expect the input to be high as well */
    if (GPIO_ReadInputDataBit(GPIOx_input, GPIO_Pin_input) != 1)
      result = pin_result_failed_high;
  }

  /* reset the gpio again */
  GPIO_WriteBit(GPIOx_output, GPIO_Pin_output, Bit_RESET);

  return result;
}

static pin_result_t rpcp_test_pins_combined(GPIO_TypeDef* GPIOx_output1, uint16_t GPIO_Pin_output1,
                                            GPIO_TypeDef* GPIOx_output2, uint16_t GPIO_Pin_output2,
                                            GPIO_TypeDef* GPIOx_output3, uint16_t GPIO_Pin_output3,
                                            GPIO_TypeDef* GPIOx_combined_input, uint16_t GPIO_Pin_combined_input)
{
  /* set all outputs low */
  GPIO_WriteBit(GPIOx_output1, GPIO_Pin_output1, Bit_RESET);
  GPIO_WriteBit(GPIOx_output2, GPIO_Pin_output2, Bit_RESET);
  GPIO_WriteBit(GPIOx_output3, GPIO_Pin_output3, Bit_RESET);

  /* wait for the output to settle */
  rpcp_delay_ms(OUTPUT_DELAY);

  /* check if the input matches the output pins */
  if (GPIO_ReadInputDataBit(GPIOx_combined_input, GPIO_Pin_combined_input) != 0)
    return pin_result_failed_low;

  /* set all outputs high */
  GPIO_WriteBit(GPIOx_output1, GPIO_Pin_output1, Bit_SET);
  GPIO_WriteBit(GPIOx_output2, GPIO_Pin_output2, Bit_SET);
  GPIO_WriteBit(GPIOx_output3, GPIO_Pin_output3, Bit_SET);

  /* wait for the output to settle */
  rpcp_delay_ms(OUTPUT_DELAY);

  /* check if the input matches the output pins */
  if (GPIO_ReadInputDataBit(GPIOx_combined_input, GPIO_Pin_combined_input) != 1)
    return pin_result_failed_high;

  /* now check all pins individually by turning them off */

  /* check output 1 */
  GPIO_WriteBit(GPIOx_output1, GPIO_Pin_output1, Bit_RESET); /* set the output low */
  rpcp_delay_ms(OUTPUT_DELAY);
  if (GPIO_ReadInputDataBit(GPIOx_combined_input, GPIO_Pin_combined_input) != 0) /* check if the input also turned low */
    return pin_result_failed_low;
  GPIO_WriteBit(GPIOx_output1, GPIO_Pin_output1, Bit_SET); /* set the output high again */

  /* check output 2 */
  GPIO_WriteBit(GPIOx_output2, GPIO_Pin_output2, Bit_RESET); /* set the output low */
  rpcp_delay_ms(OUTPUT_DELAY);
  if (GPIO_ReadInputDataBit(GPIOx_combined_input, GPIO_Pin_combined_input) != 0) /* check if the input also turned low */
    return pin_result_failed_low;
  GPIO_WriteBit(GPIOx_output2, GPIO_Pin_output2, Bit_SET); /* set the output high again */

  /* check output 3 */
  GPIO_WriteBit(GPIOx_output3, GPIO_Pin_output3, Bit_RESET); /* set the output low */
  rpcp_delay_ms(OUTPUT_DELAY);
  if (GPIO_ReadInputDataBit(GPIOx_combined_input, GPIO_Pin_combined_input) != 0) /* check if the input also turned low */
    return pin_result_failed_low;
  GPIO_WriteBit(GPIOx_output3, GPIO_Pin_output3, Bit_SET); /* set the output high again */

  return pin_result_success;
}

static void rpcp_test_update_result(pin_result_t pin_result, testresult_t *result)
{
  /* keep track of the index of the first item that failed */
  if (pin_result != pin_result_success && result->count_failed == 0)
    result->index_failed = result->count_tested;

  result->count_tested++;

  if (pin_result != pin_result_success)
    result->count_failed++;

  switch (pin_result)
  {
    case pin_result_success:
      result->count_success++;
      break;

    case pin_result_failed_low:
      result->count_failed_low++;
      break;

    case pin_result_failed_high:
      result->count_failed_high++;
      break;
  }
}

/* returns true if all tests succeeded, otherwise false */
bool rpcp_test_run(testresult_t *result)
{
  /* clear the result */
  memset(result, 0, sizeof(testresult_t));

  /* test module slot 1 & 2 */
  
  /* PA_0 -> PB_1 */
  rpcp_test_update_result(rpcp_test_pins(GPIOA, GPIO_Pin_0,
                                         GPIOB, GPIO_Pin_1), result);

  /* PA_1 -> PB_5 */
  rpcp_test_update_result(rpcp_test_pins(GPIOA, GPIO_Pin_1,
                                         GPIOB, GPIO_Pin_5), result);

  /* PA_2 -> PB_6 */
  rpcp_test_update_result(rpcp_test_pins(GPIOA, GPIO_Pin_2,
                                         GPIOB, GPIO_Pin_6), result);

  /* PA_3 -> PB_7 */
  rpcp_test_update_result(rpcp_test_pins(GPIOA, GPIO_Pin_3,
                                         GPIOB, GPIO_Pin_7), result);

  /* PA_4 -> PB_8 */
  rpcp_test_update_result(rpcp_test_pins(GPIOA, GPIO_Pin_4,
                                         GPIOB, GPIO_Pin_8), result);

  /* PA_8 -> PB_9 */
  rpcp_test_update_result(rpcp_test_pins(GPIOA, GPIO_Pin_8,
                                         GPIOB, GPIO_Pin_9), result);

  /* PA_11 & PA_12 & PB_0 => PB_10*/
  rpcp_test_update_result(rpcp_test_pins_combined(GPIOA, GPIO_Pin_11,
                                                  GPIOA, GPIO_Pin_12,
                                                  GPIOB, GPIO_Pin_0,
                                                  GPIOB, GPIO_Pin_10), result);

  /* test module slot 3 & 4 */

  /* PB_11 -> PC_8 */
  rpcp_test_update_result(rpcp_test_pins(GPIOB, GPIO_Pin_11,
                                         GPIOC, GPIO_Pin_8), result);

  /* PB_12 -> PC_9 */
  rpcp_test_update_result(rpcp_test_pins(GPIOB, GPIO_Pin_12,
                                         GPIOC, GPIO_Pin_9), result);

  /* PB_13 -> PC_10 */
  rpcp_test_update_result(rpcp_test_pins(GPIOB, GPIO_Pin_13,
                                         GPIOC, GPIO_Pin_10), result);

  /* PB_14 -> PC_11 */
  rpcp_test_update_result(rpcp_test_pins(GPIOB, GPIO_Pin_14,
                                         GPIOC, GPIO_Pin_11), result);

  /* PB_15 -> PC_12 */
  rpcp_test_update_result(rpcp_test_pins(GPIOB, GPIO_Pin_15,
                                         GPIOC, GPIO_Pin_12), result);

  /* PC_4 -> PC_13 */
  rpcp_test_update_result(rpcp_test_pins(GPIOC, GPIO_Pin_4,
                                         GPIOC, GPIO_Pin_13), result);

  /* PC_5 & PC_6 & PC_7 => PD_2 */
  rpcp_test_update_result(rpcp_test_pins_combined(GPIOC, GPIO_Pin_5,
                                                  GPIOC, GPIO_Pin_6,
                                                  GPIOC, GPIO_Pin_7,
                                                  GPIOD, GPIO_Pin_2), result);

  return result->count_failed == 0;
}

$endif$