#include "delay.h"
#include "spi.h"
#include "aio20.h"
#include "common_base.h"
#include "pilot_comm.h"

$if(model.AIO20s)$

#include "aio20_config.h"

extern void MAX11300init();
$endif$

extern spi_id_t slot_to_spi[];

//physical IO to logical port mapping
uint8_t io_to_port[20] = {
  3, 1, 2, 0, 
  6, 5, 9, 8,
  11, 10, 14, 13,
  16, 15, 18, 19,
  4, 7, 12, 17
};

uint8_t currentConfigSlot = -1;

bool MAX11300regWrite(int regAddress8, int regData16)
{
  write_register(currentConfigSlot, regAddress8, regData16);
  return true;
}

void MAX11300initDelayus(int delay_us)
{
  pilot_delay_us(delay_us);
}

$model.AIO20s:{aio20|

static void pilot_$aio20.Name$_init_exti()
{
  EXTI_InitTypeDef exti;

  /* connect exti line */
#ifdef STM32F4XX
  SYSCFG_EXTILineConfig(EXTI_PortSource$aio20.INT.GPIO$, $aio20.INT.ExtiPinSource$);
#else
  GPIO_EXTILineConfig(GPIO_PortSource$aio20.INT.GPIO$, $aio20.INT.GpioPinSource$);
#endif

  /* configure the exti line */
  exti.EXTI_Line    = $aio20.INT.ExtiLine$;
  exti.EXTI_Mode    = EXTI_Mode_Interrupt;
  exti.EXTI_Trigger = EXTI_Trigger_Falling;
  exti.EXTI_LineCmd = ENABLE;
  EXTI_Init(&exti);

\}

static void pilot_$aio20.Name$_init_nvic()
{
  /* enable and set EXTI Line Interrupt */
  NVIC_InitTypeDef nvic;
  nvic.NVIC_IRQChannel                   = $aio20.INT.ExtiIrqChannel$;
  nvic.NVIC_IRQChannelPreemptionPriority = 0x00;
  nvic.NVIC_IRQChannelSubPriority        = 0x0F;
  nvic.NVIC_IRQChannelCmd                = ENABLE;
  NVIC_Init(&nvic);
\}

static void pilot_$aio20.Name$_init_gpio()
{
  GPIO_InitTypeDef gpio;

  /* enable the gpio clock of the INT pin */
  RCC_$aio20.INT.Periph$PeriphClockCmd(RCC_$aio20.INT.Periph$Periph_$aio20.INT.GPIO$, ENABLE);

#ifdef STM32F4XX
  /* enable syscfg clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_SYSCFG, ENABLE);
#endif

  /* configure INT pin */
  gpio.GPIO_Pin = $aio20.INT.Pin$;
#ifdef STM32F4XX
  gpio.GPIO_Mode = GPIO_Mode_IN;
#else
  gpio.GPIO_Mode = GPIO_Mode_IN_FLOATING;
#endif
  GPIO_Init($aio20.INT.GPIO$, &gpio);

\}

int pilot_$aio20.Name$_init()
{
  GPIO_InitTypeDef gpio;
  gpio.GPIO_Speed = GPIO_Speed_50MHz;

  /* configure the interrupt pin */
  pilot_$aio20.Name$_init_gpio();

  /* configure the interrupt on the stm for the fpga module */
  pilot_$aio20.Name$_init_exti();
  pilot_$aio20.Name$_init_nvic();

  /* pull the chip select high to disable transfer */
  GPIO_WriteBit($aio20.SPI.NssPin.GPIO$, $aio20.SPI.NssPin.Pin$, Bit_SET);

  /* configure CNVT pin */
  #ifdef STM32F4XX
  gpio.GPIO_Mode  = GPIO_Mode_OUT;
  gpio.GPIO_OType = GPIO_OType_PP;
  gpio.GPIO_PuPd  = GPIO_PuPd_UP;
#else
  gpio.GPIO_Mode = GPIO_Mode_Out_PP;
#endif
  gpio.GPIO_Pin = $aio20.CNVT.Pin$;
  GPIO_Init($aio20.CNVT.GPIO$, &gpio);

    /* pull CNVT high */
  GPIO_WriteBit($aio20.CNVT.GPIO$, $aio20.CNVT.Pin$, Bit_SET);

  AIO20_init($aio20.Slot$);

  currentConfigSlot = $aio20.Slot$;
  //TODO - individual configurations
  MAX11300init();

  /* check if communication is working */

  return (aio20_get_device_id($aio20.Slot$) == 0x424) ? 0 : 1;
\}

int pilot_$aio20.Name$_check()
{
  return (aio20_get_device_id($aio20.Slot$) == 0x424) ? 0 : 1;
\}

};separator="\n"$

uint16_t get_aio20_dac_config(uint8_t slot, uint8_t port) 
{
  switch (slot)
  {
    $model.AIO20s:{aio20|case $aio20.Slot$: return aio20_$aio20.Slot$_dac[port]; break;
    };separator="\n"$
  }
  return 0x0; //should never happen
\}

uint16_t get_aio20_port_config(uint8_t slot, uint8_t port) 
{
  switch (slot)
  {
    $model.AIO20s:{aio20|case $aio20.Slot$: return aio20_$aio20.Slot$_port_config[port]; break;
    };separator="\n"$
  }
  return 0x71e0; //should never happen
\}

void pilot_AIO20_set_CNVT(uint8_t slot, BitAction bitVal)
{
  switch (slot)
  {
    $model.AIO20s:{aio20|case $aio20.Slot$: GPIO_WriteBit($aio20.CNVT.GPIO$, $aio20.CNVT.Pin$, bitVal); break;
    };separator="\n"$
  }
}


    //*********************************************************************
void write_register(uint8_t slot, MAX11300RegAddress_t reg, uint16_t data)
{
  pilot_spi_set_cs(slot_to_spi[slot], chip_select_enable);
  pilot_spi_dataexchange(slot_to_spi[slot],MAX11300Addr_SPI_Write(reg));
  pilot_spi_dataexchange(slot_to_spi[slot], ((0xFF00 & data) >> 8));
  pilot_spi_dataexchange(slot_to_spi[slot], (0x00FF & data));
  pilot_spi_set_cs(slot_to_spi[slot], chip_select_disable);
}

//*********************************************************************    
uint16_t read_register(uint8_t slot, MAX11300RegAddress_t reg)
{
    uint16_t rtn_val = 0;
    
    pilot_spi_set_cs(slot_to_spi[slot], chip_select_enable);
    pilot_spi_dataexchange(slot_to_spi[slot], MAX11300Addr_SPI_Read(reg));
    rtn_val = (pilot_spi_dataexchange(slot_to_spi[slot], 0x0) << 8); 
    rtn_val |= pilot_spi_dataexchange(slot_to_spi[slot], 0x0); 
    pilot_spi_set_cs(slot_to_spi[slot], chip_select_disable);
    
    return rtn_val;
}

//*********************************************************************    
void block_write(uint8_t slot, MAX11300RegAddress_t reg, uint16_t * data, uint8_t num_reg)
{
    for(uint8_t idx = 0; idx < num_reg; idx++)
    {
        write_register(slot, (MAX11300RegAddress_t)(reg + idx), data[idx]);
    }
}

//*********************************************************************        
void block_read(uint8_t slot, MAX11300RegAddress_t reg, uint16_t * data, uint8_t num_reg)
{
    for(uint8_t idx = 0; idx < num_reg; idx++)
    {
        data[idx] = read_register(slot, (MAX11300RegAddress_t)(reg + idx));
    }
}

//*********************************************************************    
CmdResult gpio_write(uint8_t slot, uint8_t io, uint8_t state)
{
    CmdResult result = OpFailure;
    uint8_t port = io_to_port[io];
    uint16_t temp;
    uint16_t port_mask;
    uint16_t port_config = get_aio20_port_config(slot, port);
    
    if(((port_config & 0xF000) >> 12) == MODE_3)
    {
        if(port < PIXI_PORT16)
        {
            port_mask = (1 << port);
            temp = read_register(slot, gpo_data_15_to_0);
            if(state & 0x01)
            {
                temp |= port_mask;
            }
            else
            {
                temp &= ~port_mask;
            }
            write_register(slot, gpo_data_15_to_0, temp);
        }
        else
        {
            port_mask = (1 << (port - PIXI_PORT16));
            temp = read_register(slot, gpo_data_19_to_16);
            if(state & 0x01)
            {
                temp |= port_mask;
            }
            else
            {
                temp &= ~port_mask;
            }
            write_register(slot, gpo_data_19_to_16, temp);
        }
        
        result = Success;
    }
    
    return result;
}

//*********************************************************************
CmdResult gpio_read(uint8_t slot, uint8_t io, uint8_t *state)
{
    CmdResult result = OpFailure;
    uint8_t port = io_to_port[io];
    uint16_t port_config = get_aio20_port_config(slot, port);
    
    if(((port_config & 0xF000) >> 12) == MODE_1)
    {
        if(port < PIXI_PORT16)
        {
            *state = (read_register(slot, gpi_data_15_to_0) >> port);
        }
        else
        {
            *state = (read_register(slot, gpi_data_19_to_16) >> (port - PIXI_PORT16));
        }
        
        result = Success;
    }
    return result;
}

//*********************************************************************
CmdResult single_ended_adc_read(uint8_t slot, uint8_t io, uint16_t *data)
{
    CmdResult result = OpFailure;
    uint8_t port = io_to_port[io];
    uint16_t port_config = get_aio20_port_config(slot, port);
    
    if(((port_config & 0xF000) >> 12) == MODE_7)
    {
        uint8_t num_samples = ((port_config & port_cfg_00_funcprm_nsamples) >> 5);
        num_samples = (1 << num_samples);
        
        while(num_samples--)
        {
            pilot_AIO20_set_CNVT(slot, Bit_RESET);
            pilot_delay_us(1);
            pilot_AIO20_set_CNVT(slot, Bit_SET);
            pilot_delay_us(100);
        }
        *data = read_register(slot, (MAX11300RegAddress_t)(adc_data_port_00 + port));
        
        result = Success;
    }
    
    return result;
}

uint16_t aio20_get_device_id(uint8_t slot)
{
  uint16_t dev_id_value;

  //read device id
  pilot_spi_set_cs(slot_to_spi[slot], chip_select_enable);
  pilot_spi_dataexchange(slot_to_spi[slot], MAX11300Addr_SPI_Read(0x0)); //dev_id
  dev_id_value = pilot_spi_dataexchange(slot_to_spi[slot], 0x0) << 8; 
  dev_id_value |= pilot_spi_dataexchange(slot_to_spi[slot], 0x1); 
  pilot_spi_set_cs(slot_to_spi[slot], chip_select_disable);

  return dev_id_value;
}

int single_ended_adc_read_all(uint8_t slot, uint8_t *data)
{
    int i;
    uint16_t dev_id = aio20_get_device_id(slot);

    pilot_spi_set_cs(slot_to_spi[slot], chip_select_enable);
    pilot_spi_dataexchange(slot_to_spi[slot], MAX11300Addr_SPI_Read(adc_data_port_00));
    for(i = 0; i < 20; i++)
    {
      *(data + 1) = pilot_spi_dataexchange(slot_to_spi[slot], 0x0); 
      *data = pilot_spi_dataexchange(slot_to_spi[slot], 0x0); 
      data+=2;
    }
    pilot_spi_set_cs(slot_to_spi[slot], chip_select_disable);
    
    return (dev_id == 0x424) ? 0 : 1;
}

//*********************************************************************
CmdResult single_ended_dac_write(uint8_t slot, uint8_t io, uint16_t data)
{
    CmdResult result = OpFailure;
    uint8_t port = io_to_port[io];
    uint16_t port_config = get_aio20_port_config(slot, port);

    if(((port_config & 0xF000) >> 12) == MODE_5)
    {
        write_register(slot, (MAX11300RegAddress_t)(dac_data_port_00 + port) , data);
        result = Success;
    }
    
    return result;
}

//*********************************************************************
void config_process_1(uint8_t slot, uint16_t *device_control_local)
{
    uint8_t idx;
    uint16_t port_mode;
    uint16_t port_config;
    uint16_t port_dac;
    
    *device_control_local |= (device_control_DESIGNVALUE & (device_control_DACREF | device_control_DACCTL));
    write_register(slot, device_control, *device_control_local);
    
    pilot_delay_us(200);
    
    //Is DACCTL = 2 or 3
    if(((device_control_DESIGNVALUE & device_control_DACCTL) == 2) || ((device_control_DESIGNVALUE & device_control_DACCTL) == 3))
    {
        //yes
        write_register(slot, dac_preset_data_1, dac_preset_data_1_DESIGNVALUE);
        write_register(slot, dac_preset_data_2, dac_preset_data_2_DESIGNVALUE);
    }
    else
    {
        //no
        for(idx = 0; idx < 20; idx++)
        {
            port_config = get_aio20_port_config(slot, idx);
            port_dac = get_aio20_dac_config(slot, idx);
            port_mode = ((port_config & 0xf000) >> 12);
            if((port_mode == MODE_1) || (port_mode == MODE_3) || 
               (port_mode == MODE_4) || (port_mode == MODE_5) || 
               (port_mode == MODE_6) || (port_mode == MODE_10))
            {
                write_register(slot, (MAX11300RegAddress_t)(dac_data_port_00 + idx), port_dac);
            }
        }
    }
    
    //Config FUNCID[i], FUNCPRM[i] for ports in mode 1
    uint8_t num_ports_mode_1 = 0;
    for(idx = 0; idx < 20; idx++)
    {
        port_mode = ((port_config & 0xf000) >> 12);
        if(port_mode == MODE_1)
        {
            write_register(slot, (MAX11300RegAddress_t)(port_cfg_00 + idx), port_config);
            num_ports_mode_1++;
        }
    }
    
    pilot_delay_us(200 * num_ports_mode_1);
    
    //Config GPODAT[i] for ports in mode 3
    write_register(slot, gpo_data_15_to_0, gpo_data_15_to_0_DESIGNVALUE);
    write_register(slot, gpo_data_19_to_16, gpo_data_19_to_16_DESIGNVALUE);
    
    //Config FUNCID[i], FUNCPRM[i] for ports in mode 3, 4, 5, 6, or 10
    for(idx = 0; idx < 20; idx++)
    {

        port_config = get_aio20_port_config(slot, idx);
        port_mode = ((port_config & 0xf000) >> 12);
        if((port_mode == MODE_3) | (port_mode == MODE_4) | 
           (port_mode == MODE_5) | (port_mode == MODE_6) | 
           (port_mode == MODE_10))
        {
            write_register(slot, (MAX11300RegAddress_t)(port_cfg_00 + idx), port_config);
            pilot_delay_us(1000);
        }
    }
    
    //Config GPIMD[i] for ports in mode 1
    write_register(slot, gpi_irqmode_7_to_0, gpi_irqmode_7_to_0_DESIGNVALUE);
    write_register(slot, gpi_irqmode_15_to_8, gpi_irqmode_15_to_8_DESIGNVALUE);
    write_register(slot, gpi_irqmode_19_to_16, gpi_irqmode_19_to_16_DESIGNVALUE);   
}

//*********************************************************************
void config_process_2(uint8_t slot, uint16_t *device_control_local)
{
    uint8_t idx;
    uint16_t port_mode;
    uint16_t port_config;
    
    for(idx = 0; idx < 20; idx++)
    {
        port_config = get_aio20_port_config(slot, idx);
        port_mode = ((port_config & 0xf000) >> 12); 
        if(port_mode == MODE_9)
        {
            write_register(slot, (MAX11300RegAddress_t)(port_cfg_00 + idx), port_config);
            pilot_delay_us(100);
        }
    }
    
    for(idx = 0; idx < 20; idx++)
    {
        port_mode = ((aio20_1_port_config[idx] & 0xf000) >> 12); 
        if((port_mode == MODE_7) || (port_mode == MODE_8))
        {
            write_register(slot, (MAX11300RegAddress_t)(port_cfg_00 + idx), aio20_1_port_config[idx]);
            pilot_delay_us(100);
        }
    }
    
    *device_control_local |= (device_control_DESIGNVALUE & device_control_ADCCTL);
    write_register(slot, device_control, *device_control_local);
}

//*********************************************************************
void config_process_3(uint8_t slot)
{
    uint8_t idx;
    uint16_t port_mode;
    
    for(idx = 0; idx < 20; idx++)
    {
        port_mode = ((aio20_1_port_config[idx] & 0xf000) >> 12); 
        if((port_mode == MODE_2) || (port_mode == MODE_11) || (port_mode == MODE_12))
        {
            write_register(slot, (MAX11300RegAddress_t)(port_cfg_00 + idx), aio20_1_port_config[idx]);
        }
    }
}

//*********************************************************************
void AIO20_init(uint8_t slot)
{
    //see datasheet 19-7318; Rev 3; 4/16; page 49
    //https://datasheets.maximintegrated.com/en/ds/MAX11300.pdf
    //for description of configuration process
    
    uint8_t idx;
    uint8_t port_mode;
    uint16_t mode_bit_mask = 0;
    
    //figure out port modes used
    for(idx = 0; idx < 20; idx++)
    {
        port_mode = ((aio20_1_port_config[idx] & 0xf000) >> 12);
        if(port_mode > 0)
        {
            mode_bit_mask |= (1 << port_mode);
        }   
    }
    
    //STEP 1: configure BRST, THSHDN, ADCCONV
    uint16_t device_control_local = (device_control_DESIGNVALUE & (device_control_BRST | device_control_THSHDN | device_control_ADCCONV));
    write_register(slot, device_control, device_control_local);
    
    //STEP 2: If any port is configured for modes 1,3,4,5,6, or 10
    if(mode_bit_mask & MODE_BITMASK_PROCESS_1)
    {
        config_process_1(slot, &device_control_local);
    }
    
    //STEP 3: If any port is configured for modes 7,8, or 9
    if(mode_bit_mask & MODE_BITMASK_PROCESS_2)
    {
        config_process_2(slot, &device_control_local);
    }
    
    //STEP 4: If any port is configured for modes 2,11, or 12
    if(mode_bit_mask & MODE_BITMASK_PROCESS_3)
    {
        config_process_3(slot);
    }
    
    //STEP 5: Are Temperature sensors used?
    if(device_control_DESIGNVALUE & (device_control_TMPCTLEXT1 | device_control_TMPCTLEXT0 | device_control_TMPCTLINT))
    {
        device_control_local |= (device_control_DESIGNVALUE & (device_control_TMPPER | device_control_RS_CANCEL));
        write_register(slot, device_control, device_control_local);
        
        uint16_t temp_thresholds [6] = {
            tmp_mon_int_hi_thresh_DESIGNVALUE, 
            tmp_mon_int_lo_thresh_DESIGNVALUE,
            tmp_mon_ext1_hi_thresh_DESIGNVALUE,
            tmp_mon_ext1_lo_thresh_DESIGNVALUE,
            tmp_mon_ext2_hi_thresh_DESIGNVALUE,
            tmp_mon_ext2_lo_thresh_DESIGNVALUE};
        block_write(slot, tmp_mon_int_hi_thresh, temp_thresholds, 6);
        
        device_control_local |= (device_control_DESIGNVALUE & (device_control_TMPCTLEXT1 | device_control_TMPCTLEXT0 | device_control_TMPCTLINT));
        write_register(slot, device_control, device_control_local);
    } 
    
    //STEP 6: Configure interrupt masks
    write_register(slot, interrupt_mask, interrupt_mask_DESIGNVALUE);
}
