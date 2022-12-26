import strutils, times, volatile
import timer

const uartAddr : ptr char = cast[ptr char](0x101f1000.int) #versatilepb uart0 addr
const pUnlockResetReg : ptr uint32 = cast[ptr uint32](0x10000020.uint32)
const pResetReg : ptr uint32 = cast[ptr uint32](0x10000040.uint32)

{.emit: """ 
volatile unsigned int * const UART0DR = (unsigned int *)0x101f1000;
__attribute__((used)) void _fini(void) {} // ensure linker happyness
                                          // exit() is never called
													
// void __attribute__((interrupt)) irq_handler() {
// /* echo the received character + 1 */
// // UART0DR = UART0DR + 1;
// }

void __attribute__((interrupt)) undef_handler(void) { *UART0DR = (unsigned int)'U'; }
void __attribute__((interrupt)) prefetch_abort_handler(void) { *UART0DR = (unsigned int)'P'; }
void __attribute__((interrupt)) hyp_trap_handler(void) { *UART0DR = (unsigned int)'T'; }
void __attribute__((interrupt)) data_abort_handler(void) { *UART0DR = (unsigned int)'D'; }
void __attribute__((interrupt)) fiq_handler(void) { *UART0DR = (unsigned int)'F'; }

// void _swi_ex_handler(int v1, int v2){}
				
#define doSoftwareIRQ(trapNum) asm volatile ("svc %0" : : "I" (trapNum) )
// 0 to 224–1 (a 24-bit value) in an ARM instruction.
// further reading (svc with register does not work for older cores)
// https://developer.arm.com/documentation/dui0056/d/handling-processor-exceptions/swi-handlers/calling-swis-from-an-application?lang=en

			
""".}

# TODO: analytic asm statements (startup.S) as gnu inline asm (not done - gnu inline asm issues)
# add signal handling (table for signums: 2 11 6 8 4)
# implement timer-tick / supv vs user mode (kernel in user mode)
# qemu dual console windows (input vs output)
# nestable interrupts / generic trap-handler / taskswitchroutine with svc #0)
# add threading support 
# support newlib reentrant struct ( xx_r calls)

template doSoftwareIRQ( trapNum : static int)=
  # quirky solution. first define the c-macro SVC and here
  # emit it with a template
  {.emit: ["doSoftwareIRQ(",astToStr(trapNum), ");"].}

type
  TextException = object of CatchableError

proc resetBoard() {.exportc.} =
  # needed to exit qemu - referenced by startup.S
  volatileStore(pUnlockResetReg,0xA05F.uint32)
  volatileStore(pResetReg,0x106.uint32)

template echo_uart0( p1: string, size : int ) =
  for i in 0..size-1:
    volatileStore(uartAddr,p1[i])

  volatileStore(uartAddr,' ') 


include syscalls

proc IRQHandler( picIRQStatus : int, stackptr: int)  {.cdecl,exportc:"irq_handler_nim"} =
  # todo: strip the sourceno from stack and evaluate
  echo " irq-exception picIRQStatus " & $picIRQStatus & " " & $stackptr  
  # mask with 0x10 to get bit4 (timer0 and 1)
  if (picIRQStatus and 0x10.int ) shr 4 == 1:    
    var t = volatileLoad(timer1MIS)
    if timer1Fired():
      clearTimer1IRQ()
      echo "timer1fired"
    else:
      echo "timer2fired"
  
proc SWIExceptionHandler(exNo : int , stackptr : int ) 
  {.cdecl,exportc:"_swi_ex_handler2"} = #,codegenDecl: "$# __attribute__((interrupt('IRQ'))) $#$#"} =
  # gcc further reading: https://gcc.gnu.org/onlinedocs/gcc/ARM-Function-Attributes.html
  # works at the moment only with double indirection (asm-wrapper)
  # compiler dependent 
  # from the doc https://developer.arm.com/documentation/dui0056/d/handling-processor-exceptions/swi-handlers/swi-handlers-in-c-and-assembly-language
  # we can now access the sp values
  echo " swi-exception number " & $exNo & " " & $stackptr

# for reentrant interrupts see:
# https://developer.arm.com/documentation/dui0203/j/handling-processor-exceptions/armv6-and-earlier--armv7-a-and-armv7-r-profiles/interrupt-handlers?lang=en  

proc fetchStackPtr () : uint {.importc:"fetchStackPtr",cdecl.}
proc storeWord(loc : uint , val : uint) {.importc:"storeWord",cdecl.}
proc fetchWord(loc : uint ): uint {.importc:"fetchWord",cdecl.}
proc fetchPC(): uint {.importc:"fetchPC",cdecl.}

proc doDingDong() =
  # just throw an exception
  raise newException(TextException, "ding-dong")

# proc write( file : cint, data : cstring, size : cint) : cint {.exportc:"_write",cdecl.} =
#  # retarget newlib's write 
#  # file: stdin = 0 / stdout = 1 / stderr = 2
#  # let p = $data
#  var dat = $data
#  echo_uart0(dat,size)
#  return size

#proc newlibRaise( signum : cint ) : cint {.exportc:"raise",cdecl.} =  
#  ## doSoftwareIRQ(22)
#  var t = "raise called"  
#  echo_uart0(t,t.len)
#  return 0

proc unhandledException( e : ref Exception ) =
  echo "unhandled_ex"
  echo getCurrentExceptionMsg()
  newlibAbort()
  
proc writeMem( loc : pointer , val : uint) = 
  asm """ str %value,[%mem] : : "mem" (`loc`), "value" (`val`) """  
#  asm """ mov r0,r0 """
# todo: change names: writeMem / readMem

proc readMem( loc : pointer) : uint = 
 asm """
    ldr %b,[%a]
    :
    :"a"(`loc`), "b"(`result`)
  """  

proc readPC() : pointer {.cdecl.}  = 
  asm """ ldr %0,PC : : ("=&r") (`result`) """  

template readSP( ) : pointer = 
 asm """
    ldr %a,SP
    :
    :"a"(`result`)
  """  

proc kmain() {.exportc.} =
  # writeMem(cast[pointer](0x0),0.uint)
  # storeWord(0.uint,0.uint)

  # var loc : uint = 0
  # for i in 0..15: # irq vector table: 2*8 words
  #  storeWord(loc,fetchWord(0x10000+loc))
  #  loc = loc + 4
  # nim variant: copy exception table (done in startup.S) 

  system.unhandledExceptionHook = unhandledException
  # unhandled ex-hook does not work
  
  doSoftwareIRQ(17)
  echo " barebone example with Nim"

  doSoftwareIRQ(17)  
   
  var x = @[1, 2, 3, 4]
    
  for i in 0..x.len-1:
    echo $x[i]
  
  echo "before dingdong"

  # output to stderr
  stderr.writeLine("to stderr")

  # doDingDong()
  initTimer1()
  enableTimer1IRQ() 
  
  try:
    doDingDong()
  except: 
    echo "caught exception " & getCurrentExceptionMsg()      
  finally:
    echo "finally block entered"
  echo "tick"
  pollTimer1()
  echo "tock"
  echo ".. the end .."
  echo "tick"
  pollTimer1()
  echo "tock"
  
  var w = 0
  
  while true:
    w = w+1
  
  doSoftwareIRQ(18)
  doSoftwareIRQ(22)
  
  #timer 
  # https://singpolyma.net/2012/02/writing-a-simple-os-kernel-hardware-interrupts/
  
  # todo: code to flash, initialized data to ram and setup data section
  # todo: route stdout/stderr to uart5
  # and eval builtins (https://gcc.gnu.org/onlinedocs/gcc-4.9.0/gcc/Other-Builtins.html#Other-Builtins)
  # http://www.embedded.com/story/OEG20020103S0073
  
  #newlib
  # http://neptune.billgatliff.com/newlib.html
  # https://www.eetimes.com/embedding-with-gnu-newlib/  
  
  # data sections init https://stackoverflow.com/questions/38914019/how-to-make-bare-metal-arm-programs-and-run-them-on-qemu
  # https://blog.thea.codes/the-most-thoroughly-commented-linker-script/
  #
  # https://interrupt.memfault.com/blog/how-to-write-linker-scripts-for-firmware LMA load address VMA virtual address