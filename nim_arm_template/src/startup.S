.global _start
_start:
B Reset_Handler /* Reset handler */
B Undefined /* Undefined mode handler */
B SWI /* Software interrupt */
B Prfetch_Abort /* Prefetch abort handler */
B Data_Abort /* Data abort handler */
B IRQ_Handler /* IRQ handler */
B FIQ_Handler /* FIQ handler */
Undefined: /* do nothing */
B .
SWI: /* do nothing */
B .
Prfetch_Abort: /* do nothing */
B .
Data_Abort: /* do nothing */
B .
IRQ_Handler: /* do nothing */
B .
FIQ_Handler: /* do nothing */
B .
Reset_Handler:
 LDR sp, =_stack
/* init .bss section   */
                MOV     R0, #0 
                LDR     R1, =__bss_start__ 
                LDR     R2, =__bss_end__ 
                CMP     R1,R2
                BEQ     BSSIsEmpty
LoopZI:         CMP     R1, R2 
                STRLO   R0, [R1], #4 
                BLO     LoopZI 
BSSIsEmpty:
  BL NimMain  /* startup nim */
  BL kmain    /* invoke main */
  LDR  r0,=resetBoard /* exit qemu */
  BX r0  
  B . 
