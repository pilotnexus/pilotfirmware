/* this file is auto-generated */
#include "io16.h"

#define CTRL 0x59
#define NOP 0x0F

$model.IO16s:{io16|

#define get_mosi_address( ba, ra, rnw ) ( (ba << 6) | (ra << 1) | (rnw) )

#define get_mosi_count( count ) ( ((count-1) << 4) | (0x0F & ~(count-1)) )

int rpc_$io16.Name$_write_register(rpcp_io16_register_t reg, int count, uint8_t *value)
{
  int16_t miso;
  uint8_t address_byte;
  int ret=1;
  int i;

  /* pull chip select down to start the communication */
  if (rpcp_spi_set_cs(spi_id_$io16.SPI.Id$, chip_select_enable))
  {
    /* request to write to the address */
    address_byte = get_mosi_address(0, (int)reg, 0);
    rpcp_spi_dataexchange(spi_id_$io16.SPI.Id$, address_byte);

    /* now send the number of bytes we want to write minus 1, encoded in the first nibble and inverted in the 2nd nibble */
    miso = rpcp_spi_dataexchange(spi_id_$io16.SPI.Id$, get_mosi_count(count));

    /* the chip should have answered by returning the address */
    if (address_byte != miso)
      ret = 0;
    else
    {
      for (i=0;i<count,ret>0;i++)
      {
        /* send the data to write to the chip */
        miso = rpcp_spi_dataexchange(spi_id_$io16.SPI.Id$, *value);

        /* check of the chip answered with the count */
        if ( (i == 0) && (miso != get_mosi_count(count)) )
          ret = 0;
        else if (i >= (count-1) )
        {
          /* send the end address */
          miso = rpcp_spi_dataexchange(spi_id_$io16.SPI.Id$, address_byte);

          /* check if the chip returned the data */
          if (miso != *value)
            ret = 0;
          else
          {
            /* send the CTRL byte to the chip */
            miso = rpcp_spi_dataexchange(spi_id_$io16.SPI.Id$, CTRL);

            /* check if the chip returned the CTRL byte */
            ret = (miso == CTRL) ? 1 : 0;
          \}
        \}
        else /* not the last byte to send, and not the first, check with previous byte */
        {
          if (miso != *(value-1))
            ret = 0;
        \}
      /* move to next byte */
      value++;
      \}
    \}

    /* pull chip select up again to disable communication with io16 */
    rpcp_spi_set_cs(spi_id_$io16.SPI.Id$, chip_select_disable);
  \}
  return ret;
\}

int rpc_$io16.Name$_read_register(rpcp_io16_register_t reg, int count, uint8_t *value)
{
  uint16_t miso;
  uint8_t address_byte;
  int ret;
  int i;

  /* pull chip select down to enable communication with io16 */
  if (rpcp_spi_set_cs(spi_id_$io16.SPI.Id$, chip_select_enable))
  {
    /* request to read the value by sending the address byte */
    address_byte = get_mosi_address(0, (int)reg, 1);
    rpcp_spi_dataexchange(spi_id_$io16.SPI.Id$, address_byte);

    /* now send a nop and receive the data from the chip */
    miso = rpcp_spi_dataexchange(spi_id_$io16.SPI.Id$, NOP);

    /* the chip should have echoed the requested address */
    if (address_byte != miso)
      ret = 0;
    else
    {
      /* master sends the number of bytes to be read minus 1, encoded in the first nibble and inverted in the 2nd nibble */
      miso = rpcp_spi_dataexchange(spi_id_$io16.SPI.Id$, get_mosi_count(count));

      for (i=0; i< count; i++)
      {
        /* set the value */
        *value = miso;
      
        /* set to next byte */
        value++;

        /* echo the received data */
        miso = rpcp_spi_dataexchange(spi_id_$io16.SPI.Id$, miso);
      \}

      /* send control byte */
      miso = rpcp_spi_dataexchange(spi_id_$io16.SPI.Id$, CTRL);

      /* test if the module returned the ctrl byte */
      ret = (miso == CTRL) ? 1 : 0;
    \}

    /* pull chip select up again to disable communication with io16 */
    rpcp_spi_set_cs(spi_id_$io16.SPI.Id$, chip_select_disable);
  \}
  return ret;
\}

/* gets the direction of the io */
int rpc_$io16.Name$_get_direction(uint8_t io, rpcp_io16_direction_t *direction)
{
  rpcp_io16_register_t reg;
  uint8_t reg_value, mask;

  if (io < 8)
    reg = rpcp_io16_register_controlword_2A;
  else if (io >= 8 && io < 16)
    reg = rpcp_io16_register_controlword_2B;
  else
    return 0;

  if (!rpc_$io16.Name$_read_register(reg, 1, &reg_value))
    return 0;

  if ( io < 4 || (io >= 8 && io < 12) )
    mask = (1 << 3);
  else if ( (io >= 4 && io < 8) || (io >= 12 && io < 16))
    mask = (1 << 7);
  else
    return 0;

  *direction = (reg_value & mask) ? rpcp_io16_direction_output : rpcp_io16_direction_input;

  return 1;
\}

int rpc_$io16.Name$_get_value(uint8_t io, uint8_t *value)
{
  int ret;
  rpcp_io16_register_t reg;
  uint8_t reg_value;
  rpcp_io16_direction_t direction;

  /* first get the direction of io */
  ret = rpc_$io16.Name$_get_direction(io, &direction);

  if (ret)
  {
    /* get the register depending on the io's direction */
    if (direction == rpcp_io16_direction_output)
    {
      if (io < 8) 
        reg = rpcp_io16_register_output_register_A;
      else if (io > 8 && io < 16)
        reg = rpcp_io16_register_output_register_B;
      else
        ret = 0;
    \} 
    else if (direction == rpcp_io16_direction_input)
    {
      if (io < 8)
        reg = rpcp_io16_register_input_register_A;
      else if (io > 8 && io < 16)
        reg = rpcp_io16_register_input_register_B;
      else
        ret = 0;
    \}
    else
      ret = 0;

    if (ret)
    {
      /* read the register value */
      ret = rpc_$io16.Name$_read_register(reg, 1, &reg_value);
      if (ret)
      {
        /* set the values */
        *value = (reg_value >> (io % 8)) & 0x01;
        ret = 1;
      \}
    \}

  \}

  return ret;
\}

uint8_t rpc_$io16.Name$_get_byte(rpcp_io16_register_t reg)
{
  int ret;
  uint8_t reg_value;

  ret = rpc_$io16.Name$_read_register(reg, 1, &reg_value);
  if (ret)
    return reg_value;

  return 0;
\}


/* wrapper function for setting the direction of a single io block */
int rpc_$io16.Name$_set_direction(rpcp_io16_block_t block, rpcp_io16_direction_t direction)
{
  int ret;
  rpcp_io16_register_t reg;
  uint8_t reg_value, update;

  /* get the register that holds the direction of the io */
  switch (block)
  {
    case rpcp_io16_block_0_to_3:
    case rpcp_io16_block_4_to_7:
      reg = rpcp_io16_register_controlword_2A;
      ret = 1;
      break;
    case rpcp_io16_block_8_to_11:
    case rpcp_io16_block_12_to_15:
      reg = rpcp_io16_register_controlword_2B;
      ret = 1;
      break;
    default: /* unknown block */
      ret = 0;
      break;
  \}

  /* first read current directions of the pins */
  if (ret)
    ret = rpc_$io16.Name$_read_register(reg, 1, &reg_value);

  if (ret)
  {
    /* update the current setting with the new direction of the specified block */
    update = 1 << ((block == rpcp_io16_block_0_to_3 || block == rpcp_io16_block_8_to_11) ? 3 : 7);
    if (direction == rpcp_io16_direction_input)
      reg_value &= ~update;
    else
      reg_value |= update;

    /* write back the register value */
    ret = rpc_$io16.Name$_write_register(reg, 1, &reg_value);
  \}

  return ret;
\}

/* wrapper function for setting the value of a single output */
int rpc_$io16.Name$_set_value(rpcp_output_target_t output, uint8_t value)
{
  int ret;
  rpcp_io16_register_t reg;
  uint8_t reg_value, update;

  ret = 0;

  /* get the register that holds this outputs value */
  reg = output < 8 ? rpcp_io16_register_output_register_A : rpcp_io16_register_output_register_B;

  /* first read the current output values that the specific output belongs to */
  ret = rpc_$io16.Name$_read_register(reg, 1, &reg_value);

  if (ret)
  {
    /* update the register value */
    update = 1 << ((int)output % 8);
    if (value)
      reg_value |= update;
    else
      reg_value &= ~update;

    /* write back the updated register value */
    ret = rpc_$io16.Name$_write_register(reg, 1, &reg_value);
  \}

  return ret;
\}

/* wrapper function for setting the value of a nibble (not byte!) */
void rpc_$io16.Name$_set_byte(rpcp_io16_register_t reg, uint8_t value)
{
  int ret;

  ret = rpc_$io16.Name$_write_register(reg, 1, &value);
  /* todo report error */
\}

/* enables/disables the interrupt on input changes */
static int rpc_$io16.Name$_set_input_change_irq_enable(uint8_t enable)
{
  int ret;
  uint8_t value = enable ? 0xFF : 0;

  /* enable / disable interrupt for IOs 0-7  */
  ret = rpc_$io16.Name$_write_register(rpcp_io16_register_irq_enable_inputchange_A, 1, &value);

  /* enable / disable interrupt for IOs 8-15 */
  if (ret)
    ret = rpc_$io16.Name$_write_register(rpcp_io16_register_irq_enable_inputchange_B, 1, &value);

  return ret;
\}

static int rpc_$io16.Name$_set_io_filter_bypass_enable(uint8_t enable)
{
  int ret;
  uint8_t value = enable ? 0x88 : 0x00;

  /* enable / disable io filter bypass for pins 0-7 */
  ret = rpc_$io16.Name$_write_register(rpcp_io16_register_controlword_1A, 1, &value);

  /* enable / disable io filter bypass for pins 8-15 */
  if (ret)
    ret = rpc_$io16.Name$_write_register(rpcp_io16_register_controlword_1B, 1, &value);

  return ret;
\}

int rpc_$io16.Name$_set_irq_handled()
{
  uint8_t value = 0x80;
  /* reset EOI in in controlword 4 to reset the interrupt 1 0 0 0 0 0 0 0 */
  return rpc_$io16.Name$_write_register(rpcp_io16_register_controlword_4, 1, &value);
\}

static void rpc_$io16.Name$_init_exti()
{
  EXTI_InitTypeDef exti;

  /* connect exti line */
#ifdef STM32F4XX
  SYSCFG_EXTILineConfig(EXTI_PortSource$io16.INT.GPIO$, $io16.INT.ExtiPinSource$);
#else
  GPIO_EXTILineConfig(GPIO_PortSource$io16.INT.GPIO$, $io16.INT.GpioPinSource$);
#endif

  /* configure the exti line */
  exti.EXTI_Line    = $io16.INT.ExtiLine$;
  exti.EXTI_Mode    = EXTI_Mode_Interrupt;
  exti.EXTI_Trigger = EXTI_Trigger_Falling;
  exti.EXTI_LineCmd = ENABLE;
  EXTI_Init(&exti);

\}

static void rpc_$io16.Name$_init_nvic()
{
  /* enable and set EXTI Line Interrupt */
  NVIC_InitTypeDef nvic;
  nvic.NVIC_IRQChannel                   = $io16.INT.ExtiIrqChannel$;
  nvic.NVIC_IRQChannelPreemptionPriority = 0x00;
  nvic.NVIC_IRQChannelSubPriority        = 0x0F;
  nvic.NVIC_IRQChannelCmd                = ENABLE;
  NVIC_Init(&nvic);
\}

static void rpc_$io16.Name$_init_gpio()
{
  GPIO_InitTypeDef gpio;

  /* enable the gpio clock of the INT pin */
  RCC_$io16.INT.Periph$PeriphClockCmd(RCC_$io16.INT.Periph$Periph_$io16.INT.GPIO$, ENABLE);

#ifdef STM32F4XX
  /* enable syscfg clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_SYSCFG, ENABLE);
#endif

  /* configure INT pin */
  gpio.GPIO_Pin = $io16.INT.Pin$;
#ifdef STM32F4XX
  gpio.GPIO_Mode = GPIO_Mode_IN;
#else
  gpio.GPIO_Mode = GPIO_Mode_IN_FLOATING;
#endif
  GPIO_Init($io16.INT.GPIO$, &gpio);

\}

void rpc_$io16.Name$_init()
{
  /* configure the interrupt pin */
  rpc_$io16.Name$_init_gpio();

  /* configure the interrupt on the stm for the io16 module */
  rpc_$io16.Name$_init_exti();
  rpc_$io16.Name$_init_nvic();

  /* enable the io filter bypass */
  rpc_$io16.Name$_set_io_filter_bypass_enable(1);

  /* reset the interrupt if it is already on */
  rpc_$io16.Name$_set_irq_handled();

  /* enable the interrupt on the io16 module */
  rpc_$io16.Name$_set_input_change_irq_enable(1);

  /* pull the chip select high to disable transfer */
  //GPIO_WriteBit($io16.SPI.NssPin.GPIO$, $io16.SPI.NssPin.Pin$, Bit_SET);
\}

};separator="\n"$


