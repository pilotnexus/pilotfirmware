/* this file is auto-generated */
#ifndef __PILOT_IO16_H__
#define __PILOT_IO16_H__

#include "stm32_conf.h"
#include "common_base.h"
#include "spi.h"

typedef enum
{
  pilot_io16_register_input_register_A = 0x00,
  pilot_io16_register_input_register_B = 0x01,
  pilot_io16_register_change_A = 0x02,
  pilot_io16_register_change_B = 0x03,
  pilot_io16_register_interrupt_A = 0x04,
  pilot_io16_register_interrupt_B = 0x05,
  pilot_io16_register_overcurrent_notification_A = 0x06,
  pilot_io16_register_overcurrent_notification_B = 0x07,
  pilot_io16_register_overcurrent_status_A = 0x08,
  pilot_io16_register_overcurrent_status_B = 0x09,
  pilot_io16_register_ad_data_1 = 0x0A,
  pilot_io16_register_ad_data_2 = 0x0B,
  pilot_io16_register_output_register_A = 0x0C,
  pilot_io16_register_output_register_B = 0x0D,
  pilot_io16_register_pulse_enable_A = 0x0E,
  pilot_io16_register_pulse_enable_B = 0x0F,
  pilot_io16_register_irq_enable_inputchange_A = 0x10,
  pilot_io16_register_irq_enable_inputchange_B = 0x11,
  pilot_io16_register_irq_enable_overcurrent_A = 0x12,
  pilot_io16_register_irq_enable_overcurrent_B = 0x13,
  pilot_io16_register_controlword_1A = 0x14,
  pilot_io16_register_controlword_1B = 0x15,
  pilot_io16_register_controlword_2A = 0x16,
  pilot_io16_register_controlword_2B = 0x17,
  pilot_io16_register_controlword_3A = 0x18,
  pilot_io16_register_controlword_3B = 0x19,
  pilot_io16_register_controlword_4 = 0x1A,
  pilot_io16_register_controlword_5 = 0x1B,
  pilot_io16_register_controlword_6 = 0x1C,
  pilot_io16_register_info = 0x1D,
  pilot_io16_register_test1 = 0x1E,
  pilot_io16_register_test2 = 0x1F
} pilot_io16_register_t;

typedef enum
{
  pilot_io16_pins_0_to_7,
  pilot_io16_pins_8_to_15
} pilot_io16_pins_t;

$model.IO16s:{io16|
  int pilot_$io16.Name$_init(void);
  int pilot_$io16.Name$_read_register(pilot_io16_register_t reg, int count, uint8_t *value);
  int pilot_$io16.Name$_write_register(pilot_io16_register_t reg, int count, uint8_t *value);

  int pilot_$io16.Name$_set_direction(pilot_io16_block_t block, pilot_io16_direction_t direction);
  int pilot_$io16.Name$_set_value(pilot_output_target_t output, uint8_t value);
  int pilot_$io16.Name$_set_irq_handled(void);

  int pilot_$io16.Name$_get_value(uint8_t io, uint8_t *value);
  uint8_t pilot_$io16.Name$_get_byte(pilot_io16_register_t reg);
  int pilot_$io16.Name$_set_byte(pilot_io16_register_t reg, uint8_t value);


};separator="\n"$

#endif
