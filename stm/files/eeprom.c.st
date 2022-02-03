#include "eeprom.h"
#include "stm32_conf.h"
#include "delay.h"
#include "stm32f10x_i2c.h"

//Run in Overdrive mode
//comment out this define to run in normal mode
#define OVERDRIVE_EEPROM

#define EEPROM_GPIO GPIOC
// #define GPIO_Pin_0                 ((uint16_t)0x0001)  /* Pin 0 selected */
// #define GPIO_Pin_1                 ((uint16_t)0x0002)  /* Pin 1 selected */
// #define GPIO_Pin_2                 ((uint16_t)0x0004)  /* Pin 2 selected */
// #define GPIO_Pin_3                 ((uint16_t)0x0008)  /* Pin 3 selected */

/* maps the module index (0-3) to pins 
  index 0 -> GPIO_Pin_2
  index 1 -> GPIO_Pin_0
  index 2 -> GPIO_Pin_3
  index 3 -> GPIO_Pin_1
*/
#define pilot_eeprom_module_to_pin(index) ((uint16_t)(index == 0) ? GPIO_Pin_2 : (module == 1) ? GPIO_Pin_0 : (module == 2) ? GPIO_Pin_3 : GPIO_Pin_1)

#ifdef OVERDRIVE_EEPROM
/* timings in microseconds for overdrive */
#define EEPROM_DELAY_A 1.0 /* Write 1-bit (drive bus low) & Read-bit (drive bus low) */
#define EEPROM_DELAY_B 7.5 /* Write 1-bit (after release bus) */
#define EEPROM_DELAY_C 7.5 /* Write 0-bit (drive bus low) */
#define EEPROM_DELAY_D 2.5 /* Write 0-bit (after release bus) */
#define EEPROM_DELAY_E 1.0 /* Read Bit (after release bus) */
#define EEPROM_DELAY_F 7   /* Read Bit (after sample read bit) */
#define EEPROM_DELAY_G 2.5 /* Reset (before drive low) */
#define EEPROM_DELAY_H 70  /* Reset (after drive low) */
#define EEPROM_DELAY_I 8.5 /* Reset (after release bus) */
#define EEPROM_DELAY_J 40  /* Reset (after sample presence pulse) */

#define EEPROM_DELAY_RETRY 200  /* Retry waiting time */
#else
/* timings in microseconds for standard */
#define EEPROM_DELAY_A 6   /* Write 1-bit (drive bus low) & Read-bit (drive bus low) */
#define EEPROM_DELAY_B 64  /* Write 1-bit (after release bus) */
#define EEPROM_DELAY_C 60  /* Write 0-bit (drive bus low) */
#define EEPROM_DELAY_D 10  /* Write 0-bit (after release bus) */
#define EEPROM_DELAY_E 9   /* Read Bit (after release bus) */
#define EEPROM_DELAY_F 55  /* Read Bit (after sample read bit) */
#define EEPROM_DELAY_G 0   /* Reset (before drive low) */
#define EEPROM_DELAY_H 480 /* Reset (after drive low) */
#define EEPROM_DELAY_I 70  /* Reset (after release bus) */
#define EEPROM_DELAY_J 410 /* Reset (after sample presence pulse) */

#define EEPROM_DELAY_RETRY 1000  /* Retry waiting time */
#endif

/* rom commands */
typedef enum {
  pilot_eeprom_rom_cmd_read_rom = 0x33,
  pilot_eeprom_rom_cmd_match_rom = 0x55,
  pilot_eeprom_rom_cmd_search_rom = 0xF0,
  pilot_eeprom_rom_cmd_skip_rom = 0xCC,
  pilot_eeprom_rom_cmd_resume_command = 0xA5
} pilot_eeprom_rom_cmd_t;

/* memory commands */
typedef enum {
  pilot_eeprom_mem_cmd_read = 0xF0,
  pilot_eeprom_mem_cmd_write = 0x55
} pilot_eeprom_mem_cmd_t;

/* write CS byte */
typedef enum {
  pilot_eeprom_mem_cmd_write_result_success = 0xAA,
  pilot_eeprom_mem_cmd_write_result_write_protected = 0x33
} pilot_eeprom_mem_cmd_write_result_t;

/* address of the memory addresses */
typedef enum {
  pilot_eeprom_mem_address_hid  = 0x00,
  pilot_eeprom_mem_address_fid  = 0x08,
  pilot_eeprom_mem_address_user = 0x10
} pilot_eeprom_mem_address_t;

typedef enum {
  pin_direction_undefined = 0,
  pin_direction_output,
  pin_direction_input
} pin_direction_t;

__STATIC_INLINE void pilot_eeprom_loop(__IO uint32_t nCount)
{
  for (; nCount != 0; nCount--);
}

/* use the pilot_delay_us() function */
#define pilot_eeprom_delay_us(microseconds) pilot_delay_cycles(USECTOCYCLES(microseconds))

/* works for keil optimization level 0 */
// #define pilot_eeprom_delay_us(microseconds) pilot_eeprom_loop((microseconds -1) * 6)

/* works for keil optimization level 3 */
//#define pilot_eeprom_delay_us(microseconds) pilot_eeprom_loop((microseconds -1) * 8)

/* configures a pin as an input usuable for a 1-wire communication */
__STATIC_INLINE void pilot_eeprom_set_pin_input(uint16_t pin)
{
  GPIO_InitTypeDef gpio;

  gpio.GPIO_Speed = GPIO_Speed_50MHz;

#ifdef STM32F4XX
  gpio.GPIO_Mode = GPIO_Mode_IN;
  gpio.GPIO_OType = GPIO_OType_OD;
#else
  gpio.GPIO_Mode = GPIO_Mode_IN_FLOATING;
#endif

  gpio.GPIO_Pin = pin;

  GPIO_Init(EEPROM_GPIO, &gpio);
}

/* configures a pin as an output usuable for 1-wire communication */
__STATIC_INLINE void pilot_eeprom_set_pin_output(uint16_t pin)
{
  GPIO_InitTypeDef gpio;

  gpio.GPIO_Speed = GPIO_Speed_50MHz;

#ifdef STM32F4XX
  gpio.GPIO_Mode = GPIO_Mode_OUT;
  gpio.GPIO_OType = GPIO_OType_PP;
  gpio.GPIO_PuPd = GPIO_PuPd_UP;
#else
  gpio.GPIO_Mode = GPIO_Mode_Out_OD;
#endif

  gpio.GPIO_Pin = pin;

  GPIO_Init(EEPROM_GPIO, &gpio);
}

__STATIC_INLINE void pilot_eeprom_set_pin_direction(module_slot_t module, pin_direction_t direction)
{
  if (direction == pin_direction_output)
    pilot_eeprom_set_pin_output(pilot_eeprom_module_to_pin(module));
  else
    pilot_eeprom_set_pin_input(pilot_eeprom_module_to_pin(module));
}

#define pilot_eeprom_set_1w(module, high) GPIO_WriteBit(EEPROM_GPIO, pilot_eeprom_module_to_pin(module), high ? Bit_SET : Bit_RESET)

// CRC-8 used in UID
uint8_t crc8( uint8_t *addr, uint8_t len)
{
      uint8_t crc=0;
      
      for (uint8_t i=0; i<len;i++) 
      {
            uint8_t inbyte = addr[i];
            for (uint8_t j=0;j<8;j++) 
            {
                  uint8_t mix = (crc ^ inbyte) & 0x01;
                  crc >>= 1;
                  if (mix) 
                        crc ^= 0x8C;
                  
                  inbyte >>= 1;
            }
      }
      return crc;
}

/* get checksum */
static uint8_t calculate_checksum(uint8_t * data, uint32_t length) 
{
  uint32_t i;
  uint8_t XOR;

  for (XOR = 0, i = 0; i < length; i++) 
    XOR ^= data[i];

  return XOR;
}

/* the following 4 functions implement the 4 basic 1-wire operations per bit-banging */

/* writes a 1 over 1-wire */
static void pilot_eeprom_write_1_bit(module_slot_t module)
{
  /* drive bus low, delay A microseconds */
  pilot_eeprom_set_pin_direction(module, pin_direction_output);
  pilot_eeprom_set_1w(module, false);
  pilot_eeprom_delay_us(EEPROM_DELAY_A);

  /* release bus, delay B microseconds */
  pilot_eeprom_set_1w(module, true);
  pilot_eeprom_set_pin_direction(module, pin_direction_input);
  pilot_eeprom_delay_us(EEPROM_DELAY_B);
}

/* writes a 0 over 1-wire */
static void pilot_eeprom_write_0_bit(module_slot_t module)
{
  /* drive bus low, delay C microseconds */
  pilot_eeprom_set_pin_direction(module, pin_direction_output);
  pilot_eeprom_set_1w(module, false);
  pilot_eeprom_delay_us(EEPROM_DELAY_C);

  /* release bus, delay D microseconds */
  pilot_eeprom_set_1w(module, true);
  pilot_eeprom_set_pin_direction(module, pin_direction_input);
  pilot_eeprom_delay_us(EEPROM_DELAY_D);
}

/* reads and returns a bit over 1-wire */
static bool pilot_eeprom_read_bit(module_slot_t module)
{
  bool bit;

  /* drive bus low, delay A microseconds */
  pilot_eeprom_set_pin_direction(module, pin_direction_output);
  pilot_eeprom_set_1w(module, false);
  pilot_eeprom_delay_us(EEPROM_DELAY_A);

  /* release bus, delay E microseconds */
  pilot_eeprom_set_1w(module, true);
  //pilot_eeprom_set_pin_direction(module, pin_direction_input);
  //pilot_eeprom_delay_us(EEPROM_DELAY_E);

  /* sample bus to read bit from slave */
  //bit = GPIO_ReadInputDataBit(EEPROM_GPIO, pilot_eeprom_module_to_pin(module));
  bit = EEPROM_GPIO->IDR & pilot_eeprom_module_to_pin(module);

  /* delay F microseconds */
  pilot_eeprom_delay_us(EEPROM_DELAY_F);

  return bit;
}

/* send reset pulse and returns true if a slave responded with a presence pulse */
static bool pilot_eeprom_reset(module_slot_t module)
{
  bool slave_present;

  /* delay G */
  pilot_eeprom_delay_us(EEPROM_DELAY_G);

  /* drive the bus low for H microseconds */
  pilot_eeprom_set_pin_direction(module, pin_direction_output);
  pilot_eeprom_set_1w(module, false);
  pilot_eeprom_delay_us(EEPROM_DELAY_H);

  /* release bus for I microseconds  */
  pilot_eeprom_set_1w(module, true);
  pilot_eeprom_delay_us(EEPROM_DELAY_I);

  pilot_eeprom_set_pin_direction(module, pin_direction_input);
  /* sample bus: 0 = device present, 1 = no device present */
  slave_present = !GPIO_ReadInputDataBit(EEPROM_GPIO, pilot_eeprom_module_to_pin(module));

  /* delay J microseconds  */
  pilot_eeprom_delay_us(EEPROM_DELAY_J);

  return slave_present;
}

static void pilot_eeprom_write_byte(module_slot_t module, uint8_t tx)
{
  int i;

  /* LSb first (least significant bit first) */
  for (i = 0; i < 8; i++)
    if ((tx >> i) & 0x01)
      pilot_eeprom_write_1_bit(module);
    else
      pilot_eeprom_write_0_bit(module);
}

static void pilot_eeprom_read_byte(module_slot_t module, uint8_t *rx)
{
  int i;
  uint8_t b = 0;

  /* LSb first (least significant bit first) */
  for (i = 0; i < 8; i++)
    b |= pilot_eeprom_read_bit(module) << i;

  *rx = b;
}

/* poll the eeprom uid */
bool pilot_eeprom_get_module_uid(module_slot_t module, pilot_eeprom_uid_t *uid)
{
  int i, j, retries=20;
  bool ret;
  uint8_t crc;

  for(j=0; j<retries; j++) {
    /* send reset pulse */
    pilot_eeprom_reset(module);

    /* send read rom command */
    pilot_eeprom_write_byte(module, (uint8_t)pilot_eeprom_rom_cmd_read_rom);

    /* read the rom from the LSB in */
    for (i = 0; i < EEPROM_UID_LENGTH; i++)
      pilot_eeprom_read_byte(module, &uid->uid[i]);

    crc = crc8(uid->uid, EEPROM_UID_LENGTH - 1);
    if (crc == uid->uid[EEPROM_UID_LENGTH-1])
    {
      ret = true;
      break;
    }
    else
      ret = false;
  }

  return ret;
}

/* reads the eeprom memory over 1-wire 
 * returns true if the read was successful (checksum matches)
*/
static bool pilot_eeprom_read_memory(module_slot_t module, uint8_t address, uint8_t *rx, int32_t length, bool checksum)
{
  int i;
  bool ret = true, all_ff = true, is_err = true;
  uint8_t err_pattern[] = { 0xaa, 0xaa, 0x55, 0x55, 0xaa, 0xaa, 0x55 };

  /* send the 'read' command code */
  pilot_eeprom_write_byte(module, (uint8_t)pilot_eeprom_mem_cmd_read);

  /* transmit 16-bit starting address */
  pilot_eeprom_write_byte(module, address); /* bit7 = 0, bit6...bit0 hold the address */
  pilot_eeprom_write_byte(module, 0x00);    /* must be 00 to be valid */

  /* read the response */
  for (i = 0; i < length; i++)
    pilot_eeprom_read_byte(module, rx + i);

  /* reset when done */
  pilot_eeprom_reset(module);

  /* check if all is 0xFF (checksum cannot find this special case) */
  for (i = 0; i < length; i++)
    if (rx[i] != 0xFF)
      all_ff = false;

  for (i = 0; i < sizeof(err_pattern); i++)
    if (rx[i] != err_pattern[i])
      is_err = false;

  /* validate checksum if set */
  if (all_ff || is_err)
    ret = false;
  else if (checksum == true)
  {
    if (calculate_checksum(rx, length-1) == rx[length-1])
    {
      rx[length-1] = 0x20; //set checksum to ' ' (space) after verification
      ret = true;
    }
    else
      ret = false;
  }

  return ret;
}

/* writes the eeprom memory over 1-wire - memory is written in 2 bytes */
static bool pilot_eeprom_write_memory(module_slot_t module, uint8_t address, uint8_t *data, int32_t length, bool checksum)
{
  uint8_t i=0;
  uint8_t cs, b0_verification, b1_verification;
  const int max_tries = 20;
  int try_count = 0;

  /* write checksum to last byte if set */
  if (checksum == true)
    data[length-1] = calculate_checksum(data, length-1);

  /* send the 'write memory' command code */
  pilot_eeprom_write_byte(module, (uint8_t)pilot_eeprom_mem_cmd_write);

  pilot_eeprom_write_byte(module, address); /* send parameter byte */
  pilot_eeprom_write_byte(module, 0xFF);    /* send 0xFF byte */

  while (i < length && try_count < max_tries)
  {
    /* write 2 data bytes */
    pilot_eeprom_write_byte(module, data[i+0]);
    pilot_eeprom_write_byte(module, data[i+1]);

    /* read back the 2 data bytes */
    pilot_eeprom_read_byte(module, &b0_verification);
    pilot_eeprom_read_byte(module, &b1_verification);

    /* if verifying the bytes works... */
    if (data[i+0] == b0_verification && 
        data[i+1] == b1_verification)
    {
      pilot_eeprom_write_byte(module, 0xFF); /* ...send the release byte */
      pilot_delay_ms(16);                    /* wait tProg (programming time for a 16-bit segment) */
      pilot_eeprom_read_byte(module, &cs);   /* read the CS byte */
      if (cs == pilot_eeprom_mem_cmd_write_result_success) /* check if writing worked */
        i += 2;
    }
    else
    {
      pilot_eeprom_write_byte(module, 0x00); /* not ok */
      try_count++;
    }
  }

  /* reset when done */
  pilot_eeprom_reset(module);

  return i >= length;
}

bool pilot_eeprom_get_module_data(module_slot_t module, uint8_t addr, uint8_t *data, bool checksum)
{
    bool success = false;
    int i, retries=20, retry_delay=EEPROM_DELAY_RETRY; 
    pilot_eeprom_uid_t uid;

    for(i=0; i<retries; i++)
        if (pilot_eeprom_get_module_uid(module, &uid))
        {
            success = pilot_eeprom_read_memory(module, addr, data, EEPROM_DATA_LENGTH, checksum);
            if (success)
              break;
            pilot_eeprom_delay_us(EEPROM_DELAY_RETRY);
            retry_delay += EEPROM_DELAY_RETRY;
        }
    return success;
}

/* poll the eeprom hid */
bool pilot_eeprom_get_module_fid(module_slot_t module, pilot_eeprom_fid_t *fid)
{
  return pilot_eeprom_get_module_data(module, (uint8_t)pilot_eeprom_mem_address_fid, fid->data, true);
}

/* write the eeprom fid */
bool pilot_eeprom_set_module_fid(module_slot_t module, pilot_eeprom_fid_t *fid)
{
  return pilot_eeprom_write_memory(module, (uint8_t)pilot_eeprom_mem_address_fid, fid->data, EEPROM_DATA_LENGTH, true);
}

/* poll the eeprom hid - get uid needs to be called before! */
bool pilot_eeprom_get_module_hid(module_slot_t module, pilot_eeprom_hid_t *hid)
{
  return pilot_eeprom_get_module_data(module, (uint8_t)pilot_eeprom_mem_address_hid, hid->data, true);
}

/* write the eeprom hid */
bool pilot_eeprom_set_module_hid(module_slot_t module, pilot_eeprom_hid_t *hid)
{
  bool ret = false;

  ret = pilot_eeprom_write_memory(module, (uint8_t)pilot_eeprom_mem_address_hid, hid->data, EEPROM_DATA_LENGTH, true);

  return ret;
}

/* poll the user data from the eeprom */
bool pilot_eeprom_get_module_userdata(module_slot_t module, int data_index, pilot_eeprom_data_t *data)
{
  return pilot_eeprom_get_module_data(module, (uint8_t)pilot_eeprom_mem_address_user + (8*data_index), data->data, false);
}

/* write the user data to the eeprom */
bool pilot_eeprom_set_module_userdata(module_slot_t module, int data_index, pilot_eeprom_data_t *data)
{
  return pilot_eeprom_write_memory(module, (uint8_t)pilot_eeprom_mem_address_user + (8*data_index), data->data, EEPROM_DATA_LENGTH, false);
}

static void pilot_eeprom_init_clock()
{
  /* enable gpio clocks for all pins */
#ifdef STM32F4XX
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOC, ENABLE);
#else
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOC, ENABLE);
#endif
}

#define I2CX I2C1

static void pilot_eeprom_board_init_i2c()
{
  I2C_InitTypeDef  i2c;
  I2C_DeInit(I2CX);
  i2c.I2C_Mode = I2C_Mode_I2C;
  i2c.I2C_DutyCycle = I2C_DutyCycle_16_9;
  i2c.I2C_OwnAddress1 = 1;
  i2c.I2C_Ack = I2C_Ack_Enable;
  i2c.I2C_AcknowledgedAddress = I2C_AcknowledgedAddress_7bit;
  i2c.I2C_ClockSpeed = 200000;

  I2C_Init(I2CX, &i2c);
  I2C_Cmd(I2CX, ENABLE);
  I2C_AcknowledgeConfig(I2CX, ENABLE);
}

/* initialize the gpios for I²C1 - PB_6 & PB_7 */
static void pilot_eeprom_board_init_gpio()
{
  GPIO_InitTypeDef gpio;
  gpio.GPIO_Pin = GPIO_Pin_6 | GPIO_Pin_7;
  gpio.GPIO_Mode = GPIO_Mode_AF_OD;
  gpio.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOB, &gpio);
}

/* initialize the clocks */
static void pilot_eeprom_board_init_clocks()
{
  RCC_AHBPeriphClockCmd(RCC_APB2Periph_AFIO, ENABLE);
  RCC_AHBPeriphClockCmd(RCC_APB2Periph_GPIOC, ENABLE);
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_I2C1, ENABLE);
  RCC_AHBPeriphClockCmd(RCC_APB1Periph_I2C1, ENABLE);
}

static void pilot_eeprom_board_init()
{
  pilot_eeprom_board_init_clocks();
  pilot_eeprom_board_init_gpio();
  pilot_eeprom_board_init_i2c();
}

/* poll the base eeprom uid over the eeprom */
bool pilot_eeprom_get_board_uid(uint32_t *uid)
{
  ///* while the bus is busy */
  //while (I2C_GetFlagStatus(I2CX, I2C_FLAG_BUSY))
  //{
  //}

  //I2C_GenerateSTART(I2CX, ENABLE);

  //while (!I2C_CheckEvent(I2CX, I2C_EVENT_MASTER_MODE_SELECT))
  //{
  //}


  //I2C_Send7bitAddress(I2CX, )
  *uid = 255;

  return 1;
}

/* initialize the eeprom driver */
void pilot_eeprom_init()
{
  pilot_eeprom_init_clock();

  //pilot_eeprom_board_init();
}
