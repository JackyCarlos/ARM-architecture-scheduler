#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "cmsis/efm32gg990f1024.h"
#include "cmsis/core_cm3.h"

#include "scheduler.h"

#define F_CPU 48000000U

void task1() {
    while(1) {
        // set register r1 to 5
		__asm("mov r0, 0xA");
        __asm("mov r1, 0xA");
        __asm("mov r2, 0xA");
        __asm("mov r3, 0xA");
        __asm("mov r4, 0xA");
        __asm("mov r5, 0xA");
        __asm("mov r6, 0xA");
        __asm("mov r7, 0xA");
        __asm("mov r8, 0xA");
        __asm("mov r9, 0xA");
        __asm("mov r10, 0xA");
        __asm("mov r11, 0xA");
	    __asm("mov r12, 0xA");
    }
}

void task2() {
    while(1) {
        // set register r1 to 5
		__asm("mov r0, 0xB");
        __asm("mov r1, 0xB");
        __asm("mov r2, 0xB");
        __asm("mov r3, 0xB");
        __asm("mov r4, 0xB");
        __asm("mov r5, 0xB");
        __asm("mov r6, 0xB");
        __asm("mov r7, 0xB");
        __asm("mov r8, 0xB");
        __asm("mov r9, 0xB");
        __asm("mov r10, 0xB");
        __asm("mov r11, 0xB");
		__asm("mov r12, 0xB");
        //svc_call();
    }
}

void task3() {
    while(1) {
        // set register r1 to 5
		__asm("mov r0, 0xC");
        __asm("mov r1, 0xC");
        __asm("mov r2, 0xC");
        __asm("mov r3, 0xC");
        __asm("mov r4, 0xC");
        __asm("mov r5, 0xC");
        __asm("mov r6, 0xC");
        __asm("mov r7, 0xC");
        __asm("mov r8, 0xC");
        __asm("mov r9, 0xC");
        __asm("mov r10, 0xC");
        __asm("mov r11, 0xC");
		__asm("mov r12, 0xC");
        //svc_call();
    }
}

int main(void) {
    // Configure SysTick timer for periodic task switching
    SysTick_Config(1000);  // 100 Hz = 10ms per tick (adjust as needed)

    // Set PendSV to lowest priority (highest number = lowest priority)
    NVIC_SetPriority(PendSV_IRQn, 0xFF);

	// scheduler stuff
	init_tasks();
	add_task(&task1, 0);
	add_task(&task2, 1);
	add_task(&task3, 2);
	start_scheduler();

	while(1) {
		;
	}
}
