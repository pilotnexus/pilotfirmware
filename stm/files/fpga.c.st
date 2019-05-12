#include "spi.h"
#include "fpga.h"
#include "common_base.h"
#include "pilot_comm.h"

$model.FPGAs:{fpga|

static void pilot_$fpga.Name$_init_exti()
{
  EXTI_InitTypeDef exti;

  /* connect exti line */
#ifdef STM32F4XX
  SYSCFG_EXTILineConfig(EXTI_PortSource$fpga.INT.GPIO$, $fpga.INT.ExtiPinSource$);
#else
  GPIO_EXTILineConfig(GPIO_PortSource$fpga.INT.GPIO$, $fpga.INT.GpioPinSource$);
#endif

  /* configure the exti line */
  exti.EXTI_Line    = $fpga.INT.ExtiLine$;
  exti.EXTI_Mode    = EXTI_Mode_Interrupt;
  exti.EXTI_Trigger = EXTI_Trigger_Falling;
  exti.EXTI_LineCmd = ENABLE;
  EXTI_Init(&exti);

\}

static void pilot_$fpga.Name$_init_nvic()
{
  /* enable and set EXTI Line Interrupt */
  NVIC_InitTypeDef nvic;
  nvic.NVIC_IRQChannel                   = $fpga.INT.ExtiIrqChannel$;
  nvic.NVIC_IRQChannelPreemptionPriority = 0x00;
  nvic.NVIC_IRQChannelSubPriority        = 0x0F;
  nvic.NVIC_IRQChannelCmd                = ENABLE;
  NVIC_Init(&nvic);
\}

static void pilot_$fpga.Name$_init_gpio()
{
  GPIO_InitTypeDef gpio;

  /* enable the gpio clock of the INT pin */
  RCC_$fpga.INT.Periph$PeriphClockCmd(RCC_$fpga.INT.Periph$Periph_$fpga.INT.GPIO$, ENABLE);

#ifdef STM32F4XX
  /* enable syscfg clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_SYSCFG, ENABLE);
#endif

  /* configure INT pin */
  gpio.GPIO_Pin = $fpga.INT.Pin$;
#ifdef STM32F4XX
  gpio.GPIO_Mode = GPIO_Mode_IN;
#else
  gpio.GPIO_Mode = GPIO_Mode_IN_FLOATING;
#endif
  GPIO_Init($fpga.INT.GPIO$, &gpio);

\}

void pilot_$fpga.Name$_init()
{
  GPIO_InitTypeDef gpio;
  gpio.GPIO_Speed = GPIO_Speed_50MHz;

  /* configure the interrupt pin */
  pilot_$fpga.Name$_init_gpio();

  /* configure the interrupt on the stm for the fpga module */
  pilot_$fpga.Name$_init_exti();
  pilot_$fpga.Name$_init_nvic();

  /* pull the chip select high to disable transfer */
  GPIO_WriteBit($fpga.SPI.NssPin.GPIO$, $fpga.SPI.NssPin.Pin$, Bit_SET);

  /* configure CRESET pin */
  #ifdef STM32F4XX
  gpio.GPIO_Mode  = GPIO_Mode_OUT;
  gpio.GPIO_OType = GPIO_OType_PP;
  gpio.GPIO_PuPd  = GPIO_PuPd_UP;
#else
  gpio.GPIO_Mode = GPIO_Mode_Out_PP;
#endif
  gpio.GPIO_Pin = $fpga.CRESET.Pin$;
  GPIO_Init($fpga.CRESET.GPIO$, &gpio);

  /* pull CRESET to high to start fpga */
  GPIO_WriteBit($fpga.CRESET.GPIO$, $fpga.CRESET.Pin$, Bit_SET);

  /* configure CDONE pin */
#ifdef STM32F4XX
  gpio.GPIO_Mode  = GPIO_Mode_IN;
  gpio.GPIO_OType = GPIO_OType_OD;
#else
  gpio.GPIO_Mode = GPIO_Mode_IN_FLOATING;
#endif
  gpio.GPIO_Pin = $fpga.CDONE.Pin$;
  GPIO_Init($fpga.CDONE.GPIO$, &gpio);

  //test only
  //pilot_$fpga.Name$_read_flash_id();
\}

void pilot_$fpga.Name$_send_char(module_port_t port, uint16_t c)
{
  char res;

  //TODO: OPTIMIZE
  if (pilot_spi_set_cs(spi_id_$fpga.SPI.Id$, chip_select_enable))
  {
    res = pilot_spi_dataexchange(spi_id_$fpga.SPI.Id$, c & 0xFF);
    if (port == module_port_2)
      pilot_comm_send( target_t_from_module_slot_and_port((module_slot_t)$fpga.Slot$, module_port_2), &res, 1);
  \}

  if (c & 0x8000)
    pilot_spi_set_cs(spi_id_$fpga.SPI.Id$, chip_select_disable);
\}

void pilot_$fpga.Name$_send(uint8_t *buffer, int length)
{
  int i;
  if (pilot_spi_set_cs(spi_id_$fpga.SPI.Id$, chip_select_enable))
  {
    for (i=0; i < length; i++)
    {
      buffer[i] = pilot_spi_dataexchange(spi_id_$fpga.SPI.Id$, buffer[i]);
    \}
    pilot_spi_set_cs(spi_id_$fpga.SPI.Id$, chip_select_disable);
  \}
\}

uint8_t pilot_$fpga.Name$_fpga_gpio_set(int8_t chipselect, int8_t reset)
{
  if (reset != -1)
    GPIO_WriteBit($fpga.CRESET.GPIO$, $fpga.CRESET.Pin$, reset == 0 ? Bit_RESET : Bit_SET);

  if (chipselect != -1)
    pilot_spi_set_cs(spi_id_$fpga.SPI.Id$, chipselect == 0 ? chip_select_enable : chip_select_disable);

  return GPIO_ReadInputDataBit($fpga.CDONE.GPIO$, $fpga.CDONE.Pin$);
\}

};separator="\n"$