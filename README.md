# Scheduler for ARM-Cortex M4

Small preemptive task scheduler for an ARM-Cortex M4 microcontroller. It was originally developed as part of a university project to gain a deeper understanding of task scheduling, processor context switching and the Cortex-M exception mechanism. The scheduler assigns each task its own stack and periodically switches between enabled tasks. A major focus of the project is the low-level implementation of the context switch itself.

> [!NOTE]
> This project is currently being
> reworked and documented. The scheduler implementation and its underlying
> concepts are documented below, but the current version has not yet been
> fully revalidated on the original target hardware.

## Functionality

- Preemptive round-robin scheduling of up to 8 tasks
- Separate 8192-byte stack for each task
- Periodic scheduling triggered by the Cortex-M SysTick timer
- Context switching performed through the PendSV exception
- Manual preservation of the complete task context
- Support for initial task startup and resuming previously interrupted tasks

## Technical documentation

The source files relevant for the scheduler are `scheduler.c`, `scheduler.h` and `startup.s`.

### task_t and init_tasks

Every task is represented by a `task_t` struct defined inside of `scheduler.h`:

```c
typedef struct  {
    uint8_t id;
    void (*start_function)(void);
    uint32_t* stack_pointer;

    uint8_t first_start;
    uint8_t enabled;
} task_t;
```

- `id`: unique identifier for each task
- `void (*start_function)(void)`: function pointer to the function the task is made up of
- `stack_pointer`: pointer pointing at the stack of the task
- `first_start`: flag indicating a task to be initially scheduled
- `enabled`: flag indicating whether the task is used at all

The memory used for the individual task stacks is statically allocated in the global `stacks` array. All the tasks are represented by an array of `task_t` data types.

```c
#define MAX_TASKS 8
#define STACK_SIZE 8192

uint8_t stacks [MAX_TASKS * (STACK_SIZE)]  __attribute__((aligned(8)));
task_t tasks [MAX_TASKS];

// The task that is currently scheduled
uint8_t current_scheduled_task;

void init_tasks(){
    for (int i = 0; i < MAX_TASKS; i++) {
        tasks[i].id = i;
        tasks[i].start_function = 0;
        tasks[i].stack_pointer = stacks + ((i + 1) * STACK_SIZE);
        tasks[i].first_start = 1;
        tasks[i].enabled = 0;
    }
    current_scheduled_task = 0;
}
```

The function `init_tasks` prepares the tasks for being scheduled. Each task receives an id, the reference to a starting function which is initially a `NULL` pointer and initial values for `first_start` and `enabled`. Each tasks available stack memory is a slice of the global stack `uint8_t` array. The array is basically cut into 8192 bytes size portions with the starting address of the portion being the task's initial stack pointer. The global variable `current_scheduled_task` holds the currently scheduled task id which is initially is 0. With this setup done we are ready to schedule!

### General scheduling concept

On entry to an interrupt service routine, the processor automatically performs a so called stacking operation. The registers `r0-r3`, `r12`, the link register `LR`, the program counter `PC` and the program status register `xPSR` are pushed onto the currently active stack. This preserves the execution context of the interrupted code, allowing the ISR to execute without losing the register state required to resume it afterwards. When returning from the ISR, the processor performs the corresponding de-stacking operation and restores these registers from the stack.

The scheduler exploits this feature of stacking and de-stacking before and after the execution of interrupt service routines (ISR) to perform context switches. The Cortex-M system timer (`SysTick`) provides the periodic scheduling trigger. Each time the timer expires, the `SysTick_Handler` marks the `PendSV` exception as pending. The actual context switch is then performed inside the `PendSV_Handler`. This separates the periodic scheduling trigger from the context switch itself. `PendSV` is configured with a low interrupt priority, allowing higher-priority interrupts to be handled before the pending context switch is performed.

Normally, the return of an ISR or exception would restore the context of the same task that was interrupted. To perform a context switch, the scheduler instead selects the next task and replaces the current stack pointer with the saved stack pointer of the selected task. Consequently, when the exception returns, the processor performs a de-stacking operation using the newly selected task's stack. The restored register values therefore belong to the newly scheduled task. This causes the execution to continue from the point at which the task was previously interrupted. For a task that did not run before, a stack frame containing register values must first be build so so that the same de-stacking-return mechanism can be used to start it.

To dig deeper let's have a look at the schedulers c and assembly code.

### Triggering a Context Switch

The `SysTick_Handler` itself does not perform any scheduling logic. Instead, it sets the `PendSV` exception to pending, thereby requesting a context switch. The processor then executes the `PendSV_Handler`. The `SysTick_Handler` therefore determines when a context switch is requested, while the `PendSV_Handler` performs the actual switch.

### Performing the Context Switch

Let's start by having a look at the ISR assembly inside of `startup.s`

```asm
PendSV_Handler
    ...
    ; Save stack of the current task
    PUSH {r4-r11}

    MOV R0, R13
    BL schedule

...
```

First a `PUSH {r4-r11}` is performed which pushes the contents of the register `r4` to `r11` onto the stack. Recall that a stacking operation does not automatically push these registers to the stack. In order to restore all the task's registers later on we are forced to backup these registers on our own. Then we move the content of register `r13` which is the `SP` register into `R0` preparing a call to the `schedule` function. According to the ARM calling convention, the first four function arguments are passed through registers `r0` to `r3`, with the first argument being placed in `r0`, the second in `r1`, and so on. The `schedule` function therefore receives the current `SP` register as its only argument. `BL schedule` then calls the function defined in `scheduler.c`.

```c
...
void schedule(uint32_t *current_stack_pointer) {
    tasks[current_scheduled_task].stack_pointer = current_stack_pointer;

    task_t next_task;

    // find the next task
    for (uint8_t i = 0; i<MAX_TASKS; i++) {
        uint8_t next_task_index = (current_scheduled_task + 1 + i) % MAX_TASKS;
        if(tasks[next_task_index].enabled == 1) {
            next_task = tasks[next_task_index];
            break;
        }
    }

    current_scheduled_task = next_task.id;

    __asm volatile ("mov R0, %[stack_pointer]" : : [stack_pointer] "r" (next_task.stack_pointer));

    if(next_task.first_start == 1) {
        __asm volatile ("mov R1, %[start_function]" : : [start_function] "r" (next_task.start_function));
    } else {
        __asm volatile ("mov R1, 0x0");
    }

}
...
```

First the argument being the current task's stackpointer is saved to the corresponding task struct. We need this value later on when the task is rescheduled and a de-stacking operation is about to be performed. Then the next task to be scheduled is determined and the global variable `current_scheduled_task` holding the id of the currently scheduled task is updated. So far we did a backup of a stackpointer and determined the next task to run. Now for the interesting part.

In order to perform the context switch the calling assembly code needs two parts of information. First it needs the new task's stackpointer so the processor can do its de-stacking from the new task's stack. And secondly it needs to know whether the new task has ever been run before. In case the task has never been run before the calling code must build an initial stack frame to de-stack from. This distinction is made by the value of the task structs `first_start` flag. For returning these information we simply use registers `r0` and `r1`.

For the first part of information the new task's stack pointer is simply moved into the register `r0`. The calling code can then simply read this register. For the second part of information we update the value of register `r1`. In case the task has never been run before we put the address of the function making up this task into register `r1`. For the initial build of a stack frame this information is needed since we need an initial value for the `PC` register. In case the task has already been run however we simply put the value 0 into `r1`. This signalizes the calling assembly to not build an initial stack frame since there is already one to de-stack from. We now return to the assembly code.

```asm
...

CMP r1, #0
BNE setup_stack

; Else case
; restore the stack from the next task and end the interrupt
MOV r13, r0
POP {r4-r11}
MOV lr, 0xFFFFFFF9
BX lr

...
ENDP
```

Let's follow the `r1` register holding the value 0 first. In this case we simply move `r0` holding the new task's stackpointer into `SP` (`R13`). We then restore the registers `r4` to `r11` by calling `POP {r4-r11}`. Recall these registers not being restored by the upcoming de-stacking operation. We finally move the value `0xFFFFFFF9` into the link register `LR` and branch to it using `BX lr`. This value is a special return value recognized by the processor rather than a regular return address. Executing `BX lr` with this value causes the processor to return from the interrupt service routine. As part of the return, the processor automatically performs the corresponding de-stacking operation, restoring `r0-r3`, `r12`, `LR`, `PC` and `xPSR` from the currently selected task's stack. Since we updated the stack pointer, the restored context belongs to the newly scheduled task and execution continues at the restored PC.

Let's now have a look at the `r1` register holding the address of a function meaning we are about to schedule a task that has never been scheduled before. `r1` unequal to 0 causes the code to branch to the `setup_stack` mark.

```asm
setup_stack:

    mov R13, r0

    mov r2, 0x01000000;
    push {r2}               ; xPSR - 0x01000000

    push {r1}               ; PC

    mov r0, #0
    push {r0}               ;  LR

    sub R13, R13, #0x14     ; move the stack pointer 5 registers r12, r3, r2, r1, r0 caller-saved

    // for security the new task is not allowed to read the callee-saved registers
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
```

We first again move the `r0` holding the new task's stackpointer into `SP`. We now must build an initial stack frame to de-stack from. The stack frame has to match the layout expected by the processor during the return of an interrupt service routine. The initial register values must be placed on the task's stack in the same order in which they would appear after a regular context save. Effectively we create an artificial context that has never been used before. To accomplish this we begin by pushing the value `0x01000000` to the stack. This value represents the content of the `xPSR` register. We continue by pushing the `r1` register onto the stack. Remember `r1` contains the address of the function that makes up the task. The pushed value is placed at the position from which the processor will later restore the `PC` register during de-stacking. After returning from the interrupt service routine `PC` will point to the task's function and execution will begin at its first instruction. Next we push the desired content of the `LR` register to the stack. Since execution of the task's function hasn't started we just push the value 0. The only thing left to do for our stack frame is to push the initial values for the registers `r12` and `r0-r3`. We just mimic this by running `sub R13, R13, #0x14` which decreases the stack pointer by the value of `0x14`. With this our stack frame is done and ready to be de-stacked from.

Before leaving the interrupt service routine the registers `r4-r11` still require special attention. As already mentioned these registers are not restored automatically by the processor during the de-stacking. Since the newly created task has never executed before, no meaningful register state exists for them yet. Without explicitly initializing them, they could therefore still contain values left behind by the previously running task. That's the reason behind moving zero to the registers `r4` to `r11`. Now we can finally move the value of `0xFFFFFFF9` into `LR` again and branch away to it via `BX lr`. This is the same way to leave an interrupt service routine already discussed in the `r1` equal to 0 path.

With this, both cases are covered: a task can either resume from a previously saved context or start for the first time from an artificially constructed one. From the processor's perspective, both cases work the same way. The task's context is restored from its stack and execution continues at the address loaded into the `PC` register. For now we are done with our scheduler and the context switching logic. Let's see how to use the scheduler!

## Usage

Before tasks can be scheduled, the scheduler must be initialized by calling `init_tasks()`:

```c
init_tasks();
```

Tasks can then be registered using `add_task(..)`. The function takes a pointer to the task function and the ID under which the task should be registered:

```c
add_task(&task1, 0);
add_task(&task2, 1);
```

Internally, `add_task` stores the provided function as the task's entry point and marks the task as enabled and ready for its initial execution:

```c
void add_task(void (*function), uint8_t task_id) {
    tasks[task_id].start_function = function;
    tasks[task_id].first_start = 1;
    tasks[task_id].enabled = 1;
}
```

After all tasks have been registered, the scheduler is started by calling:

```c
start_scheduler();
```

`start_scheduler` performs the initial transition from the application's execution context to the first task. It sets the stack pointer to the stack allocated for task 0, marks the task as started, updates `current_scheduled_task` and finally calls the task's start function:

```c
void start_scheduler()
{
    __asm volatile (
        "mov R13, %[stack_pointer]"
        :
        : [stack_pointer] "r" (tasks[0].stack_pointer)
    );

    tasks[0].first_start = 0;
    current_scheduled_task = 0;

    (*tasks[0].start_function)();
}
```

A minimal setup with two tasks therefore looks as follows:

```c
int main(void)
{
    SysTick_Config(F_CPU / 100);          // 100 Hz = 10ms per tick (adjust as needed)
    NVIC_SetPriority(PendSV_IRQn, 0xFF);  // very low priority for the PendSV_Handler routine

    init_tasks();

    add_task(&task1, 0);
    add_task(&task2, 1);

    start_scheduler();

    while (1) {
        ;
    }
}
```

Once `start_scheduler()` has started the first task, subsequent task switches are triggered periodically by the system timer interrupt.
