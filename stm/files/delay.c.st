#include "delay.h"

//activate DWT-Unit
void DWT_Enable() {
  CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;
}

void DWT_CycCounterEn() {
  DWT->CTRL = 0x40000001;
}
void DWT_CycCounterDis() {
  DWT->CTRL = 0x40000000;
}

void pilot_delay_ms(__IO int32_t milliseconds)
{
  int i;
  for (i = 0; i < milliseconds; i++)
    pilot_delay_us(1000);
}
