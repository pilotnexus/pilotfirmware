/*
  this file was auto-generated
  instead of editing this file directly, edit the corresponding *.st file
*/
#ifndef __STM32F10X_IT_C_
#define __STM32F10X_IT_C_

/* Includes ------------------------------------------------------------------*/
#include "stm32f10x_it.h"
#include "gpio_config.h"
#include "it_callback.h"
#include "stm32f10x_exti.h"
#include "main.h"

#if USB_HIGH_PRIORITY_EVENT > 0
extern void USB_HIGH_ISR (void);
#endif // USB_HIGH_PRIORITY_EVENT > 0
extern void USB_ISR (void);

char j=0;

/*******************************************************************************
* Function Name  : NMIException
* Description    : This function handles NMI exception.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void NMIException(void)
{
}

/*******************************************************************************
* Function Name  : HardFaultException
* Description    : This function handles Hard Fault exception.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void HardFaultException(void)
{
}

/*******************************************************************************
* Function Name  : MemManageException
* Description    : This function handles Memory Manage exception.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void MemManageException(void)
{
}

/*******************************************************************************
* Function Name  : BusFaultException
* Description    : This function handles Bus Fault exception.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void BusFaultException(void)
{
}

/*******************************************************************************
* Function Name  : UsageFaultException
* Description    : This function handles Usage Fault exception.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void UsageFaultException(void)
{
}

/*******************************************************************************
* Function Name  : DebugMonitor
* Description    : This function handles Debug Monitor exception.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void DebugMonitor(void)
{
}

/*******************************************************************************
* Function Name  : SVCHandler
* Description    : This function handles SVCall exception.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void SVCHandler(void)
{
}

/*******************************************************************************
* Function Name  : PendSVC
* Description    : This function handles PendSVC exception.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void PendSVC(void)
{
}

/*******************************************************************************
* Function Name  : SysTickHandler
* Description    : This function handles SysTick Handler.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void SysTick_Handler(void)
{
  pilot_systick();
}

/*******************************************************************************
* Function Name  : WWDG_IRQHandler
* Description    : This function handles WWDG interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void WWDG_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : PVD_IRQHandler
* Description    : This function handles PVD interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void PVD_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : TAMPER_IRQHandler
* Description    : This function handles Tamper interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TAMPER_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : RTC_IRQHandler
* Description    : This function handles RTC global interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void RTC_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : FLASH_IRQHandler
* Description    : This function handles Flash interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void FLASH_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : RCC_IRQHandler
* Description    : This function handles RCC interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void RCC_IRQHandler(void)
{
}

/******************************************************************************* 
* Function Name  : DMA1_Channel1_IRQHandler 
* Description    : This function handles DMA Stream 1 interrupt request. 
* Input          : None 
* Output         : None 
* Return         : None 
*******************************************************************************/ 
void DMA1_Channel1_IRQHandler(void) 
{ 
} 
 
/******************************************************************************* 
* Function Name  : DMA1_Channel2_IRQHandler 
* Description    : This function handles DMA Stream 2 interrupt request. 
* Input          : None 
* Output         : None 
* Return         : None 
*******************************************************************************/ 
void DMA1_Channel2_IRQHandler(void) 
{ 
} 
 
/******************************************************************************* 
* Function Name  : DMA1_Channel3_IRQHandler 
* Description    : This function handles DMA Stream 3 interrupt request. 
* Input          : None 
* Output         : None 
* Return         : None 
*******************************************************************************/ 
void DMA1_Channel3_IRQHandler(void) 
{ 
  pilot_spi_transmit_done();
} 
 
/******************************************************************************* 
* Function Name  : DMA1_Channel4_IRQHandler 
* Description    : This function handles DMA Stream 4 interrupt request. 
* Input          : None 
* Output         : None 
* Return         : None 
*******************************************************************************/ 
void DMA1_Channel4_IRQHandler(void) 
{ 
  pilot_uart_transmit_done();
} 
 
/******************************************************************************* 
* Function Name  : DMA1_Channel5_IRQHandler 
* Description    : This function handles DMA Stream 5 interrupt request. 
* Input          : None 
* Output         : None 
* Return         : None 
*******************************************************************************/ 
void DMA1_Channel5_IRQHandler(void) 
{ 
} 
 
/******************************************************************************* 
* Function Name  : DMA1_Channel6_IRQHandler 
* Description    : This function handles DMA Stream 6 interrupt request. 
* Input          : None 
* Output         : None 
* Return         : None 
*******************************************************************************/ 
void DMA1_Channel6_IRQHandler(void) 
{ 
} 
 
/******************************************************************************* 
* Function Name  : DMA1_Channel7_IRQHandler 
* Description    : This function handles DMA Stream 7 interrupt request. 
* Input          : None 
* Output         : None 
* Return         : None 
*******************************************************************************/ 
void DMA1_Channel7_IRQHandler(void) 
{ 
} 
 

/*******************************************************************************
* Function Name  : ADC_IRQHandler
* Description    : This function handles ADC global interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void ADC_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : CAN_RX1_IRQHandler
* Description    : This function handles CAN RX1 interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void CAN_RX1_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : CAN_SCE_IRQHandler
* Description    : This function handles CAN SCE interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void CAN_SCE_IRQHandler(void)
{
}

$if(model.IO16s)$
static void check_io16_input_changed(uint32_t extiLine, int slot)
{
  /* check if the interrupt line raised the interrupt */
  if (EXTI_GetITStatus(extiLine))
  {
    /* inform the rpi that an input changed */
    pilot_io16_input_changed(slot);

    /* mark the interrupt as handled */
    EXTI_ClearITPendingBit(extiLine);
  }
}
$endif$

$if(model.FPGAs)$
static void check_fpga_int_changed(uint32_t extiLine, int slot)
{
  /* check if the interrupt line raised the interrupt */
  if (EXTI_GetITStatus(extiLine))
  {
    /* process */
    //TODO

    /* mark the interrupt as handled */
    EXTI_ClearITPendingBit(extiLine);
  }
}
$endif$

$if(model.AIO20s)$
static void check_aio20_int_changed(uint32_t extiLine, int slot)
{
  /* check if the interrupt line raised the interrupt */
  if (EXTI_GetITStatus(extiLine))
  {
    /* process */
    //TODO

    /* mark the interrupt as handled */
    EXTI_ClearITPendingBit(extiLine);
  }
}
$endif$

$if(model.Counter8s)$
static void check_counter_increment(uint32_t extiLine, int counter, GPIO_TypeDef* gpio_board, uint16_t gpio_pin)
{
  uint8_t gpio_state;

  /* check if the interrupt line raised the interrupt */
  if (EXTI_GetITStatus(extiLine) != RESET)
  {
    /* check the gpio pin */
    gpio_state = GPIO_ReadInputDataBit(gpio_board, gpio_pin);

    /* if it's high, than increment the counter */
    if (gpio_state)
      pilot_counter_increment(counter);

    /* mark the interrupt as handled */
    EXTI_ClearITPendingBit(extiLine);
  }
}
$endif$

/* This function handles External interrupt Line 0 request. */
void EXTI0_IRQHandler(void)
{
  $model.IrqHandlers.EXTI0$
}

/* This function handles External interrupt Line 1 request. */
void EXTI1_IRQHandler(void)
{
  $model.IrqHandlers.EXTI1$
}

/* This function handles External interrupt Line 2 request. */
void EXTI2_IRQHandler(void)
{
  $model.IrqHandlers.EXTI2$
}

/* This function handles External interrupt Line 3 request. */
void EXTI3_IRQHandler(void)
{
  $model.IrqHandlers.EXTI3$
}

/* This function handles External interrupt Line 4 request. */
void EXTI4_IRQHandler(void)
{
  $model.IrqHandlers.EXTI4$
}

/* This function handles External lines 9 to 5 interrupt request. */
void EXTI9_5_IRQHandler(void)
{
  $model.IrqHandlers.EXTI9_5$
}

/* This function handles External lines 15 to 10 interrupt request. */
void EXTI15_10_IRQHandler(void)
{
  $model.IrqHandlers.EXTI15_10$
}

/*******************************************************************************
* Function Name  : TIM1_BRK_IRQHandler
* Description    : This function handles TIM1 Break interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM1_BRK_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : TIM1_UP_IRQHandler
* Description    : This function handles TIM1 overflow and update interrupt
*                  request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM1_UP_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : TIM1_TRG_CCUP_IRQHandler
* Description    : This function handles TIM1 Trigger and CC Update interrupts
*                  requests.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM1_TRG_CCUP_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : TIM1_CC_IRQHandler
* Description    : This function handles TIM1 capture compare interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM1_CC_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : TIM2_IRQHandler
* Description    : This function handles TIM2 global interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM2_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : TIM3_IRQHandler
* Description    : This function handles TIM3 global interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM3_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : TIM4_IRQHandler
* Description    : This function handles TIM4 global interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM4_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : I2C1_EV_IRQHandler
* Description    : This function handles I2C1 Event interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void I2C1_EV_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : I2C1_ER_IRQHandler
* Description    : This function handles I2C1 Error interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void I2C1_ER_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : I2C2_EV_IRQHandler
* Description    : This function handles I2C2 Event interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void I2C2_EV_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : I2C2_ER_IRQHandler
* Description    : This function handles I2C2 Error interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void I2C2_ER_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : SPI1_IRQHandler
* Description    : This function handles SPI1 global interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void SPI1_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : SPI2_IRQHandler
* Description    : This function handles SPI2 global interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void SPI2_IRQHandler(void)
{
}

/* usart irq handlers */
$model.Usarts:{usart|
void $usart.Name$_IRQHandler(void)
{
  pilot_$usart.Name$_receive();
\}
};separator="\n"$

/*******************************************************************************
* Function Name  : RTCAlarm_IRQHandler
* Description    : This function handles RTC Alarm interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void RTCAlarm_IRQHandler(void)
{
}

/*******************************************************************************
* Function Name  : USBWakeUp_IRQHandler
* Description    : This function handles USB WakeUp interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void USBWakeUp_IRQHandler(void)
{
}


#endif
