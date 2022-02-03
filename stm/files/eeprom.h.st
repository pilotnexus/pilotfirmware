#ifndef __pilot_EEPROM_H__
#define __pilot_EEPROM_H__

#include <stdint.h>
#include <stdbool.h>
#include "common_base.h"

void pilot_eeprom_init(void); /* initialize the eeprom driver */
bool pilot_eeprom_get_module_uid(module_slot_t module, pilot_eeprom_uid_t *uid); /* poll the eeprom uid */
bool pilot_eeprom_get_module_hid(module_slot_t module, pilot_eeprom_hid_t *hid); /* poll the eeprom hid */
bool pilot_eeprom_set_module_hid(module_slot_t module, pilot_eeprom_hid_t *hid); /* write the eeprom hid */
bool pilot_eeprom_get_module_fid(module_slot_t module, pilot_eeprom_fid_t *fid); /* poll the eeprom hid */
bool pilot_eeprom_set_module_fid(module_slot_t module, pilot_eeprom_fid_t *fid); /* write the eeprom fid */
bool pilot_eeprom_get_module_userdata(module_slot_t module, int data_index, pilot_eeprom_data_t *data); /* poll the user data from the eeprom */
bool pilot_eeprom_set_module_userdata(module_slot_t module, int data_index, pilot_eeprom_data_t *data); /* write the user data to the eeprom */
bool pilot_eeprom_get_board_uid(uint32_t *uid); /* get the board base uid */

#endif
