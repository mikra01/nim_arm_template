.text
.code 32
.global _start
.global vectors_end
_start:
 LDR PC, reset_handler_addr
 LDR PC, undef_handler_addr
 LDR PC, swi_handler_addr
 LDR PC, prefetch_abort_handler_addr
 LDR PC, data_abort_handler_addr
 LDR PC, hyp_trap_addr
 LDR PC, irq_handler_addr
 LDR PC, fiq_handler_addr
 
reset_handler_addr: .word reset_handler
undef_handler_addr: .word undef_handler
swi_handler_addr: .word  swi_handler // do not work with direct nim call with irq-rout
prefetch_abort_handler_addr: .word prefetch_abort_handler
data_abort_handler_addr: .word data_abort_handler
hyp_trap_addr: .word hyp_trap_handler
irq_handler_addr: .word irq_handler /* defined in c */
fiq_handler_addr: .word fiq_handler
vectors_end:

reset_handler:
/* wait for pll stabilization */
     NOP     
     NOP
     NOP
     NOP
     NOP
     NOP
     NOP
     NOP
 /* set Supervisor stack */
 LDR sp, =_stack
 /* copy exception table to address 0 */
     LDR   r0, = 0x10000         // r0 = pointer to source block
     LDR   r1, = 0x0             // r1 = pointer to destination block
     MOV   r2, #16               // r2 = number of words to copy
excopy:
        LDR   r3, [r0], #4       // load a word from the source and
        STR   r3, [r1], #4       // store it to the destination
        SUBS  r2, r2, #1         // decrement the counter
        BNE   excopy             // ... copy more
end_excopy:
 // BL copy_vectors
 // FIXME: call nim rt
 /* get Program Status Register */
 MRS r0, cpsr
 /* go in IRQ mode */
 BIC r1, r0, #0x1F
 ORR r1, r1, #0x12
 MSR cpsr, r1
 /* set IRQ stack */
 LDR sp, =irq_stack_top
 /* Enable IRQs */
 BIC r0, r0, #0x80  
 /* go back in Supervisor mode */
 MSR cpsr, r0
/* init .bss and data section   */
                MOV     R0, #0 
                LDR     R1, = __bss_start__ 
                LDR     R2, = __bss_end__ 
                CMP     R1,R2
                BEQ     BSSIsEmpty /* start == end -> bail out */
LoopZI:         CMP     R1, R2 
                STRLO   R0, [R1], #4 
                BLO     LoopZI 
BSSIsEmpty:  
 BL NimMain
 SVC #88
 BL kmain
 SVC #99
 LDR  r0,=resetBoard /* exit qemu */
 BX r0  

el:
 NOP
 b el

/* todo: copy data section from flash to ram */

//   MSR CPSR_c, 0x13 /* Supervisor mode */
//    LDR SP, =stack_top
//   MSR CPSR_c, 0x10 /* User mode */
//    LDR SP, =usr_stack_top
//    BL  usermode_function

swi_handler:
    push {r0,r1,lr}
    ldr r0,[lr,#-4] // 1st param: swi number
	BIC r0, r0, #0xFF000000 // unmask swi number
    mov r1,sp       // 2nd param: stackpointer  
    bl _swi_ex_handler2
    pop {r0,r1,lr}
    movs pc,lr
	
trap_handler:
    push {r0,r1,lr}
    ldr r0,[lr,#-4] // 1st param: swi number
	BIC r0, r0, #0xFF000000 // unmask swi number
    mov r1,sp       // 2nd param: stackpointer  
    bl _swi_ex_handler2
    pop {r0,r1,lr}
    movs pc,lr


irq_handler:
    push {r0,r1,lr} // 0x10140000 PICIRQStatus
    ldr r0, PICBASE // PIC Base
    ldr r0, [r0]
	PICBASE: .word 0x10140000
    clz r0, r0
    mov r1,sp       // 2nd param: stackpointer  
    bl irq_handler_nim
    pop {r0,r1,lr}
    movs pc,lr
	
	
/* helper functions related to SP/PC/memoryaccess */
.global fetchStackPtr
fetchStackPtr:
    mov r0,sp
    bx lr

.global fetchPC
fetchPC:
    mov r0,pc
    bx lr

.global fetchWord
fetchWord:
    ldr r0,[r0]
    bx lr

.global storeWord
storeWord:
    str r1,[r0]
    bx lr

.global store16
store16:
    strh r1,[r0]
    bx lr

.global store8
store8:
    strb r1,[r0]
    bx lr

.global fetch16
fetch16:
    ldrh r0,[r0]
    bx lr

.global fetch8
fetch8:
    ldrb r0,[r0]
    bx lr


.data 0
.global _trapTable
_trapTable: .int 0,0,0,0,0,0,0,0,0,0
              .int 0,0,0,0,0,0,0,0,0,0
		      .int 0,0,0,0,0,0,0,0,0,0
		      .int 0,0
/* reserve space for 32 user defined software traps */			  


.end