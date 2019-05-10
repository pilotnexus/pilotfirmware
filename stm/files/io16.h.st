/* this file is auto-generated */
#ifndef __RPC_IO16_H__
#define __RPC_IO16_H__

#include "stm32_conf.h"
#include "common_base.h"
#include "spi.h"

typedef enum
{
  rpcp_io16_register_input_register_A = 0x00,
  rpcp_io16_register_input_register_B = 0x01,
  rpcp_io16_register_change_A = 0x02,
  rpcp_io16_register_change_B = 0x03,
  rpcp_io16_register_interrupt_A = 0x04,
  rpcp_io16_register_interrupt_B = 0x05,
  rpcp_io16_register_overcurrent_notification_A = 0x06,
  rpcp_io16_register_overcurrent_notification_B = 0x07,
  rpcp_io16_register_overcurrent_status_A = 0x08,
  rpcp_io16_register_overcurrent_status_B = 0x09,
  rpcp_io16_register_ad_data_1 = 0x0A,
  rpcp_io16_register_ad_data_2 = 0x0B,
  rpcp_io16_register_output_register_A = 0x0C,
  rpcp_io16_register_output_register_B = 0x0D,
  rpcp_io16_register_pulse_enable_A = 0x0E,
  rpcp_io16_register_pulse_enable_B = 0x0F,
  rpcp_io16_register_irq_enable_inputchange_A = 0x10,
  rpcp_io16_register_irq_enable_inputchange_B = 0x11,
  rpcp_io16_register_irq_enable_overcurrent_A = 0x12,
  rpcp_io16_register_irq_enable_overcurrent_B = 0x13,
  rpcp_io16_register_controlword_1A = 0x14,
  rpcp_io16_register_controlword_1B = 0x15,
  rpcp_io16_register_controlword_2A = 0x16,
  rpcp_io16_register_controlword_2B = 0x17,
  rpcp_io16_register_controlword_3A = 0x18,
  rpcp_io16_register_controlword_3B = 0x19,
  rpcp_io16_register_controlword_4 = 0x1A,
  rpcp_io16_register_controlword_5 = 0x1B,
  rpcp_io16_register_controlword_6 = 0x1C,
  rpcp_io16_register_info = 0x1D,
  rpcp_io16_register_test1 = 0x1E,
  rpcp_io16_register_test2 = 0x1F
} rpcp_io16_register_t;

typedef enum
{
  rpcp_io16_pins_0_to_7,
  rpcp_io16_pins_8_to_15
} rpcp_io16_pins_t;

$model.IO16s:{io16|
  void rpc_$io16.Name$_init(void);
  int rpc_$io16.Name$_read_register(rpcp_io16_register_t reg, int count, uint8_t *value);
  int rpc_$io16.Name$_write_register(rpcp_io16_register_t reg, int count, uint8_t *value);

  int rpc_$io16.Name$_set_direction(rpcp_io16_block_t block, rpcp_io16_direction_t direction);
  int rpc_$io16.Name$_set_value(rpcp_output_target_t output, uint8_t value);
  int rpc_$io16.Name$_set_irq_handled(void);

  int rpc_$io16.Name$_get_value(uint8_t io, uint8_t *value);
  uint8_t rpc_$io16.Name$_get_byte(rpcp_io16_register_t reg);
  void rpc_$io16.Name$_set_byte(rpcp_io16_register_t reg, uint8_t value);


};separator="\n"$

#endif
