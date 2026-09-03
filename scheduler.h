#include <stdint.h>

#define MAX_TASKS 8
#define STACK_SIZE 8192
//#define CANARY 0x01234567

typedef struct  {
    uint8_t id;
    void (*start_function)(void);
    uint32_t* stack_pointer;
    // Flags for the scheduler
    uint8_t first_start; // this function should not be rescheduled but started from the "start_function pointer"
    uint8_t enabled; // If the task is used at all.
} task_t;

void init_tasks();
void add_task(void (*function), uint8_t task_id);
void start_scheduler();
schedule_result_t schedule(uint32_t *current_stack_pointer);