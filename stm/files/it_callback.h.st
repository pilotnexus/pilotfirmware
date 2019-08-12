#ifndef RCP_IT_CALLBACK_H
#define RCP_IT_CALLBACK_H

$model.Usarts:{u|void pilot_$u.Name$_receive(void);};separator="\n"$

void pilot_spi_transmit_done(void);
void pilot_counter_increment(int counter);
void pilot_io16_input_changed(int slot);

#endif
