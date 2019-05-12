#ifndef __pilot_DELAY_H__
#define __pilot_DELAY_H__

#include "stm32f10x.h"
#include "stm32_conf.h"
#include <stdint.h>

void DWT_Enable();
void DWT_CycCounterEn();
void DWT_CycCounterDis();
void pilot_delay_ms(__IO int32_t milliseconds);

__STATIC_INLINE uint32_t DWT_CycCounterRead() {
  return DWT->CYCCNT;
}
__STATIC_INLINE void DWT_CycCounterClear() {
  DWT->CYCCNT = 0;
}

#define USECTOCYCLES(u) (u* ($model.ClockSpeed$ / 1000000)) 

__STATIC_INLINE void pilot_delay_cycles(__IO int32_t cycles)
{
  int32_t end =  DWT->CYCCNT + cycles;
  
  /* wait for the specified time */
  while (DWT_CycCounterRead() <= end)
    ;
}

__STATIC_INLINE void pilot_delay_us(__IO int32_t microseconds)
{
  int32_t end =  DWT_CycCounterRead() + (microseconds * (SystemCoreClock / 1000000));
  
  if (microseconds < 2)
    return;
  
  /* wait for the specified time */
  while (DWT_CycCounterRead() <= end)
    ;
}

#endif