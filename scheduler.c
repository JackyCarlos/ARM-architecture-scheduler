#include "scheduler.h"
#include "cmsis/efm32gg990f1024.h"
#include <stdint.h>
#include <stddef.h>

// this is where all stacks live
// the stack for task 0 is at stacks[0]
// the stack for task 1 is at stacks[1]
uint8_t stacks [MAX_TASKS * (STACK_SIZE)]  __attribute__((aligned(8)));

// this is the list of of task that can run on the system
task_struct tasks [MAX_TASKS];

// the task that is currently scheduled
uint8_t current_scheduled_task = 0;

void init_tasks(){
    for (int i = 0; i < MAX_TASKS; i++) {
        tasks[i].id = i;
        tasks[i].start_function = 0;
        tasks[i].stack_pointer = stacks + ((i + 1) * STACK_SIZE - 4);
        tasks[i].first_start = 1;
        tasks[i].enabled = 0;
    }
    current_scheduled_task = 0;
}

// adds a task to the tasklist and enables it.
void add_task(void (*function), uint8_t task_id){
    tasks[task_id].start_function = function;
    tasks[task_id].first_start = 1;
    tasks[task_id].enabled = 1;
}

// This function starts the scheduler,
// It must be run aftet the tasks have been setup
// and must only be called once!
void start_scheduler() {
    // What do we want to do?
    // Set stack pointer to task[0].stack_pointer
    __asm volatile ("mov R13, %[stack_pointer]" : : [stack_pointer] "r" (tasks[0].stack_pointer));
    // call the start function of our first task
    tasks[0].first_start = 0;
    current_scheduled_task = 0;
    (*tasks[0].start_function)();
}

schedule_result_t schedule(uint32_t *current_stack_pointer)
{
    schedule_result_t result = {0};

    tasks[current_scheduled_task].stack_pointer = current_stack_pointer;

    task_struct *next_task = NULL;

    for (uint8_t i = 0; i < MAX_TASKS; i++) {
        uint8_t next_task_index =
            (current_scheduled_task + 1 + i) % MAX_TASKS;

        if (tasks[next_task_index].enabled == 1) {
            next_task = &tasks[next_task_index];
            break;
        }
    }

    if (next_task == NULL) {
        result.stack_pointer = current_stack_pointer;
        result.start_function = NULL;
        return result;
    }

    current_scheduled_task = next_task->id;

    result.stack_pointer = next_task->stack_pointer;

    if (next_task->first_start == 1) {
        result.start_function = next_task->start_function;
        next_task->first_start = 0;
    } else {
        result.start_function = NULL;
    }

    return result;
}
