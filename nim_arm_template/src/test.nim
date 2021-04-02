const uartAddr : ptr char = cast[ptr char](0x101f1000.int) #versatilepb uart0 addr
const pUnlockResetReg : ptr uint32 = cast[ptr uint32](0x10000020.uint32)
const pResetReg : ptr uint32 = cast[ptr uint32](0x10000040.uint32)

{.emit: """ 
__attribute__((used)) void _fini(void) {} // ensure linker happyness
                                          // exit() is never called
""".}

type
  TextException = object of CatchableError

proc resetBoard() {.exportc.} =
  # needed to exit qemu - referenced by startup.S
  pUnlockResetReg[] = 0xA05F.uint32
  pResetReg[] = 0x106.uint32

proc doDingDong() =
  # just throw an exception
  raise newException(TextException, "ding-dong")

iterator span(s: string; len: int, first: int, last: BackwardsIndex): char =
  for i in first..len - last.int: yield s[i]

proc echo_uart0( p1 : var string, len : int) =
  for c in p1.span(len,0,^1):
    uartAddr[] = c     
    # works only on qemu that way 
    # because uart-buffer's state is not checked

proc write( file : int, data : cstring, size : int) : int {.exportc:"_write",cdecl.} =
  # retarget newlib's write 
  # file: stdin = 0 / stdout = 1 / stderr = 2
  var p = $data
  echo_uart0(p,size)
  return size

proc kmain() {.exportc.} =
  echo " barebone example with Nim"
    
  var x = @[1, 2, 3, 4]
  
  for i in 0..x.len-1:
    echo $x[i]
 
  echo "before dingdong"

  try:
    doDingDong()
  except: 
    echo "caught " & getCurrentExceptionMsg()      
  finally:
    echo "finally block entered"

  echo ".. the end .."
