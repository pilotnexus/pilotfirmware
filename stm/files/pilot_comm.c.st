#include "main.h"
#include "pilot_comm.h"
#include "plc.h"
#include "eeprom.h"
#include "pilot_usart.h"
#include "stm32f10x_crc.h"
#include "stm32f10x_dma.h"
#include "i8.h"
#include "o8.h"
#include "io16.h"
#include "ia8.h"
#include "fpga.h"
#include "gps.h"
#include "gsm.h"
#include "lora.h"
#include "gpio_config.h"
#include "types.h"
#include "stm.h"
#include "tty_commands.h"
#include <string.h>
#include "usart.h"
#include "counter8.h"
#include "onewire.h"
#include "rtc.h"
#include "slcd.h"
#include "test.h"

$if(model.AIO20s)$
#include "aio20.h"
$endif$

/* holds private members */
static internals_t _internals = {0};

static void pilot_pilot_comm_spi_init(void);
static void pilot_pilot_comm_spi_dma_init();
static void pilot_pilot_comm_gpio_init(void);
static void pilot_pilot_comm_gpio_clear(void);

static void pilot_pilot_comm_spi_handle_cmd_complete(pilot_cmd_t* cmd);
static void pilot_comm_handle_plc_readdata(char data);
static void pilot_comm_handle_plc_writedata(char data);

/* main initialization function */
void pilot_comm_init()
{
  NVIC_PriorityGroupConfig(NVIC_PriorityGroup_0);

  /* configure the additional gpios used in the rpi kernel driver communication */
  pilot_pilot_comm_gpio_init();

  /* make sure the gpios are cleared */
  pilot_pilot_comm_gpio_clear();

  /* setup the spi communication with the rpi kernel driver */
  pilot_pilot_comm_spi_init();
  
  /* setup spi circular DMA */
  pilot_pilot_comm_spi_dma_init();

  //init stats
  _internals.stats.tx_buffer_min = TX_BUFFER_SIZE;
  _internals.stats.rx_buffer_min = RX_BUFFER_SIZE;
  _internals.stats.crc_errors = 0;

  /* enable CRC clock */
  __IO uint32_t tmpreg;
  SET_BIT(RCC->AHBENR, RCC_AHBENR_CRCEN);
  /* Delay after an RCC peripheral clock enabling */
  tmpreg = READ_BIT(RCC->AHBENR, RCC_AHBENR_CRCEN);
}

void pilot_comm_increment_cmd_timeout()
{
  _internals.current_cmd_timeout_counter++;
}

bool pilot_enqueue_spi_tx(uint16_t data)
{
  
  uint32_t nextindex = _internals.spi_tx_end + 1;
  if (nextindex >= TX_BUFFER_SIZE) { //the last index needs to be a dummy byte for DMA transfer
    _internals.spi_tx_array[_internals.spi_tx_end] = get_spi_data(target_invalid, 0x00);
    _internals.spi_tx_end = 0;
    nextindex = 1;

    //check for overflow in this special case
    if (_internals.spi_tx_end == _internals.spi_tx_start) //error! OVERFLOW
    {
      _internals.send2rpiqueue_overflow_count++;
      return false;
    }
  }

  if (nextindex == _internals.spi_tx_start) //error! OVERFLOW
  {
    _internals.send2rpiqueue_overflow_count++;
    return false;
  }
  else
  {
    _internals.spi_tx_array[_internals.spi_tx_end] = data; // set data to current index
    _internals.spi_tx_end = nextindex; //and progress to the next index
  
    return true;
  }
}

void pilot_comm_enqueue_usart(uint16_t data)
{
  pilot_enqueue_spi_tx(data);
}

void pilot_comm_send(target_t target, char* buffer, int length)
{
  int i;

  /* enqueue it into the send2rpiqueue */
  for (i = 0; i < length; i++)
    pilot_enqueue_spi_tx(get_spi_data(target, *(buffer++)));

  pilot_setup_spi_tx();
}

/* send the supplied command to the rpi */
void pilot_comm_send_cmd(pilot_cmd_t *cmd)
{
  int i;
  uint8_t length_parity;
  int length = cmd->length << 2;

  length_parity = cmd->length;

  //calculate parity
  length_parity ^= length_parity >> 4;
  length_parity ^= length_parity >> 2;
  length_parity ^= length_parity >> 1;
  cmd->length = cmd->length | ((length_parity & 1) != 0 ? 0 : 0x80);

  CRC_ResetDR();
  CRC->DR = *((uint32_t*)cmd);

  for(i=0;i<length;i+=4)
    CRC->DR = *((uint32_t*)(((uint8_t*)cmd) + i + 4));

  cmd->crc = CRC->DR;

  //header
  pilot_enqueue_spi_tx(get_spi_data(target_base, cmd->target));
  pilot_enqueue_spi_tx(get_spi_data(target_base_type, cmd->type));
  pilot_enqueue_spi_tx(get_spi_data(target_base_length, cmd->length));
  pilot_enqueue_spi_tx(get_spi_data(target_base_reserved, cmd->reserved));

  //data
  for (i = 0; i < length; i++)
    pilot_enqueue_spi_tx(get_spi_data(target_base_data, cmd->data[i]));

    //crc
  for (i = 0; i < sizeof(uint32_t); i++)
    pilot_enqueue_spi_tx(get_spi_data(target_base_crc, ((uint8_t *)&cmd->crc)[i]));

  pilot_setup_spi_tx();
}

static void pilot_pilot_comm_spi_dma_init()
{
  RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1, ENABLE);      // Enable DMA1 clock

  DMA_DeInit(DMA1_Channel2);                              // Reset DMA1 channe1 to default values;

  DMA_InitStructure_rx.DMA_M2M = DMA_M2M_Disable;            // M2M Disabled- Peripheral mode (requires timer trigger)
  DMA_InitStructure_rx.DMA_Mode = DMA_Mode_Circular;         // Circular mode
  DMA_InitStructure_rx.DMA_Priority = DMA_Priority_VeryHigh; // High priority
  DMA_InitStructure_rx.DMA_DIR = DMA_DIR_PeripheralSRC;      // Peripheral to Memory 

  DMA_InitStructure_rx.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord; // 16-bit Register
  DMA_InitStructure_rx.DMA_PeripheralInc = DMA_PeripheralInc_Disable;            // Always write to same register
  DMA_InitStructure_rx.DMA_PeripheralBaseAddr = (uint32_t)&SPI1->DR;           // Output data for GPIO

  DMA_InitStructure_rx.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;         // 16-bit array
  DMA_InitStructure_rx.DMA_MemoryInc = DMA_MemoryInc_Enable;                     // Increment through array
  DMA_InitStructure_rx.DMA_MemoryBaseAddr = (uint32_t)&_internals.spi_rx_array;                 // 16-bit destination data

  DMA_InitStructure_rx.DMA_BufferSize = RX_BUFFER_SIZE;           // Size of destination array x 2
  _internals.spi_rx_remain = RX_BUFFER_SIZE;

  DMA_Init(DMA1_Channel2, &DMA_InitStructure_rx);            // Initialize DMA

  DMA_DeInit(DMA1_Channel3);                              // Reset DMA1 channe1 to default values;

  DMA_InitStructure_tx.DMA_M2M = DMA_M2M_Disable;            // M2M Disabled- Peripheral mode (requires timer trigger)
  DMA_InitStructure_tx.DMA_Mode = DMA_Mode_Normal;         // Circular mode
  DMA_InitStructure_tx.DMA_Priority = DMA_Priority_VeryHigh; // High priority
  DMA_InitStructure_tx.DMA_DIR = DMA_DIR_PeripheralDST;      // Memory to Peripheral

  DMA_InitStructure_tx.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord; // 16-bit Register
  DMA_InitStructure_tx.DMA_PeripheralInc = DMA_PeripheralInc_Disable;            // Always write to same register
  DMA_InitStructure_tx.DMA_PeripheralBaseAddr = (uint32_t)&SPI1->DR;           // Output data for GPIO

  DMA_InitStructure_tx.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;         // 16-bit array
  DMA_InitStructure_tx.DMA_MemoryInc = DMA_MemoryInc_Enable;                     // Increment through array
  DMA_InitStructure_tx.DMA_MemoryBaseAddr = (uint32_t)&_internals.spi_tx_array;             // 16-bit Source data
  _internals.spi_tx_start = 0;
  _internals.spi_tx_end = 0;
  _internals.spi_tx_array[TX_BUFFER_SIZE - 1] = get_spi_data(target_invalid, 0x00); //dummy byte for DMA slave (is repeated when master clocks before new DMA transfer is set up)

  DMA_InitStructure_tx.DMA_BufferSize = RX_BUFFER_SIZE;           // Size of source array x 2
  //spi_tx_remain = TX_BUFFER_BYTESIZE;

  DMA_Init(DMA1_Channel3, &DMA_InitStructure_tx);            // Initialize DMA

  // Enable channels
  DMA_Cmd(DMA1_Channel2, ENABLE);
  //DMA_Cmd(DMA1_Channel3, ENABLE);

  // Enable SPI TX/RX request
  //SPI_I2S_DMACmd(SPI1, SPI_I2S_DMAReq_Rx | SPI_I2S_DMAReq_Tx, ENABLE);
  SPI_I2S_DMACmd(SPI1, SPI_I2S_DMAReq_Rx, ENABLE);
}

/* initializes the spi interface */
static void pilot_pilot_comm_spi_init()
{
  GPIO_InitTypeDef gpio;
  SPI_InitTypeDef spi;

  /* enable the clocks for GPIOA and SPI1 */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_SPI1, ENABLE);

#ifdef STM32F4XX
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOA, ENABLE);
#else
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
#endif

#ifdef STM32F4XX
  /* configure the gpio pins as AF */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource5, GPIO_AF_SPI1 ); /* SPI1 CLK  */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource6, GPIO_AF_SPI1 ); /* SPI1 MISO */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource7, GPIO_AF_SPI1 ); /* SPI1 MOSI */
#endif

  /* Configure the GPIOs for SPI1 usage */
#ifdef STM32F4XX
  gpio.GPIO_Pin = GPIO_Pin_7 | GPIO_Pin_6 | GPIO_Pin_5;
  gpio.GPIO_Mode = GPIO_Mode_AF;
  gpio.GPIO_Speed = GPIO_Speed_100MHz;
  gpio.GPIO_OType = GPIO_OType_PP;
  gpio.GPIO_PuPd = GPIO_PuPd_DOWN;
  GPIO_Init(GPIOA, &gpio);
#else
  /* configure SCK and MOSI and CS0 pins as input floating */
  gpio.GPIO_Speed = GPIO_Speed_50MHz;
  gpio.GPIO_Pin = GPIO_Pin_7 | GPIO_Pin_5 | GPIO_Pin_4;
  gpio.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_Init(GPIOA, &gpio);

  /* configure MISO as alternate function push pull */
  gpio.GPIO_Pin = GPIO_Pin_6;
  gpio.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_Init(GPIOA, &gpio);
#endif

  /* configure spi */
  SPI_StructInit(&spi);
  spi.SPI_Direction = SPI_Direction_2Lines_FullDuplex;
  spi.SPI_Mode      = SPI_Mode_Slave;
  spi.SPI_DataSize  = SPI_DataSize_16b;
  spi.SPI_CPOL      = SPI_CPOL_Low;
  spi.SPI_CPHA      = SPI_CPHA_1Edge;
  spi.SPI_NSS       = SPI_NSS_Hard;     // ignore slave select channel, as we use it ourself
  spi.SPI_FirstBit  = SPI_FirstBit_MSB; // start with MSB
  spi.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_2; // setting baudrateprescaler is not necessary as slave, as the clk is generated by the master
  SPI_Init(SPI1, &spi);

  //SPI1->CR1 &= 0xFDFF; //CR1_SSM = 0
  //SPI1->CR2 &= 0xFFFB; //CR2_SSOE = 0 

  /* enable spi */
  SPI_Cmd(SPI1, ENABLE);

  /* fill the spi with invalid target data */
  SPI_I2S_SendData(SPI1, (uint16_t)(target_invalid << 8));
}

static void pilot_setup_spi_tx()
{
  NVIC_InitTypeDef NVIC_InitStructure_tx;
  uint16_t freebuff;

  if (_internals.spi_tx_start != _internals.spi_tx_end)
  { 
    freebuff = _internals.spi_tx_start < _internals.spi_tx_end ? 
                                    TX_BUFFER_SIZE - (_internals.spi_tx_end-_internals.spi_tx_start) :
                                    (_internals.spi_tx_start - _internals.spi_tx_end);
    if (freebuff < _internals.stats.tx_buffer_min)
      _internals.stats.tx_buffer_min = freebuff;

    /* there is data to send */
    if (!(DMA1_Channel3->CCR & DMA_CCR1_EN))
    {
      //always add a dummy frame at the end (the SPI slave keeps repeating the last byte when the master keeps clocking data)
      pilot_enqueue_spi_tx(get_spi_data(target_invalid, 0x00));

      if (_internals.spi_tx_start < _internals.spi_tx_end)
      { //data to send (no wraparound)
        _internals.spi_tx_current_end = _internals.spi_tx_end;
        DMA_InitStructure_tx.DMA_MemoryBaseAddr = (uint32_t)&_internals.spi_tx_array[_internals.spi_tx_start];
        DMA_InitStructure_tx.DMA_BufferSize = (_internals.spi_tx_current_end-_internals.spi_tx_start);
        DMA_Init(DMA1_Channel3, &DMA_InitStructure_tx);  // Initialize DMA

        NVIC_InitStructure_tx.NVIC_IRQChannel = DMA1_Channel3_IRQn;
        NVIC_InitStructure_tx.NVIC_IRQChannelPreemptionPriority = 0;
        NVIC_InitStructure_tx.NVIC_IRQChannelSubPriority = 0;
        NVIC_InitStructure_tx.NVIC_IRQChannelCmd = ENABLE;
        NVIC_Init(&NVIC_InitStructure_tx);
        DMA_ITConfig(DMA1_Channel3, DMA_IT_TC, ENABLE);

        DMA_Cmd(DMA1_Channel3, ENABLE);  //start DMA
        
        SPI_I2S_DMACmd(SPI1, SPI_I2S_DMAReq_Rx | SPI_I2S_DMAReq_Tx, ENABLE);
      }
      else if (_internals.spi_tx_start > _internals.spi_tx_end)
      { //wraparound, just read to end
        _internals.spi_tx_current_end = TX_BUFFER_SIZE;
        DMA_InitStructure_tx.DMA_MemoryBaseAddr = (uint32_t)&_internals.spi_tx_array[_internals.spi_tx_start];
        DMA_InitStructure_tx.DMA_BufferSize = (_internals.spi_tx_current_end-_internals.spi_tx_start);
        DMA_Init(DMA1_Channel3, &DMA_InitStructure_tx);  // Initialize DMA

        NVIC_InitStructure_tx.NVIC_IRQChannel = DMA1_Channel3_IRQn;
        NVIC_InitStructure_tx.NVIC_IRQChannelPreemptionPriority = 0;
        NVIC_InitStructure_tx.NVIC_IRQChannelSubPriority = 0;
        NVIC_InitStructure_tx.NVIC_IRQChannelCmd = ENABLE;
        NVIC_Init(&NVIC_InitStructure_tx);
        DMA_ITConfig(DMA1_Channel3, DMA_IT_TC, ENABLE);

        DMA_Cmd(DMA1_Channel3, ENABLE);  //start DMA
        
        SPI_I2S_DMACmd(SPI1, SPI_I2S_DMAReq_Rx | SPI_I2S_DMAReq_Tx, ENABLE);
      }

      /* inform the rpi that we have data to send */
      GPIO_WriteBit(GPIO_Pin_BOARD, GPIO_Pin_DATA_M2R, Bit_SET);
    }
  }
  else
  {
    /* we have no data to send */
    GPIO_WriteBit(GPIO_Pin_BOARD, GPIO_Pin_DATA_M2R, Bit_RESET);
  }
}

//called by interrupt handler when TX transfer is completed
void pilot_comm_spi_tx_done()
{
  //GPIO_WriteBit(GPIO_Pin_BOARD, GPIO_Pin_DATA_M2R, Bit_RESET);
  DMA_ClearITPendingBit(DMA1_IT_TC3); //mark interrupt as done
  _internals.spi_tx_start = _internals.spi_tx_current_end == TX_BUFFER_SIZE ? 0 : _internals.spi_tx_current_end;

  SPI_I2S_DMACmd(SPI1, SPI_I2S_DMAReq_Rx, ENABLE);
  DMA_Cmd(DMA1_Channel3, DISABLE);  //disable DMA

  //check if we still data to send, e.g. a circular buffer wraparound
  if (_internals.spi_tx_start != _internals.spi_tx_end) {
    pilot_setup_spi_tx();
  }
  else 
  {
    GPIO_WriteBit(GPIO_Pin_BOARD, GPIO_Pin_DATA_M2R, Bit_RESET);
  }
}

/* initializes the additional gpios used in the  <-> rpi communication */
static void pilot_pilot_comm_gpio_init()
{
  /* declare variables */
  GPIO_InitTypeDef outputs;
#ifdef STM32F4XX
  GPIOSpeed_TypeDef speed = GPIO_Speed_100MHz;
#else
  GPIOSpeed_TypeDef speed = GPIO_Speed_50MHz;
#endif

  /* enable the gpio clock */
#ifdef STM32F4XX
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOB, ENABLE);
#else
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);
#endif

  /* configure output gpios */
  outputs.GPIO_Pin   = GPIO_Pin_DATA_M2R;
  outputs.GPIO_Speed = speed;
#ifdef STM32F4XX
  outputs.GPIO_PuPd  = GPIO_PuPd_NOPULL;
  outputs.GPIO_Mode  = GPIO_Mode_OUT;
  outputs.GPIO_OType = GPIO_OType_PP;
#else
  outputs.GPIO_Mode  = GPIO_Mode_Out_PP;
#endif
  GPIO_Init(GPIOB, &outputs);
}

/* clear the outputs */
static void pilot_pilot_comm_gpio_clear()
{
  GPIO_WriteBit(GPIO_Pin_BOARD, GPIO_Pin_DATA_M2R, Bit_RESET);
}

static void pilot_pilot_comm_send_bufferstate_cmd(stm_bufferstate_t bufferstate)
{
  pilot_cmd_t cmd;
  
  /* fill the bufferstate command */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.type = pilot_cmd_type_bufferstate;
  cmd.data[(int)pilot_bufferstate_index_value] = bufferstate;
  cmd.length = MSG_LEN(4); //minimum length
  /* send the bufferstate cmd */
  pilot_comm_send_cmd(&cmd);
}

static void pilot_send_data_to_module(module_slot_t slot, module_port_t port, uint8_t data, uint16_t spidata)
{
$model.Modules:{module|
  if (slot == $module.Slot$)
  {
    if (port == module_port_1)
    {
      $if(module.Port1)$
      pilot_$module.Port1$_send_char(data);
      $endif$
    \}
    else if (port == module_port_2)
    {
      $if(module.Port2)$
      pilot_$module.Port2$_send_char(data);
      $endif$
    \}
  \}
};separator="\n"$

$model.SLCDs:{slcd|
  if (slot == $slcd.Slot$)
    pilot_$slcd.Name$_update_buffer_data(data);
};separator="\n"$

$model.FPGAs:{fpga|
  if (slot == $fpga.Slot$)
    pilot_$fpga.Name$_send_char(port, spidata);
};separator="\n"$

}

static void pilot_spi0_handle_received_cmd_byte(target_t target, uint8_t data)
{
  int i;
  uint32_t crcindex;
  uint8_t length_parity;
  uint32_t crc_check;
  
  if (target == target_base)
  {
    /* ...reset the cmd */
    _internals.current_cmd.index = pilot_current_cmd_index_target;
    _internals.current_cmd.cmd_completion = 0x0;
  }
  
  if (target - target_base == _internals.current_cmd.index && _internals.current_cmd.index < pilot_current_cmd_index_data_begin)
  { //header
    switch ((uint8_t)target)
    {
    case (uint8_t)target_base:_internals.current_cmd.cmd.target = (target_t)data; _internals.current_cmd.cmd_completion |= 0x1; break;
    case (uint8_t)target_base_type: _internals.current_cmd.cmd.type = (pilot_cmd_type_t)data; _internals.current_cmd.cmd_completion |= 0x2; break;
    case (uint8_t)target_base_length: 
      //calculate parity
      length_parity = data; 
      length_parity ^= length_parity >> 4;
      length_parity ^= length_parity >> 2;
      length_parity ^= length_parity >> 1;
      //if ((data & 0x80) == ((length_parity & 1) != 0 ? 0 : 0x80))
      {
        _internals.current_cmd.length = ((unsigned char)(data & 0x7F)) << 2; 
        _internals.current_cmd.cmd.length = data;
        _internals.current_cmd.cmd_completion |= 0x4; 
      }
      break;
    case (uint8_t)target_base_reserved: _internals.current_cmd.cmd.reserved = data; _internals.current_cmd.cmd_completion |= 0x8; break;
    default:
      //general error in transmission structure, reset
      _internals.current_cmd.cmd_completion = 0x0;
      break;
    }
  }
  else if (target == target_base_data && 
    _internals.current_cmd.index >= pilot_current_cmd_index_data_begin && 
    _internals.current_cmd.cmd_completion == 0xF)
  { //header done, data block
    _internals.current_cmd.cmd.data[_internals.current_cmd.index - pilot_current_cmd_index_data_begin] = data;
  }
  else if (target == target_base_crc)
  { //crc check
    crcindex = _internals.current_cmd.index - pilot_current_cmd_index_data_begin - _internals.current_cmd.length;
    if (crcindex < 4) 
    {
      ((uint8_t *)&_internals.current_cmd.cmd.crc)[crcindex] = data;
      _internals.current_cmd.cmd_completion |= (0x10 << crcindex);
    }
  }
  else
  {
    //general error in transmission structure, reset
    _internals.current_cmd.cmd_completion = 0x0;
  }

  /* increment the index */
  _internals.current_cmd.index++;

  /* is the received command completed? */
  if ((_internals.current_cmd.cmd_completion == 0xFF) && 
    (_internals.current_cmd.index >= pilot_cmd_t_size_without_data) && 
    (_internals.current_cmd.index >= (_internals.current_cmd.length + pilot_cmd_t_size_without_data)))
  {
    /* hardware CRC */
    CRC_ResetDR();
    CRC->DR = *((uint32_t*)&_internals.current_cmd.cmd);

    for (i = 0; i < _internals.current_cmd.length; i += 4)
      CRC->DR = *((uint32_t*)(((uint8_t*)&_internals.current_cmd.cmd.data[i])));

    crc_check = CRC->DR;

    /* reset the current cmd index */
    _internals.current_cmd.index = pilot_current_cmd_index_target;

    if (crc_check == _internals.current_cmd.cmd.crc) 
    {
      /* handle the command by copy */
      _internals.current_cmd.cmd.length &= 0x7F; //remove parity
      pilot_pilot_comm_spi_handle_cmd_complete(&_internals.current_cmd.cmd);
    }
    else
    {
      _internals.stats.crc_errors++;
    }
  }
}

void pilot_handle_received_data()
{
  uint16_t spidata;
  target_t target; uint8_t data;
  module_slot_t slot; module_port_t port;
  int remaining = 0;
  int cndtr = DMA1_Channel2->CNDTR;
  uint16_t freebuff = cndtr <= _internals.spi_rx_remain  ? 
                  RX_BUFFER_SIZE - (_internals.spi_rx_remain - cndtr) :
                  (cndtr - _internals.spi_rx_remain);

  if (freebuff < _internals.stats.rx_buffer_min)
    _internals.stats.rx_buffer_min = freebuff;

  pilot_setup_spi_tx(); //setup tx DMA if data is to be sent

  while (_internals.spi_rx_remain != cndtr)
  {
    remaining = RX_BUFFER_SIZE - _internals.spi_rx_remain;
    spidata = _internals.spi_rx_array[remaining];
    _internals.spi_rx_remain--; //16 bit reads
    if (_internals.spi_rx_remain == 0)
    {
      _internals.spi_rx_remain = RX_BUFFER_SIZE;
    }

    /* decode the spi data */
    target = (target_t) ((spidata >> 8) & 0x7F);

    if (target != target_invalid)
    {
      data = (uint8_t) (spidata & 0xFF);

      /* handle the data according to it's target */
      /* if it's targetted at the base, it's a cmd byte */
      if (target >= target_base)
      {
          /* fill the current cmd */
        pilot_spi0_handle_received_cmd_byte(target, data);
      }
      else if (target == target_plc_read)
      { /* forward the data to the plc */
        pilot_comm_handle_plc_readdata(data);
      }
      else if (target == target_plc_write)
      {
        pilot_comm_handle_plc_writedata(data);
      }
      else /* forward the data to the specified module */
      {
        slot = target_t_get_module_slot(target);
        port = target_t_get_module_port(target);

        if (slot >= 0 && slot < 4 && port >= 0 && port < 2)
        {
          /* routing of module_slot & module_port -> usart/spi */
          pilot_send_data_to_module(slot, port, data, spidata);
        }
        else
        {
          printf("Unknown slot %i, port %i\r\n", slot, port);	   
        }
      }
    }
  }
}

static int pilot_stm_proto_baudrate_to_int(pilot_cmd_baudrate_t value)
{
  int baudrate;

  switch (value)
  {
    case pilot_cmd_baudrate_9600: baudrate = 9600; break;
    case pilot_cmd_baudrate_19200: baudrate = 19200; break;
    case pilot_cmd_baudrate_38400: baudrate = 38400; break;
    case pilot_cmd_baudrate_57600: baudrate = 57600; break;
    case pilot_cmd_baudrate_115200: baudrate = 115200; break;
    case pilot_cmd_baudrate_230400: baudrate = 230400; break;
    case pilot_cmd_baudrate_250000: baudrate = 250000; break;
    default: baudrate = 9600; break;
  }

  return baudrate;
}


static uint16_t pilot_pilot_comm_spi_get_mc_stopbits(pilot_cmd_stopbits_t pilot_stopbits)
{
  uint16_t mc_stopbits;
  switch (pilot_stopbits)
  {
    case pilot_cmd_stopbits_2: mc_stopbits = USART_StopBits_2; break;
    default:
    case pilot_cmd_stopbits_1: mc_stopbits = USART_StopBits_1; break;
  }

  return mc_stopbits;
}

static uint16_t pilot_pilot_comm_spi_get_mc_parity(pilot_cmd_parity_t pilot_parity)
{
  uint16_t mc_parity;
  switch (pilot_parity)
  {
    case pilot_cmd_parity_even: mc_parity = USART_Parity_Even; break;
    case pilot_cmd_parity_odd: mc_parity  = USART_Parity_Odd; break;
    default:
    case pilot_cmd_parity_none: mc_parity = USART_Parity_No; break;
  }
  return mc_parity;
}

static uint16_t pilot_pilot_comm_spi_get_mc_wordlength(pilot_cmd_wordlength_t pilot_wordlength)
{
  uint16_t mc_databits;
  switch (pilot_wordlength)
  {
    default:
    case pilot_cmd_wordlength_8: mc_databits = USART_WordLength_8b; break;
    case pilot_cmd_wordlength_9: mc_databits = USART_WordLength_9b; break;
  }
  return mc_databits;
}

void pilot_comm_set_baudrate(module_slot_t slot, module_port_t port, int baudrate)
{
$model.Modules:{module|
  if (slot == $module.Slot$) {
   if (port == module_port_1) {
     $if(module.Port1)$
     pilot_$module.Port1$_set_baudrate(baudrate);
     $endif$
   \} else if (port == module_port_2) {
     $if(module.Port2)$
     pilot_$module.Port2$_set_baudrate(baudrate);
     $endif$
   \}
  \}
};separator="\n"$
}

void pilot_comm_set_stopbits(module_slot_t slot, module_port_t port, uint16_t stopbits)
{
$model.Modules:{module|
  if (slot == $module.Slot$) {
   if (port == module_port_1) {
     $if(module.Port1)$
     pilot_$module.Port1$_set_stopbits(stopbits);
     $endif$
   \} else if (port == module_port_2) {
     $if(module.Port2)$
     pilot_$module.Port2$_set_stopbits(stopbits);
     $endif$
   \}
  \}
};separator="\n"$
}

void pilot_comm_set_parity(module_slot_t slot, module_port_t port, uint16_t parity)
{
$model.Modules:{module|
  if (slot == $module.Slot$) {
   if (port == module_port_1) {
     $if(module.Port1)$
     pilot_$module.Port1$_set_parity(parity);
     $endif$
   \} else if (port == module_port_2) {
     $if(module.Port2)$
     pilot_$module.Port2$_set_parity(parity);
     $endif$
    \}
  \}
};separator="\n"$
}

void pilot_comm_set_wordlength(module_slot_t slot, module_port_t port, uint16_t wordlength)
{
$model.Modules:{module|
  if (slot == $module.Slot$) {
   if (port == module_port_1) {
     $if(module.Port1)$
     pilot_$module.Port1$_set_wordlength(wordlength);
     $endif$
   \} else if (port == module_port_2) {
     $if(module.Port2)$
     pilot_$module.Port2$_set_wordlength(wordlength);
     $endif$
   \}
  \}
};separator="\n"$
}

static void pilot_pilot_comm_get_input_state_cmd(module_slot_t slot, uint8_t input, pilot_cmd_t *cmd)
{
  uint32_t value;
  $if(model.IA8s)$
  uint16_t ia_value;
  $endif$
  $if(model.IO16s)$
  uint8_t io16_value;
  $endif$  
  $if(model.AIO20s)$
  uint16_t aio_value;
  $endif$

  switch (slot)
  {
    $model.I8s:{i8|case $i8.Slot$: value = $i8.Name$_get_state(input); break;};separator="\n"$
    $model.IA8s:{ia8|case $ia8.Slot$:
      pilot_$ia8.Name$_get_value(input, &ia_value);
      value = ia_value;
      break;
    };separator="\n"$
    $model.IO16s:{io16|case $io16.Slot$:
      pilot_$io16.Name$_get_value(input, &io16_value);
      value = io16_value;
      break;
    };separator="\n"$
    $model.AIO20s:{aio20|case $aio20.Slot$:
      single_ended_adc_read($aio20.Slot$, (MAX11300_Ports) input, &aio_value);
      value = aio_value;
      break;
    };separator="\n"$
    default: value = (uint32_t)-1; break;
  }

  /* fill the rpcp cmd */
  memset(cmd, 0, sizeof(pilot_cmd_t));
  cmd->target = target_t_from_module_slot_and_port(slot, 0);
  cmd->type = pilot_cmd_type_input_get_input;
  cmd->data[(int)pilot_input_index_target] = input;
  cmd->data[(int)pilot_input_index_value + 0] = (value >> 3*8) & 0xFF;
  cmd->data[(int)pilot_input_index_value + 1] = (value >> 2*8) & 0xFF;
  cmd->data[(int)pilot_input_index_value + 2] = (value >> 1*8) & 0xFF;
  cmd->data[(int)pilot_input_index_value + 3] = (value >> 0*8) & 0xFF;
  cmd->length = MSG_LEN(8);
}

static void pilot_pilot_comm_send_input_state(module_slot_t slot, uint8_t input)
{
  pilot_cmd_t cmd;

  /* get a command that contains the input state */
  pilot_pilot_comm_get_input_state_cmd(slot, input, &cmd);

  /* send the input state cmd */
  pilot_comm_send_cmd(&cmd);
}

/* sends the counter values to the rpi */
static void pilot_pilot_comm_get_counter_values(module_slot_t slot, pilot_counter_target_t counter_target)
{
$if(model.Counter8s)$
  pilot_cmd_t cmd; int counter_index;
$endif$

$model.Counter8s:{counter8|
  if (slot == $counter8.Slot$)
  {
    /* if we're getting all counters */
    if (counter_target == pilot_counter_target_all) {
      for (counter_index = 0; counter_index < COUNTERS_COUNT; counter_index++) {
        pilot_$counter8.Name$_get_counter_cmd(&cmd, counter_index); /* update the command for module <counter8.Slot> and the counter */
        pilot_comm_send_cmd(&cmd);                      /* send the command  */
      \}
    \}

    /* if we're getting a single counter, do a sanity check */
    else if ((int)counter_target >= 0 && counter_target < COUNTERS_COUNT) {
      pilot_$counter8.Name$_get_counter_cmd(&cmd, counter_target);
      pilot_comm_send_cmd(&cmd);
    \}
  \}
};separator="\n"$

}

static void pilot_pilot_comm_send_rtc()
{
  pilot_cmd_t cmd;

  /* get a command that contains the current datetime */
  rtc_get_datetime_cmd(&cmd);

  /* send the rtc cmd */
  pilot_comm_send_cmd(&cmd);
}

void pilot_comm_send_input_changed(module_slot_t slot)
{
  pilot_cmd_t cmd;

  /* generate the input changed cmd */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_t_from_module_slot_and_port(slot, 0);
  cmd.type = pilot_cmd_type_input_changed;
  cmd.length = 0; //TODO - send the changed input as well
  pilot_comm_send_cmd(&cmd);
}

//START LORA
static void pilot_rpi_lora_set_enable(module_slot_t slot, int enable)
{
$model.LORAs:{lora|
  if (slot == $lora.Slot$)
  {
    pilot_$lora.Name$_set_enable(enable);
  \}
};separator="\n"$
}

static void pilot_rpi_lora_get_enable(module_slot_t slot)
{
$if(model.LORAs)$
  int enabled;
  pilot_cmd_t cmd;

  /* get the state */
  switch (slot)
  {
$model.LORAs:{lora|
    case $lora.Slot$: enabled = pilot_$lora.Name$_get_enable(); break;
};separator="\n"$
    default: return;
  }

  /* create and send the answer */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_t_from_module_slot_and_port(slot, 0),
  cmd.type = pilot_cmd_type_lora_get_enable;
  cmd.data[(int)pilot_lora_enable_index_value] = enabled;
  cmd.length = MSG_LEN(4); //minimum length
  pilot_comm_send_cmd(&cmd);
$endif$
}
//END LORA

static void pilot_rpi_gps_set_enable(module_slot_t slot, int enable)
{
$model.GPSs:{gps|
  if (slot == $gps.Slot$)
  {
    pilot_$gps.Name$_set_enable(enable);
  \}
};separator="\n"$
}

static void pilot_rpi_gps_get_enable(module_slot_t slot)
{
$if(model.GPSs)$
  int enabled;
  pilot_cmd_t cmd;

  /* get the state */
  switch (slot)
  {
$model.GPSs:{gps|
    case $gps.Slot$: enabled = pilot_$gps.Name$_get_enable(); break;
};separator="\n"$
    default: return;
  }

  /* create and send the answer */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_t_from_module_slot_and_port(slot, 0),
  cmd.type = pilot_cmd_type_gps_get_enable;
  cmd.data[(int)pilot_gps_enable_index_value] = enabled;
  cmd.length = MSG_LEN(4); //minimum length
  pilot_comm_send_cmd(&cmd);
$endif$
}

static void pilot_rpi_gsm_set_enable(module_slot_t slot, int enable)
{
$model.GSMs:{gsm|
if (slot == $gsm.Slot$)
  pilot_$gsm.Name$_set_enable(enable);
}; separator = "\n"$
}

static void pilot_rpi_gsm_get_enable(module_slot_t slot)
{
$if(model.GSMs)$
  pilot_cmd_t cmd;
  int enabled;

  /* get the state */
  switch (slot)
  {
$model.GSMs:{gsm |
  case $gsm.Slot$: enabled = pilot_$gsm.Name$_get_enable(); break;
}; separator = "\n"$
    default: return;
  }

  /* create and the answer */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_t_from_module_slot_and_port(slot, 0);
  cmd.type = pilot_cmd_type_gsm_get_enable;
  cmd.data[(int)pilot_gsm_enable_index_value] = enabled;
  cmd.length = MSG_LEN(4); //minimum length
  pilot_comm_send_cmd(&cmd);
$endif$
}

static void pilot_rpi_onewire_set_enable(module_slot_t slot, int enable)
{
  $model.OneWires:{ow|
    if (slot == $ow.Slot$)
      pilot_$ow.Name$_set_enable(enable);
  };separator="\n"$
}

static void pilot_rpi_onewire_get_enable(module_slot_t slot)
{
$if(model.OneWires)$
  int enabled;
  pilot_cmd_t cmd;

  /* get the state */
  switch ((int)slot)
  {
$model.OneWires:{ow|
    case $ow.Slot$: enabled = pilot_$ow.Name$_get_enable(); break;
};separator="\n"$
    default: return;
  }

  /* create and send the answer */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_t_from_module_slot_and_port(slot, 0);
  cmd.type = pilot_cmd_type_onewire_get_enable;
  cmd.data[(int)pilot_onewire_enable_index_value] = enabled;
  cmd.length = MSG_LEN(4); //minimum length
  pilot_comm_send_cmd(&cmd);
$endif$
}

static void pilot_rpi_slcd_update(module_slot_t slot)
{
$if(model.SLCDs)$
  switch ((int)slot)
  {
$model.SLCDs:{slcd|
  case $slcd.Slot$: pilot_$slcd.Name$_update_buffer_start();
};separator="\n"$
  }
$endif$
}

static void pilot_rpi_slcd_get_resolution(module_slot_t slot)
{
$if(model.SLCDs)$

  int i;
  pilot_cmd_t cmd;
  slcd_resolution_t resolution;

  switch ((int)slot)
  {
$model.SLCDs:{slcd|
  case $slcd.Slot$: pilot_$slcd.Name$_get_resolution(&resolution); break;
};separator="\n"$
  }

  /* setup the answer */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_t_from_module_slot_and_port(slot, 0);
  cmd.type = pilot_cmd_type_slcd_get_resolution;
  for (i = 0; i < sizeof(int32_t); i++)
    cmd.data[(int)pilot_slcd_resolution_index_width + i] = BYTE_FROM_INT(resolution.width, i);
  for (i = 0; i < sizeof(int32_t); i++)
    cmd.data[(int)pilot_slcd_resolution_index_height + i] = BYTE_FROM_INT(resolution.height, i);

  /* send the command */
  cmd.length = MSG_LEN(8);
  pilot_comm_send_cmd(&cmd);

$endif$
}

static void pilot_rpi_slcd_set_resolution(module_slot_t slot, pilot_cmd_t *cmd)
{
$if(model.SLCDs)$
  slcd_resolution_t resolution;

  resolution.width = INT_FROM_BYTES( (cmd->data + (int)pilot_slcd_resolution_index_width) );
  resolution.height = INT_FROM_BYTES( (cmd->data + (int)pilot_slcd_resolution_index_height) );

  /* update the resolution */
  switch ((int)slot)
  {
$model.SLCDs:{slcd|
    case $slcd.Slot$: pilot_$slcd.Name$_set_resolution(&resolution); break;
};separator="\n"$
  }
$endif$
}

static void pilot_pilot_comm_set_output(module_slot_t slot, pilot_output_target_t output, uint16_t value)
{
  switch (slot)
  {
    $model.O8s:{o8|case $o8.Slot$: pilot_$o8.Name$_set_value(output, value); break;};separator="\n"$
    $model.IO16s:{io16|case $io16.Slot$: pilot_$io16.Name$_set_value(output, value); break;};separator="\n"$
    $model.AIO20s:{aio20|case $aio20.Slot$: single_ended_dac_write($aio20.Slot$, output, value); break;};separator="\n"$
  }
}

static void pilot_rpi_io16_set_direction(module_slot_t slot, pilot_io16_block_t block, pilot_io16_direction_t direction)
{
  switch (slot)
  {
    $model.IO16s:{io16|case $io16.Slot$: pilot_$io16.Name$_set_direction(block, direction); break;};separator="\n"$
  }
}

static void pilot_comm_get_board_uid()
{
  int i; pilot_cmd_t cmd; uint32_t uid;

  /* setup the cmd */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_base;
  cmd.type = pilot_cmd_type_eeprom_uid_get;

  /* read the uid from the base eeprom */
  if (pilot_eeprom_get_board_uid(&uid))
  {
    /* encode the uid in the cmd data */
    for (i = 0; i < 4; i++)
      cmd.data[i] = BYTE_FROM_INT(uid, i);
  }

  /* send the reply */
  cmd.length = MSG_LEN(4);
  pilot_comm_send_cmd(&cmd);
}

static void pilot_comm_get_uid(module_slot_t module_slot)
{
  int i; pilot_cmd_t cmd; pilot_eeprom_uid_t uid;

  /* setup the cmd */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_t_from_module_slot_and_port(module_slot, module_port_1);
  cmd.type = pilot_cmd_type_eeprom_uid_get;

  /* read the uid from the module's eeprom */
  if (pilot_eeprom_get_module_uid(module_slot, &uid))
  {
    /* encode the uid in the cmd data */
    for (i = 0; i < pilot_cmd_t_data_size && i < EEPROM_UID_LENGTH; i++)
      cmd.data[i] = uid.uid[i];
  }

  /* send the reply */
  cmd.length = MSG_LEN(EEPROM_UID_LENGTH);
  pilot_comm_send_cmd(&cmd);
}

static void pilot_comm_get_hid(module_slot_t module_slot)
{
  int i; pilot_cmd_t cmd; pilot_eeprom_hid_t hid; pilot_eeprom_uid_t uid;

  /* setup the cmd */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_t_from_module_slot_and_port(module_slot, module_port_1);
  cmd.type = pilot_cmd_type_eeprom_hid_get;

  /* every mem cmd must start with an rom cmd */
  if (pilot_eeprom_get_module_uid(module_slot, &uid))
  {
    /* read the hid from the module's eeprom */
    pilot_eeprom_get_module_hid(module_slot, &hid);

    /* encode the hid in the cmd data */
    for (i = 0; i < pilot_cmd_t_data_size && i < EEPROM_HID_LENGTH; i++)
      cmd.data[i] = hid.data[i];
  }

  /* send the reply */
  cmd.length = MSG_LEN(EEPROM_HID_LENGTH);
  pilot_comm_send_cmd(&cmd);
}

static void pilot_comm_set_hid(module_slot_t module_slot, pilot_cmd_t *cmd)
{
  pilot_eeprom_uid_t uid;
  pilot_eeprom_hid_t hid;
  int i; 

  /* decode the hid from the cmd data */
  for (i = 0; i < pilot_cmd_t_data_size && i < EEPROM_HID_LENGTH; i++)
    hid.data[i] = cmd->data[i];

  /* every mem cmd must start with the an rom cmd */
  pilot_eeprom_get_module_uid(module_slot, &uid);

  /* try to set the hid of module */
  pilot_eeprom_set_module_hid(module_slot, &hid);
}

static void pilot_comm_get_fid(module_slot_t module_slot)
{
  int i; pilot_cmd_t cmd; pilot_eeprom_fid_t fid; pilot_eeprom_uid_t uid;

  /* setup the cmd */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_t_from_module_slot_and_port(module_slot, module_port_1);
  cmd.type = pilot_cmd_type_eeprom_fid_get;

  /* every mem cmd must start with an rom cmd */
  if (pilot_eeprom_get_module_uid(module_slot, &uid))
  {
    /* read the fid from the module's eeprom */
    pilot_eeprom_get_module_fid(module_slot, &fid);

    /* encode the fid in the cmd data */
    for (i = 0; i < pilot_cmd_t_data_size && i < EEPROM_FID_LENGTH; i++)
      cmd.data[i] = fid.data[i];
  }

  /* send the reply */
  cmd.length = MSG_LEN(EEPROM_FID_LENGTH);
  pilot_comm_send_cmd(&cmd);
}

static void pilot_comm_set_fid(module_slot_t module_slot, pilot_cmd_t *cmd)
{
  pilot_eeprom_uid_t uid;
  pilot_eeprom_fid_t fid;
  int i; 

  /* decode the fid from the cmd data */
  for (i = 0; i < pilot_cmd_t_data_size && i < EEPROM_FID_LENGTH; i++)
    fid.data[i] = cmd->data[i];

  /* every mem cmd must start with the rom cmd */
  pilot_eeprom_get_module_uid(module_slot, &uid);

  /* try to set the fid of module */
  pilot_eeprom_set_module_fid(module_slot, &fid);
}

static void pilot_comm_get_eeprom_userdata(module_slot_t module_slot, const pilot_cmd_t *cmd)
{
  int i; pilot_cmd_t reply; pilot_eeprom_uid_t uid; pilot_eeprom_data_t data;

  /* get the user data index */
  int data_index = cmd->data[pilot_eeprom_userdata_index_number];

  /* every mem cmd must start with an rom cmd */
  if (pilot_eeprom_get_module_uid(module_slot, &uid))
  {
    /* read the user data from the module's eeprom */
    pilot_eeprom_get_module_userdata(module_slot, data_index, &data);
  }

  /* setup the reply */
  memset(&reply, 0, sizeof(pilot_cmd_t));
  reply.target = eeprom_encode_module_slot_and_data_index(module_slot, data_index);
  reply.type = pilot_cmd_type_eeprom_userdata_get;
  for (i = 0; i < pilot_cmd_t_data_size && i < EEPROM_DATA_LENGTH; i++)
    reply.data[i] = data.data[i];

  /* send the reply */
  reply.length = MSG_LEN(EEPROM_DATA_LENGTH);
  pilot_comm_send_cmd(&reply);
}

static void pilot_comm_set_eeprom_userdata(const pilot_cmd_t *cmd)
{
  pilot_eeprom_uid_t uid;
  pilot_eeprom_data_t data;
  int i;

  /* get the user data index */
  int data_index = eeprom_decode_data_index(cmd->target);
  int module_slot = eeprom_decode_module_slot(cmd->target);

  /* get the user data from the cmd */
  for (i = 0; i < pilot_cmd_t_data_size && i < EEPROM_DATA_LENGTH; i++)
    data.data[i] = cmd->data[i];

  /* every mem cmd must start with the rom cmd */
  pilot_eeprom_get_module_uid(module_slot, &uid);

  /* try to set the user data block */
  pilot_eeprom_set_module_userdata(module_slot, data_index, &data);
}

static void pilot_comm_get_module_type(module_slot_t module_slot)
{
  int i;
  /* setup the cmd */
  pilot_cmd_t cmd;
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_t_from_module_slot_and_port(module_slot, module_port_1);
  cmd.type   = pilot_cmd_type_module_type_get;

  /* copy module type to the data */
  switch (module_slot)
  {
$model.Modules:{m|
    case $m.Slot$: strncpy(cmd.data, "$m.Name$", pilot_cmd_t_data_size); break;
};separator="\n"$
    default: break;
  }

  /* send the reply */
  cmd.length = MSG_LEN(8);
  pilot_comm_send_cmd(&cmd);
}

/* global plc variables */
extern int plc_state;
extern cycletimes_t cycles;
extern unsigned long long __tick;

static void pilot_rpi_plc_state_get()
{
  pilot_cmd_t cmd;
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_base;
  cmd.type = pilot_cmd_type_plc_state_get;
  cmd.data[(int)pilot_plc_state_index] = plc_state;
  cmd.length = MSG_LEN(4);
  pilot_comm_send_cmd(&cmd);
}

static void pilot_rpi_plc_state_set(pilot_cmd_t *cmd)
{
  plc_state = (int)cmd->data[(int)pilot_plc_state_index];
}

static void pilot_rpi_plc_cycletimes_get()
{
  int i;
  pilot_cmd_t cmd;
  uint16_t min, max, cur, tick, comm, read, program, write;
  /* get the current values */
  min = (uint16_t) (cycles.cycle_min / ($model.ClockSpeed$ / 1000000));
  max = (uint16_t) (cycles.cycle_max / ($model.ClockSpeed$ / 1000000));
  cur = (uint16_t) (cycles.cycle_current / ($model.ClockSpeed$ / 1000000));
  comm = (uint16_t) ((cycles.cycle_current_comm-cycles.cycle_start) / ($model.ClockSpeed$ / 1000000));
  read = (uint16_t) ((cycles.cycle_current_read-cycles.cycle_current_comm)/ ($model.ClockSpeed$ / 1000000));
  program = (uint16_t) ((cycles.cycle_current_program-cycles.cycle_current_read) / ($model.ClockSpeed$ / 1000000));
  write = (uint16_t) ((cycles.cycle_current_write-cycles.cycle_current_program) / ($model.ClockSpeed$ / 1000000));
  tick = (uint16_t) __tick;

  /* create the answer */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_base;
  cmd.type = pilot_cmd_type_plc_cycletimes_get;
  for (i = 0; i < sizeof(min); i++)
    cmd.data[(int)pilot_plc_cycletimes_index_min + i] = BYTE_FROM_UINT16(min, i);
  for (i = 0; i < sizeof(max); i++)
    cmd.data[(int)pilot_plc_cycletimes_index_max + i] = BYTE_FROM_UINT16(max, i);
  for (i = 0; i < sizeof(cur); i++)
    cmd.data[(int)pilot_plc_cycletimes_index_cur + i] = BYTE_FROM_UINT16(cur, i);
  for (i = 0; i < sizeof(tick); i++)
    cmd.data[(int)pilot_plc_cycletimes_index_tick + i] = BYTE_FROM_UINT16(tick, i);

  for (i = 0; i < sizeof(comm); i++)
    cmd.data[(int)pilot_plc_cycletimes_index_comm + i] = BYTE_FROM_UINT16(comm, i);
  for (i = 0; i < sizeof(read); i++)
    cmd.data[(int)pilot_plc_cycletimes_index_read + i] = BYTE_FROM_UINT16(read, i);
  for (i = 0; i < sizeof(program); i++)
    cmd.data[(int)pilot_plc_cycletimes_index_program + i] = BYTE_FROM_UINT16(program, i);
  for (i = 0; i < sizeof(write); i++)
    cmd.data[(int)pilot_plc_cycletimes_index_write + i] = BYTE_FROM_UINT16(write, i);

  /* send the answer */
  cmd.length = MSG_LEN(16);
  pilot_comm_send_cmd(&cmd);
}

static void pilot_rpi_plc_variables_read_config(pilot_cmd_t *cmd)
{
  /* prepare to receive the variables numbers */
  _internals.plc.read_config.expected = INT_FROM_BYTES((cmd->data + (int)pilot_plc_variables_value_index_size));
  _internals.plc.read_config.count = 0;
  _internals.plc.read_config.has_last_char  = 0;
}

static void pilot_rpi_plc_variables_read_config_reply(int successful)
{
  pilot_cmd_t cmd;
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_base;
  cmd.type = pilot_cmd_type_plc_variables_read_config;
  cmd.data[0] = successful ? 1 : 0;
  cmd.length = MSG_LEN(4);
  
  pilot_comm_send_cmd(&cmd);
}

static void pilot_comm_handle_plc_readdata(char data)
{
  uint16_t number;
  pilot_plc_vars_config_t *cfg = &_internals.plc.read_config;

  /* collect the plc data */
  if (cfg->count < MAX_PLC_VARS)
  {
    /* keep the first byte */
    if (!cfg->has_last_char)
    {
      cfg->last_char = data;
      cfg->has_last_char = 1;
    }
    else
    {
      /* complete the number of the second byte */
      number = (uint16_t) ( (data << 8) | cfg->last_char );
      cfg->numbers[cfg->count++] = number;
      cfg->has_last_char = 0;

      /* check if we have received the expected number of variables */
      if (cfg->count == cfg->expected)
      {
        /* configure plc variables */
        _internals.plc.read_values.size = plc_configure_read_variables(cfg->numbers, cfg->count);

        /* send a variables config reply to signal that the configuration is complete */
        pilot_rpi_plc_variables_read_config_reply(_internals.plc.read_values.size <= MAX_PLC_VARS_SIZE);
      }
    }
  }
}

static void pilot_rpi_plc_variables_write_config(pilot_cmd_t *cmd)
{
  /* prepare to receive the variable numbers */
  _internals.plc.write_config.expected = INT_FROM_BYTES((cmd->data + (int)pilot_plc_variables_value_index_size));
  _internals.plc.write_config.count = 0;
  _internals.plc.write_config.has_last_char = 0;
}

static void pilot_rpi_plc_variables_write_config_reply(int successful)
{
  pilot_cmd_t cmd;
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_base;
  cmd.type = pilot_cmd_type_plc_variables_write_config;
  cmd.data[0] = successful ? 1 : 0;
  cmd.length = MSG_LEN(4);
  pilot_comm_send_cmd(&cmd);
}

static void pilot_comm_handle_plc_writeconfig(pilot_plc_vars_config_t *cfg, char data)
{
  uint16_t number;

  /* collect the plc data */
  if (cfg->count < MAX_PLC_VARS)
  {
    /* keep the first byte */
    if (!cfg->has_last_char)
    {
      cfg->last_char = data;
      cfg->has_last_char = 1;
    }
    else
    {
      /* complete the number of the second byte */
      number = (uint16_t)((data << 8) | cfg->last_char);
      cfg->numbers[cfg->count++] = number;
      cfg->has_last_char = 0;

      /* check if we have received the expected number of variables */
      if (cfg->count == cfg->expected)
      {
        /* configure plc write variables */
        plc_configure_write_variables(cfg->numbers, cfg->count);

        /* send a variables config reply to signal that the configuration is complete */
        pilot_rpi_plc_variables_write_config_reply(1);
      }
    }
  }
}

static void pilot_rpi_plc_variables_write_values_reply()
{
  pilot_cmd_t cmd;
  /* setup the cmd */
  memset(&cmd, 0, sizeof(pilot_cmd_t));
  cmd.target = target_plc_write;
  cmd.type = pilot_cmd_type_plc_variables_set;
  
  /* send the cmd */
  cmd.length = 0; //no payload
  pilot_comm_send_cmd(&cmd);
}

static void pilot_comm_handle_plc_writevalues(pilot_plc_vars_write_values_t *val, char data)
{
  /* if there is room in the buffer */
  if (val->count < MAX_PLC_VARS_SIZE)
  {
    /* add the data to the buffer */
    val->buffer[val->count++] = data;

    /* if we have received the expected number of bytes */
    if (val->count == val->expected)
    {
      /* write the variables */
      plc_write_variables(val->buffer, val->count);

      /* send a variables value set reply to signal that the values setting is complete */
      pilot_rpi_plc_variables_write_values_reply();
    }
  }
}

/* is called when a variable subscription event happens */
void pilot_comm_send_subscribed_plc_variable(int plc_variable_number)
{  
  if (plc_variable_number != -1 && _internals.bufferstate != stm_bufferstate_full)
  {
    pilot_cmd_t cmd;
    /* setup the cmd */
    memset(&cmd, 0, sizeof(pilot_cmd_t));
    cmd.target = target_base;
    cmd.type = pilot_cmd_type_plc_variable_get;
 
    plc_read_from_variable(plc_variable_number, 1, cmd.data, pilot_cmd_t_data_size);

    *((uint16_t *)&cmd.data[8]) = plc_variable_number | PLC_VAR_SUBSCRIBE_BIT;

    /* send the answer */
    cmd.length = MSG_LEN(12);
    pilot_comm_send_cmd(&cmd);
  }  
}

/* is called when receiving stream data with target plc write,
   used for the write configuration and the write values */
static void pilot_comm_handle_plc_writedata(char data)
{
  pilot_plc_vars_config_t *cfg = &_internals.plc.write_config;
  pilot_plc_vars_write_values_t *val = &_internals.plc.write_values;

  /* is the data supposed to be write configuration? */
  if (cfg->count < cfg->expected)
    pilot_comm_handle_plc_writeconfig(cfg, data);
  /* is the data supposed to be a write value? */
  else if(val->count < val->expected)
    pilot_comm_handle_plc_writevalues(val, data);

}

static void pilot_rpi_plc_variables_get_reply(int size)
{
  int i;
  /* prepare the reply to plc variables get command */
  pilot_cmd_t cmd;
  memset(&cmd, 0, sizeof(cmd));
  cmd.target = target_base;
  cmd.type = pilot_cmd_type_plc_variables_get;

  for (i = 0; i < sizeof(int); i++)
    cmd.data[(int)pilot_plc_variables_value_index_size + i] = BYTE_FROM_INT(size, i);

  /* send the answer with the size of the variables */
  cmd.length = MSG_LEN(8);
  pilot_comm_send_cmd(&cmd);

}

/* is called when the plc variables get cmd is received */
static void pilot_rpi_plc_variables_get()
{
  int actual_size;
  pilot_plc_vars_values_t *values = &_internals.plc.read_values;

  /* send the variable values back as a stream */
  if (values->size > 0 && values->size <= MAX_PLC_VARS_SIZE)
  {
    /* update the values buffer */
    actual_size = plc_read_variables(_internals.plc.read_values.buffer);

    /* send the variables get reply */
    pilot_rpi_plc_variables_get_reply(actual_size);

    /* send the variable values back as a stream */
    pilot_comm_send(target_plc_read, _internals.plc.read_values.buffer, actual_size);
  }

}

/* is called when the plc variable get cmd is received */
static void pilot_rpi_plc_variable_get(pilot_cmd_t * cmd)
{
  plc_read_from_variable(*((uint16_t *)&cmd->data[8]), 0, cmd->data, pilot_cmd_t_data_size);
  *((uint16_t *)&cmd->data[8]) &= 0xFFF; //remove flags for reply

  /* send the answer */
  cmd->length = MSG_LEN(12); //TODO make size dynamic depending on var size
  pilot_comm_send_cmd(cmd);
}

/* is called when the plc variable get cmd is received */
static void pilot_rpi_plc_variable_set(pilot_cmd_t * cmd)
{
  plc_write_to_variable(*((uint16_t *)&cmd->data[8]), 0, (uint8_t *)cmd->data, pilot_cmd_t_data_size);
 
  /* send the answer */
  cmd->length = MSG_LEN(12); //TODO make size dynamic depending on var size
  pilot_comm_send_cmd(cmd);
}

/* is called when the plc variables set cmd is received */
static void pilot_rpi_plc_variables_set(pilot_cmd_t *cmd)
{
  /* expect a variables command stream */
  _internals.plc.write_values.expected = INT_FROM_BYTES((cmd->data + (int)pilot_plc_variables_value_index_size));
  _internals.plc.write_values.count = 0;
}

static void pilot_comm_run_test(pilot_cmd_t *cmd)
{
  pilot_cmd_t reply;
  memset(&reply, 0, sizeof(pilot_cmd_t));
  reply.target = target_base;
  reply.type = pilot_cmd_type_test_run;

$if(model.IsTest)$
  /* if it's a test image, conduct the test */
  testresult_t result;
  memset(&result, 0, sizeof(testresult_t));
  bool successful;
  /* run the test */
  successful = pilot_test_run(&result);
  reply.data[(uint8_t)(int)pilot_test_run_index_result] = successful ? pilot_test_run_result_success : pilot_test_run_result_failed;
  reply.data[(uint8_t)(int)pilot_test_run_index_failed_count] = (uint8_t)result.count_failed;
  reply.data[(uint8_t)(int)pilot_test_run_index_success_count] = (uint8_t)result.count_success;
  reply.data[(uint8_t)(int)pilot_test_run_index_total_count] = (uint8_t)result.count_tested;
  reply.data[(uint8_t)(int)pilot_test_run_index_failed_low_count] = (uint8_t)result.count_failed_low;
  reply.data[(uint8_t)(int)pilot_test_run_index_failed_high_count] = (uint8_t)result.count_failed_high;
  reply.data[(uint8_t)(int)pilot_test_run_index_failed_index] = (uint8_t)result.index_failed;
$else$
  /* as this is not a test image return an error that this is not supported */
  reply.data[(uint8_t)(int)pilot_test_run_index_result] = pilot_test_run_result_not_supported;
$endif$

  /* send the reply */
  reply.length = MSG_LEN(8);
  pilot_comm_send_cmd(&reply);
}

static void pilot_rpi_fpga_state_set(pilot_cmd_t *cmd)
{
  $if(model.FPGAs)$
  module_slot_t slot; module_port_t port;
  slot = target_t_get_module_slot(cmd->target);
  switch ((int)slot)
  {
    $model.FPGAs:{fpga|
      case $fpga.Slot$: cmd->data[2] = (uint8_t)pilot_$fpga.Name$_fpga_gpio_set((int8_t)cmd->data[0], (int8_t)cmd->data[1]); break;
    };separator="\n"$
  }
  cmd->length = MSG_LEN(4);
  pilot_comm_send_cmd(cmd);
  $endif$
}

static void pilot_rpi_fpga_cmd(pilot_cmd_t *cmd)
{
  $if(model.FPGAs)$
  module_slot_t slot; module_port_t port;
  uint32_t size = *((uint16_t *)cmd->data);

  if (size > (pilot_cmd_t_data_size-2))
    size = pilot_cmd_t_data_size-2;
  slot = target_t_get_module_slot(cmd->target);
  switch ((int)slot)
  {
    $model.FPGAs:{fpga|
      case $fpga.Slot$: pilot_$fpga.Name$_send(&cmd->data[2], size); break;
    };separator="\n"$
  }
  pilot_comm_send_cmd(cmd);
  $endif$
}

static void pilot_rpi_comm_stats(pilot_cmd_t *cmd)
{
  memcpy(cmd->data, &_internals.stats, sizeof(stats_t)); 
  cmd->length = MSG_LEN(sizeof(stats_t));
  pilot_comm_send_cmd(cmd);
}

static void pilot_rpi_fwinfo_cmd(pilot_cmd_t *cmd) {
  static const char version[] = "$model.Version$";
  strncpy(cmd->data, version, pilot_cmd_t_data_size);
  cmd->length = MSG_LEN(sizeof(version));
  pilot_comm_send_cmd(cmd);
}

static void pilot_pilot_comm_spi_handle_cmd_complete(pilot_cmd_t *cmd)
{
  int baudrate; uint16_t stopbits, parity, wordlength, i;
  module_slot_t slot; module_port_t port;

  slot = target_t_get_module_slot(cmd->target);
  port = target_t_get_module_port(cmd->target);

    switch (cmd->type)
    {
      case pilot_cmd_type_eeprom_uid_get:
        if (cmd->target == target_base)
          pilot_comm_get_board_uid();
        else
          pilot_comm_get_uid(slot);
        break;

      case pilot_cmd_type_eeprom_hid_get:
        pilot_comm_get_hid(slot);
        break;

      case pilot_cmd_type_eeprom_hid_set:
        pilot_comm_set_hid(slot, cmd);
        break;

      case pilot_cmd_type_eeprom_fid_get:
        pilot_comm_get_fid(slot);
        break;

      case pilot_cmd_type_eeprom_fid_set:
        pilot_comm_set_fid(slot, cmd);
        break;

      case pilot_cmd_type_eeprom_userdata_get:
        pilot_comm_get_eeprom_userdata(slot, cmd);
        break;

      case pilot_cmd_type_eeprom_userdata_set:
        pilot_comm_set_eeprom_userdata(cmd);
        break;

      case pilot_cmd_type_usart_set_baudrate:
        baudrate = pilot_stm_proto_baudrate_to_int((pilot_cmd_baudrate_t) cmd->data[0]);
        pilot_comm_set_baudrate(slot, port, baudrate);
        break;

      case pilot_cmd_type_usart_set_stopbits:
        stopbits = pilot_pilot_comm_spi_get_mc_stopbits((pilot_cmd_stopbits_t) cmd->data[0]);
        pilot_comm_set_stopbits(slot, port, stopbits);
        break;

      case pilot_cmd_type_usart_set_parity:
        parity = pilot_pilot_comm_spi_get_mc_parity((pilot_cmd_parity_t) cmd->data[0]);
        pilot_comm_set_parity(slot, port, parity);
        break;

      case pilot_cmd_type_usart_set_wordlength:
        wordlength = pilot_pilot_comm_spi_get_mc_wordlength((pilot_cmd_wordlength_t) cmd->data[0]);
        pilot_comm_set_wordlength(slot, port, wordlength);
        break;

      case pilot_cmd_type_input_get_input:
        pilot_pilot_comm_send_input_state(slot, cmd->data[(int)pilot_input_index_target]);
        break;

      case pilot_cmd_type_output_set_value:
        pilot_pilot_comm_set_output(slot, (pilot_output_target_t) cmd->data[(int)pilot_output_index_target], *((uint32_t *)&cmd->data[(int)pilot_output_index_value]));
        break;

      /* rpi requests the rtc time, send it an answer */
      case pilot_cmd_type_rtc_get:
        pilot_pilot_comm_send_rtc();
        break;

      /* rpi sends rtc datetime, update rtc */
      case pilot_cmd_type_rtc_set:
        rtc_set_datetime_cmd(cmd);
        break;

      /* rpi requests counter values, send it an answer*/
      case pilot_cmd_type_input_get_counter:
        pilot_pilot_comm_get_counter_values(slot, (pilot_counter_target_t)cmd->data[pilot_counter_index_target]);
        break;

      /* rpi sets the counter */
      case pilot_cmd_type_input_set_counter:
        pilot_counter8_set_counter(cmd);
        break;

      /* rpi enables / disables the gps */
      case pilot_cmd_type_gps_set_enable:
        pilot_rpi_gps_set_enable(slot, cmd->data[pilot_gps_enable_index_value]);
        break;

      /* rpi request gps enabled state */
      case pilot_cmd_type_gps_get_enable:
        pilot_rpi_gps_get_enable(slot);
        break;

      /* rpi enables / disables the gsm */
      case pilot_cmd_type_gsm_set_enable:
        pilot_rpi_gsm_set_enable(slot, cmd->data[pilot_gsm_enable_index_value]);
        break;

      /* rpi requests the gsm enabled state */
      case pilot_cmd_type_gsm_get_enable:
        pilot_rpi_gsm_get_enable(slot);
        break;

      /* rpi enables / disables 1-wire */
      case pilot_cmd_type_onewire_set_enable:
        pilot_rpi_onewire_set_enable(slot, cmd->data[pilot_onewire_enable_index_value]);
        break;

      /* rpi requests onewire enabled state */
      case pilot_cmd_type_onewire_get_enable:
        pilot_rpi_onewire_get_enable(slot);
        break;

      /* rpi sends scld update */
      case pilot_cmd_type_slcd_udpate:
        pilot_rpi_slcd_update(slot);
        break;

      case pilot_cmd_type_slcd_set_resolution:
        pilot_rpi_slcd_set_resolution(slot, cmd);
        break;

      case pilot_cmd_type_slcd_get_resolution:
        pilot_rpi_slcd_get_resolution(slot);
        break;

      case pilot_cmd_type_plc_state_get:
        pilot_rpi_plc_state_get();
        break;

      case pilot_cmd_type_plc_state_set:
        pilot_rpi_plc_state_set(cmd);
        break;

      case pilot_cmd_type_plc_cycletimes_get:
        pilot_rpi_plc_cycletimes_get();
        break;

      case pilot_cmd_type_plc_variables_read_config:
        pilot_rpi_plc_variables_read_config(cmd);
        break;

      case pilot_cmd_type_plc_variables_write_config:
        pilot_rpi_plc_variables_write_config(cmd);
        break;

      case pilot_cmd_type_plc_variables_get:
        pilot_rpi_plc_variables_get();
        break;

      case pilot_cmd_type_plc_variables_set:
        pilot_rpi_plc_variables_set(cmd);
        break;

      case pilot_cmd_type_io16_set_direction:
        pilot_rpi_io16_set_direction(slot, 
          (pilot_io16_block_t)cmd->data[(int)pilot_io16_set_direction_index_block],
          (pilot_io16_direction_t)cmd->data[(int)pilot_io16_set_direction_index_direction]);
        break;

      /* rpi requests the module type */
      case pilot_cmd_type_module_type_get:
        pilot_comm_get_module_type(slot);
        break;

      /* rpi enables / disables lora */
      case pilot_cmd_type_lora_set_enable:
        pilot_rpi_lora_set_enable(slot, cmd->data[pilot_lora_enable_index_value]);
        break;

      /* rpi request lora enabled state */
      case pilot_cmd_type_lora_get_enable:
        pilot_rpi_lora_get_enable(slot);
        break;

      case pilot_cmd_type_test_run:
        pilot_comm_run_test(cmd);
        break;

      case pilot_cmd_type_plc_variable_get:
        pilot_rpi_plc_variable_get(cmd);
        break;

      case pilot_cmd_type_plc_variable_set:
        pilot_rpi_plc_variable_set(cmd);
      break;

      case pilot_cmd_type_fpga_state:
      pilot_rpi_fpga_state_set(cmd);
      break;

      case pilot_cmd_type_fpga_cmd:
      pilot_rpi_fpga_cmd(cmd);
      break;

      case pilot_cmd_type_comm_stats_get:
      pilot_rpi_comm_stats(cmd);
      break;

      case pilot_cmd_type_fwinfo:
      pilot_rpi_fwinfo_cmd(cmd);
      break;
      default: break;
    }
}

