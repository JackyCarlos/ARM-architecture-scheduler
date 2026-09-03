;/**************************************************************************//**
; * @file
; * @brief    CMSIS Core Device Startup File for
; *           Silicon Labs EFM32GG Device Series
; * @version 5.8.2
; ******************************************************************************
; * # License
; *
; * The licensor of this software is Silicon Laboratories Inc. Your use of this
; * software is governed by the terms of Silicon Labs Master Software License
; * Agreement (MSLA) available at
; * www.silabs.com/about-us/legal/master-software-license-agreement. This
; * software is Third Party Software licensed by Silicon Labs from a third party
; * and is governed by the sections of the MSLA applicable to Third Party
; * Software and the additional terms set forth below.
; *
; *****************************************************************************/
;/*
; * Copyright (c) 2009-2016 ARM Limited. All rights reserved.
; *
; * SPDX-License-Identifier: Apache-2.0
; *
; * Licensed under the Apache License, Version 2.0 (the License); you may
; * not use this file except in compliance with the License.
; * You may obtain a copy of the License at
; *
; * www.apache.org/licenses/LICENSE-2.0
; *
; * Unless required by applicable law or agreed to in writing, software
; * distributed under the License is distributed on an AS IS BASIS, WITHOUT
; * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; * See the License for the specific language governing permissions and
; * limitations under the License.
; */

;/*
;//-------- <<< Use Configuration Wizard in Context Menu >>> ------------------
;*/

; <h> Stack Configuration
;   <o> Stack Size (in Bytes) <0x0-0xFFFFFFFF:8>
; </h>
                IF :DEF: __STACK_SIZE
Stack_Size      EQU     __STACK_SIZE
                ELSE
Stack_Size      EQU     0x00000400
                ENDIF

                AREA    STACK, NOINIT, READWRITE, ALIGN=3
Stack_Mem       SPACE   Stack_Size
__initial_sp


; <h> Heap Configuration
;   <o>  Heap Size (in Bytes) <0x0-0xFFFFFFFF:8>
; </h>
                IF :DEF: __HEAP_SIZE
Heap_Size       EQU     __HEAP_SIZE
                ELSE
Heap_Size       EQU     0x00000C00
                ENDIF

                AREA    HEAP, NOINIT, READWRITE, ALIGN=3
__heap_base
Heap_Mem        SPACE   Heap_Size
__heap_limit


                PRESERVE8
                THUMB


; Vector Table Mapped to Address 0 at Reset

                AREA    RESET, DATA, READONLY, ALIGN=8
                EXPORT  __Vectors
                EXPORT  __Vectors_End
                EXPORT  __Vectors_Size

__Vectors       DCD     __initial_sp              ; Top of Stack
                DCD     Reset_Handler             ; Reset Handler
                DCD     NMI_Handler               ; NMI Handler
                DCD     HardFault_Handler         ; Hard Fault Handler
                DCD     MemManage_Handler         ; MPU Fault Handler
                DCD     BusFault_Handler          ; Bus Fault Handler
                DCD     UsageFault_Handler        ; Usage Fault Handler
                DCD     0                         ; Reserved
                DCD     0                         ; Reserved
                DCD     0                         ; Reserved
                DCD     0                         ; Reserved
                DCD     SVC_Handler               ; SVCall Handler
                DCD     DebugMon_Handler          ; Debug Monitor Handler
                DCD     sl_app_properties         ; Application properties
                DCD     PendSV_Handler            ; PendSV Handler
                DCD     SysTick_Handler           ; SysTick Handler

                ; External Interrupts

                DCD     DMA_IRQHandler            ; 0: DMA Interrupt
                DCD     GPIO_EVEN_IRQHandler      ; 1: GPIO_EVEN Interrupt
                DCD     TIMER0_IRQHandler         ; 2: TIMER0 Interrupt
                DCD     USART0_RX_IRQHandler      ; 3: USART0_RX Interrupt
                DCD     USART0_TX_IRQHandler      ; 4: USART0_TX Interrupt
                DCD     USB_IRQHandler            ; 5: USB Interrupt
                DCD     ACMP0_IRQHandler          ; 6: ACMP0 Interrupt
                DCD     ADC0_IRQHandler           ; 7: ADC0 Interrupt
                DCD     DAC0_IRQHandler           ; 8: DAC0 Interrupt
                DCD     I2C0_IRQHandler           ; 9: I2C0 Interrupt
                DCD     I2C1_IRQHandler           ; 10: I2C1 Interrupt
                DCD     GPIO_ODD_IRQHandler       ; 11: GPIO_ODD Interrupt
                DCD     TIMER1_IRQHandler         ; 12: TIMER1 Interrupt
                DCD     TIMER2_IRQHandler         ; 13: TIMER2 Interrupt
                DCD     TIMER3_IRQHandler         ; 14: TIMER3 Interrupt
                DCD     USART1_RX_IRQHandler      ; 15: USART1_RX Interrupt
                DCD     USART1_TX_IRQHandler      ; 16: USART1_TX Interrupt
                DCD     LESENSE_IRQHandler        ; 17: LESENSE Interrupt
                DCD     USART2_RX_IRQHandler      ; 18: USART2_RX Interrupt
                DCD     USART2_TX_IRQHandler      ; 19: USART2_TX Interrupt
                DCD     UART0_RX_IRQHandler       ; 20: UART0_RX Interrupt
                DCD     UART0_TX_IRQHandler       ; 21: UART0_TX Interrupt
                DCD     UART1_RX_IRQHandler       ; 22: UART1_RX Interrupt
                DCD     UART1_TX_IRQHandler       ; 23: UART1_TX Interrupt
                DCD     LEUART0_IRQHandler        ; 24: LEUART0 Interrupt
                DCD     LEUART1_IRQHandler        ; 25: LEUART1 Interrupt
                DCD     LETIMER0_IRQHandler       ; 26: LETIMER0 Interrupt
                DCD     PCNT0_IRQHandler          ; 27: PCNT0 Interrupt
                DCD     PCNT1_IRQHandler          ; 28: PCNT1 Interrupt
                DCD     PCNT2_IRQHandler          ; 29: PCNT2 Interrupt
                DCD     RTC_IRQHandler            ; 30: RTC Interrupt
                DCD     BURTC_IRQHandler          ; 31: BURTC Interrupt
                DCD     CMU_IRQHandler            ; 32: CMU Interrupt
                DCD     VCMP_IRQHandler           ; 33: VCMP Interrupt
                DCD     LCD_IRQHandler            ; 34: LCD Interrupt
                DCD     MSC_IRQHandler            ; 35: MSC Interrupt
                DCD     AES_IRQHandler            ; 36: AES Interrupt
                DCD     EBI_IRQHandler            ; 37: EBI Interrupt
                DCD     EMU_IRQHandler            ; 38: EMU Interrupt

__Vectors_End
__Vectors_Size  EQU     __Vectors_End - __Vectors

                AREA    |.text|, CODE, READONLY


; Reset Handler
Reset_Handler   PROC
                EXPORT  Reset_Handler             [WEAK]
                IMPORT  __main
                LDR     R0, =__main
                BX      R0
                ENDP


; delay_us
delay_us        PROC
                EXPORT delay_us
__delay_loop
                SUBS r0, r0, #1
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                NOP
                BNE	__delay_loop
                BX lr
                ENDP


; svc_call
svc_call        PROC
                EXPORT  svc_call
                SVC 0
                BX lr
                ENDP


; Dummy Exception Handlers (infinite loops which can be modified)

NMI_Handler     PROC
                EXPORT  NMI_Handler               [WEAK]
                EXPORT  sl_app_properties         [WEAK]
sl_app_properties     ; Provide a dummy value for the sl_app_properties symbol.
                B       .
                ENDP
HardFault_Handler\
                PROC
                EXPORT  HardFault_Handler         [WEAK]
                B       .
                ENDP
MemManage_Handler\
                PROC
                EXPORT  MemManage_Handler         [WEAK]
                B       .
                ENDP
BusFault_Handler\
                PROC
                EXPORT  BusFault_Handler          [WEAK]
                B       .
                ENDP
UsageFault_Handler\
                PROC
                EXPORT  UsageFault_Handler        [WEAK]
                B       .
                ENDP
SVC_Handler     PROC
                EXPORT  SVC_Handler               [WEAK]
                BX      LR
                ENDP
DebugMon_Handler\
                PROC
                EXPORT  DebugMon_Handler          [WEAK]
                B       .
                ENDP
PendSV_Handler  PROC
                EXPORT  PendSV_Handler            [WEAK]
                IMPORT  schedule
                
                ; Save stack of the current task
                PUSH {r4-r11}

                MOV R0, R13
                BL schedule
                
                ; Check if this is first start of next task
                CMP r1, #0
                BNE setup_stack

                ; Else case
                ; restore the stack from the next task and end the interrupt
                MOV r13, r0
                POP {r4-r11}
                MOV lr, 0xFFFFFFF9
                BX lr
                ENDP
setup_stack     mov R13, r0
                mov r2, 0x01000000;
                push {r2}               ; xPSR - 0x01000000
                push {r1}               ; PC
                mov r0, #0
                push {r0}               ;  LR
                sub R13, R13, #0x14     ; move the stack pointer 5 registers r12, r3, r2, r1, r0 caller saved

                ; for security the new task is not allowed to read the calle saved registers
                MOV r4, #0
                MOV r5, #0
                MOV r6, #0
                MOV r7, #0
                MOV r8, #0
                MOV r9, #0
                MOV r10, #0
                MOV r11, #0

                MOV lr, 0xFFFFFFF9
                BX lr

SysTick_Handler PROC
                EXPORT  SysTick_Handler           [WEAK]
                
                ; Trigger PendSV by setting bit 28 of ICSR register
                LDR     R0, =0xE000ED04          ; Address of ICSR
                LDR     R1, =0x10000000          ; Bit 28 = PendSV set-pending
                STR     R1, [R0]
                
                ; Return from interrupt
                BX      LR
                ENDP


DMA_IRQHandler  PROC
                EXPORT  DMA_IRQHandler            [WEAK]
				B       .
                ENDP

GPIO_EVEN_IRQHandler  PROC
                EXPORT  GPIO_EVEN_IRQHandler            [WEAK]
				B       .
                ENDP

TIMER0_IRQHandler  PROC
                EXPORT  TIMER0_IRQHandler            [WEAK]
				B       .
                ENDP

                EXPORT  TIMER0_IRQHandler         [WEAK]
                EXPORT  USART0_RX_IRQHandler      [WEAK]
                EXPORT  USART0_TX_IRQHandler      [WEAK]
                EXPORT  USB_IRQHandler            [WEAK]
                EXPORT  ACMP0_IRQHandler          [WEAK]
                EXPORT  ADC0_IRQHandler           [WEAK]
                EXPORT  DAC0_IRQHandler           [WEAK]
                EXPORT  I2C0_IRQHandler           [WEAK]
                EXPORT  I2C1_IRQHandler           [WEAK]
                EXPORT  GPIO_ODD_IRQHandler       [WEAK]
                EXPORT  TIMER1_IRQHandler         [WEAK]
                EXPORT  TIMER2_IRQHandler         [WEAK]
                EXPORT  TIMER3_IRQHandler         [WEAK]
                EXPORT  USART1_RX_IRQHandler      [WEAK]
                EXPORT  USART1_TX_IRQHandler      [WEAK]
                EXPORT  LESENSE_IRQHandler        [WEAK]
                EXPORT  USART2_RX_IRQHandler      [WEAK]
                EXPORT  USART2_TX_IRQHandler      [WEAK]
                EXPORT  UART0_RX_IRQHandler       [WEAK]
                EXPORT  UART0_TX_IRQHandler       [WEAK]
                EXPORT  UART1_RX_IRQHandler       [WEAK]
                EXPORT  UART1_TX_IRQHandler       [WEAK]
                EXPORT  LEUART0_IRQHandler        [WEAK]
                EXPORT  LEUART1_IRQHandler        [WEAK]
                EXPORT  LETIMER0_IRQHandler       [WEAK]
                EXPORT  PCNT0_IRQHandler          [WEAK]
                EXPORT  PCNT1_IRQHandler          [WEAK]
                EXPORT  PCNT2_IRQHandler          [WEAK]
                EXPORT  RTC_IRQHandler            [WEAK]
                EXPORT  BURTC_IRQHandler          [WEAK]
                EXPORT  CMU_IRQHandler            [WEAK]
                EXPORT  VCMP_IRQHandler           [WEAK]
                EXPORT  LCD_IRQHandler            [WEAK]
                EXPORT  MSC_IRQHandler            [WEAK]
                EXPORT  AES_IRQHandler            [WEAK]
                EXPORT  EBI_IRQHandler            [WEAK]
                EXPORT  EMU_IRQHandler            [WEAK]



USART0_RX_IRQHandler
USART0_TX_IRQHandler
USB_IRQHandler
ACMP0_IRQHandler
ADC0_IRQHandler
DAC0_IRQHandler
I2C0_IRQHandler
I2C1_IRQHandler
GPIO_ODD_IRQHandler
TIMER1_IRQHandler
TIMER2_IRQHandler
TIMER3_IRQHandler
USART1_RX_IRQHandler
USART1_TX_IRQHandler
LESENSE_IRQHandler
USART2_RX_IRQHandler
USART2_TX_IRQHandler
UART0_RX_IRQHandler
UART0_TX_IRQHandler
UART1_RX_IRQHandler
UART1_TX_IRQHandler
LEUART0_IRQHandler
LEUART1_IRQHandler
LETIMER0_IRQHandler
PCNT0_IRQHandler
PCNT1_IRQHandler
PCNT2_IRQHandler
RTC_IRQHandler
BURTC_IRQHandler
CMU_IRQHandler
VCMP_IRQHandler
LCD_IRQHandler
MSC_IRQHandler
AES_IRQHandler
EBI_IRQHandler
EMU_IRQHandler
                B       .
                ENDP

                ALIGN

; User Initial Stack & Heap

                IF      :DEF:__MICROLIB

                EXPORT  __initial_sp
                EXPORT  __heap_base
                EXPORT  __heap_limit

                ELSE

                IMPORT  __use_two_region_memory
                EXPORT  __user_initial_stackheap

__user_initial_stackheap PROC
                LDR     R0, =  Heap_Mem
                LDR     R1, =(Stack_Mem + Stack_Size)
                LDR     R2, = (Heap_Mem +  Heap_Size)
                LDR     R3, = Stack_Mem
                BX      LR
                ENDP

                ALIGN

                ENDIF

                END
