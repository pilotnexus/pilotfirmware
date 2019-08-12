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

volatile uint64_t last_cycle_count_64 = 0;

// Call at least every 2^32 cycles (every 59.6 seconds @ 72 MHz).
// Do not call from interrupt context!
uint64_t GetCycleCount64() {
  last_cycle_count_64 += DWT->CYCCNT - (uint32_t)(last_cycle_count_64);
  return last_cycle_count_64;
}

// Call at least every 2^32 cycles (every 59.6 seconds @ 72 MHz).
uint64_t GetCycleCountDisableInterrupt64() {
  uint32_t primask;

  asm volatile ("mrs %0, PRIMASK" : "=r"(primask));
  asm volatile ("cpsid i");  // Disable interrupts.
  int64_t r = last_cycle_count_64;
  r += DWT->CYCCNT - (uint32_t)(r);
  last_cycle_count_64 = r;
  asm volatile ("msr PRIMASK, %0" : : "r"(primask));  // Restore interrupts.
  return r;
}

