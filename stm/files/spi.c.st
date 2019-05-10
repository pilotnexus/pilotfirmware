#include "spi.h"

spi_id_t slot_to_spi[$model.Modules.Count$] = { $model.Modules:{module|$if(module.SpiId)$spi_id_$module.SpiId$$else$spi_id_invalid$endif$};separator=","$};

static spi_id_t enabled_cs = spi_id_invalid;

/* private function to set the chip select pin */
static void rpcp_spi_set_cs_pin(spi_id_t spi_id, chip_select_t cs)
{
  switch (spi_id)
  {
$model.SPIs:{spi |    case spi_id_$i$:
      GPIO_WriteBit($spi.NssPin.GPIO$, $spi.NssPin.Pin$, (cs == chip_select_enable) ? Bit_RESET : Bit_SET);
      break;
}; separator = "\n"$
  }
}

void rpcp_spi_setup()
{
  GPIO_InitTypeDef gpio;

$model.SPIs:{spi|
  /* spi_id_$i$ - $spi.Name$ */
  RCC_$spi.SPIPeriph$PeriphClockCmd(RCC_$spi.SPIPeriph$Periph_$spi.Name$, ENABLE); /* enable the spi clock */
  RCC_$spi.GPIOPeriph$PeriphClockCmd(RCC_$spi.GPIOPeriph$Periph_$spi.GPIO$, ENABLE); /* enable the gpio clock */

  /* configure SCK and MOSI as alternate function push pull */
  gpio.GPIO_Speed = GPIO_Speed_50MHz;
  gpio.GPIO_Pin = $spi.ClkPin$ | $spi.MosiPin$;
  gpio.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_Init($spi.GPIO$, &gpio);

  /* configure MISO as in floating */
  gpio.GPIO_Pin = $spi.MisoPin$;
  gpio.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_Init($spi.GPIO$, &gpio);

  /* configure NSS as Push Pull */
  gpio.GPIO_Pin = $spi.NssPin.Pin$;
  gpio.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init($spi.NssPin.GPIO$, &gpio);

};separator = "\n"$
  /* disable all chip selects */
  $model.SPIs:{spi | rpcp_spi_set_cs_pin(spi_id_$i$, chip_select_disable); }; separator = "\n"$
}

/* configure the spi */
void rpcp_spi_configure(spi_id_t spi_id)
{
  SPI_InitTypeDef spi;

  switch (spi_id)
  {
$model.SPIs:{spi|case spi_id_$i$:
      SPI_StructInit(&spi);
      spi.SPI_Direction         = $spi.Direction$;
      spi.SPI_Mode              = $spi.Mode$;
      spi.SPI_DataSize          = $spi.DataSize$;
      spi.SPI_FirstBit          = $spi.FirstBit$;
      spi.SPI_NSS               = $spi.Nss$;
      spi.SPI_BaudRatePrescaler = $spi.BaudRatePrescaler$;
      SPI_Init($spi.Name$, &spi);
      SPI_Cmd($spi.Name$, ENABLE); /* enable spi */
    break;
    };separator="\n"$
  }
}

bool rpcp_spi_set_cs(spi_id_t spi_id, chip_select_t cs)
{
  if (enabled_cs == spi_id_invalid && cs == chip_select_enable)
  {
    rpcp_spi_configure(spi_id);
    rpcp_spi_set_cs_pin(spi_id, chip_select_enable);
    enabled_cs = spi_id;
    return true;
  }
  else if (enabled_cs == spi_id && cs == chip_select_disable)
  {
    rpcp_spi_set_cs_pin(spi_id, chip_select_disable);
    enabled_cs = spi_id_invalid;
    return true;
  }
  else if (enabled_cs == spi_id && cs == chip_select_enable)
    return true;  //already selected

  return false;
}

/* rpcp_spi_data_send, sends data only */
void rpcp_spi_send(spi_id_t spi_id, uint16_t mosi)
{
  switch (spi_id)
  {
    $model.SPIs:{spi | case spi_id_$i$:
      while (SPI_I2S_GetFlagStatus($spi.Name$, SPI_I2S_FLAG_TXE) == RESET);  /* wait for transmit buffer empty */
      SPI_I2S_SendData($spi.Name$, mosi);                                    /* send */
      break; }; separator = "\n"$
  }
}

/* rpcp_spi_data_exchange */
uint16_t rpcp_spi_dataexchange(spi_id_t spi_id, uint16_t mosi)
{
  uint16_t miso;

  switch (spi_id)
  {
    $model.SPIs:{spi|case spi_id_$i$:
    while (SPI_I2S_GetFlagStatus($spi.Name$, SPI_I2S_FLAG_TXE) == RESET);  /* wait for transmit buffer empty */
    SPI_I2S_SendData($spi.Name$, mosi);                                    /* send */
    while (SPI_I2S_GetFlagStatus($spi.Name$, SPI_I2S_FLAG_RXNE) == RESET); /* wait for data reception */
    miso = SPI_I2S_ReceiveData($spi.Name$);                                /* receive */
  break;}; separator = "\n"$
  }

  return miso;
}

