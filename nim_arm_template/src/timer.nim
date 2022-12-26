import volatile
# basic timer implementation (versatilepb board)

#http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0271d/index.html
const timer1Load : ptr uint32 = cast[ptr uint32](0x101E2000.uint32) #versatilepb timer0 base
const timer1Value : ptr uint32 = cast[ptr uint32](0x101E2004.uint32)
const timer1Control : ptr byte = cast[ptr byte](0x101E2008.uint32)  
const timer1INTClr : ptr uint32 = cast[ptr uint32](0x101E200C.uint32)
const timer1MIS* : ptr uint32 = cast[ptr uint32](0x101E2014.uint32)
const TIMER_EN : byte = 0x80 
const TIMER_PERIODIC : byte = 0x40 
const TIMER_INTEN : byte = 0x20 
const TIMER_32BIT : byte = 0x02 
const TIMER_ONESHOT : byte = 0x01

# PRIMARY INTERRUPT CONTROLLER REGS
# http://infocenter.arm.com/help/topic/com.arm.doc.dui0224i/I1042232.html 
const picINTEnable : ptr uint32 = cast[ptr uint32](0x10140010.uint32) #read/write 
const picINTENclear : ptr uint32 = cast[ptr uint32](0x10140014.uint32) #write
const PIC_TIMER01 : uint32 = 0x10
const picVectorAddr : ptr uint32 = cast[ptr uint32](0x10140030.uint32) #read/write

# http://infocenter.arm.com/help/topic/com.arm.doc.ddi0181e/I1006461.html 
#define VIC_INTENABLE 0x4 /* 0x10 bytes */

# further reading: https://singpolyma.net/2012/02/writing-a-simple-os-kernel-hardware-interrupts/

{.emit: """ 
/* http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0271d/index.html */
#define TIMER0 ((volatile unsigned int*)0x101E2000)
#define TIMER_VALUE 0x1 /* 0x04 bytes */
#define TIMER_CONTROL 0x2 /* 0x08 bytes */
#define TIMER_INTCLR 0x3 /* 0x0C bytes */             
#define TIMER_MIS 0x5 /* 0x14 bytes */
/* http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0271d/Babgabfg.html */
#define TIMER_EN 0x80
#define TIMER_PERIODIC 0x40
#define TIMER_INTEN 0x20
#define TIMER_32BIT 0x02
#define TIMER_ONESHOT 0x01			
""".}

proc initTimer1* = 
  volatileStore(timer1Load,1000000.uint32) # tick each second
  var val : byte = TIMER_EN 
  val = val or TIMER_PERIODIC or TIMER32_BIT or TIMER_INTEN
  volatileStore(timer1Control, val ) 

proc enableTimer1IRQ* =
  volatileStore(picINTEnable,PIC_TIMER01)
  # volatileStore(picINTENclear,0x1.uint32)
  
proc clearTimer1IRQ* =  
  volatileStore(timer1INTClr,0x1.uint32)
  
template timer1Fired* : bool = 
   (volatileLoad(timer1MIS) and 0x01) == 1  

template timer2Fired* : bool =
   (volatileLoad(timer1MIS) and 0x02) == 2  
  
proc pollTimer1* =
  var tval = 1.uint32
  while tval > 0:
   tval = volatileLoad(timer1Value)
   
  # initTimer1() 