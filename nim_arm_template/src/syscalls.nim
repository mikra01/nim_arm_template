# retargeted syscalls (newlib-nano provides only empty stubs for most of these)
# contain board/platform dependent code (references some linkerscript variables/memory)
# all functions are marked with attribute:used because of the lto step
# https://www.embedded.com/embedding-with-gnu-newlib/
# https://www.embedded.com/embedding-gnu-newlib-part-2/


proc write( file : cint, data : cstring, size : cint) : cint {.exportc:"_write",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =
  # retarget newlib's write 
  # file: stdin = 0 / stdout = 1 / stderr = 2
  # let p = $data
  var dat = $data
  echo_uart0(dat,size)
  return size

proc newlibRaise( signum : cint ) : cint {.exportc:"raise",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =  
  ## doSoftwareIRQ(22)
  var t = "raise called"  
  echo_uart0(t,t.len)
  return 0

proc newlibExit(status : cint) {.exportc:"exit",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =
  var t = "_exit called " 
  var stat = $status 
  echo_uart0(t,t.len)  
  echo_uart0(stat,stat.len)
  resetBoard()

# proc nimMutexInit(x1 : pointer, x2 : pointer) : int {.exportc:"pthread_mutex_init",cdecl.} =
#  # empty stub. called by nim through locks module
#  discard

proc newlibIsatty(filedesc : cint) : cint {.exportc:"_isatty",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =
  var t = "_isatty called"  
  echo_uart0(t,t.len)  
  return 1.cint

{.emit: """ 
  #include <errno.h>
  #include <sys/stat.h>

  #undef errno
  extern int  errno;
  extern int _end; // start of free memory defined by linker script -> heap_start
                   // the global variable _stack is set by the runtime (todo: where?)
  extern int _stack;
  
  // typedef void (*sighandler_t)(int);
 
""".}  

# _sbrk_r, _fstat_r, _isatty_r, _close_r, _lseek_r, _write_r, _read_r

const maxStackSize : int = 0x800 
# 2K stack; todo: move2linkerdef

let einval {.importc:"EINVAL",nodecl.}:cint
let nomem {.importc:"ENOMEM",nodecl.}:cint

let initialFreememPtr {.importc:"_end", nodecl.}: cint
let initialStackPtr {.importc:"_stack", nodecl.} : cint
# TODO: evaluate linker symbol import 

var errno {.importc:"errno",nodecl.}: cint 
var heapPtr : cint = cast[cint](initialFreememPtr.unsafeAddr)
var stackPtr : cint = cast[cint](initialStackPtr.unsafeAddr)
# due to that global definition the functions are not reentrant; so only 
# monothreading possible

proc newlibSbrk( nbytes : cint ) : cint {.exportc:"_sbrk",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.}  =
  ## called when the heap needs to grow number of nbytes  

  if stackPtr - (heapPtr + nbytes) > maxStackSize:
    result = heapPtr
    heapPtr = heapPtr + nbytes
  else:
    errno = nomem 
    result = -1.cint

proc mallocLock( nbytes : cint ) : cint {.exportc:"__malloc_lock",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.}  =
  ## todo: implement for reentrant malloc
  discard

proc mallocUnlock( nbytes : cint ) : cint {.exportc:"__malloc_unlock",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.}  =
  ## todo: implement for reentrant malloc
  discard

proc envLock( nbytes : cint ) : cint {.exportc:"__env_lock",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.}  =
  ## todo: implement for reentrant variable pool
  discard

proc envUnlock( nbytes : cint ) : cint {.exportc:"__env_unlock",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.}  =
  ## todo: implement hook for reentrant variable pool
  discard

proc sysFork( nbytes : cint ) : cint {.exportc:"_fork",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.}  =
  ## todo: implement if system() or fork() called. todo: check posix spawn
  discard
  
proc newlibKill( pid : cint, sig : cint ):cint {.exportc:"_kill",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =  
  errno = einval
  # default_impl. we are in singlethreaded mode so that's fine for now
  # echo "kill called"
  var t = "kill called"  
  echo_uart0(t,t.len)  
  return -1.cint

proc newlibGetPid() : cint {.exportc:"_getpid",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =
  # default_impl. no multithreaded mode
  # echo "getpid called"
  var t = "getpid called"  
  echo_uart0(t,t.len)  
  return 1.cint

let EBADF {.importc:"EBADF",nodecl.} : cint
  
proc newlibClose( filedesc : cint) : cint {.exportc:"_close",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} = 
  errno = EBADF
  # echo "close called"
  var t = "close called"  
  echo_uart0(t,t.len)  
  return -1.cint # error - no filesys present 
  
proc newlibLseek( filedesc , offset, whence : cint) : int {.exportc:"_lseek",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =  
  # echo "seek called"
  var t = "seek called"  
  echo_uart0(t,t.len)  
  return 0 # stdout is always at begin

proc newlibRead(filedesc : cint, charptr : pointer, len : cint) : int {.exportc:"_read",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =
  # echo "read called"
  var t = "read called"  
  echo_uart0(t,t.len)  
  return  0 # always indicate EOF

let SIFCHR {.importc:"S_IFCHR",nodecl.} : int

proc newlibFStat( filedesc : cint, st : cint) : int {.exportc:"_fstat",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =
  var tp : ptr int = cast[ptr int](st+8) # fetch st_mode
  tp[] = SIFCHR # ugly hacky
  # echo "fstat called"
  var t = "_fstat called"  
  echo_uart0(t,t.len)  
  return 0 #char device

type Sighandler = proc (a: cint) {.noconv.}

proc newlibAbort() {.exportc:"abort",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =
  # todo: raise(SIGABRT)
  var t = "abort called"  
  echo_uart0(t,t.len)  

# read: https://www.codeinsideout.com/blog/stm32/free-rtos/reentrant/

type
 Tm {.importc: "struct tm", header: "<time.h>", final, pure.} = object
      tm_sec*: cint   ## Seconds [0,60].
      tm_min*: cint   ## Minutes [0,59].
      tm_hour*: cint  ## Hour [0,23].
      tm_mday*: cint  ## Day of month [1,31].
      tm_mon*: cint   ## Month of year [0,11].
      tm_year*: cint  ## Years since 1900.
      tm_wday*: cint  ## Day of week [0,6] (Sunday =0).
      tm_yday*: cint  ## Day of year [0,365].
      tm_isdst*: cint ## Daylight Savings flag.

# proc times*(tms: ptr Tms): Clock {.importc, header: "<sys/times.h>", discardable.}
proc newlibTimes( tms: ptr Tm) : int {.exportc:"_times",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =
  discard

proc newlibSignal( sigNum : cint , hdlr : Sighandler ) : cint {.exportc:"signal",codegenDecl: "$# __attribute__((used)) $#$#",cdecl.} =
  ## mandatory signals
  ## SIGABRT
  ##  Abnormal termination of a program; raised by the <<abort>> function.
  ## SIGFPE
  ##  A domain error in arithmetic, such as overflow, or division by zero.
  ## SIGILL
  ##  Attempt to execute as a function data that is not executable.
  ## SIGINT
  ## Interrupt; an interactive attention signal.
  ## SIGSEGV
  ## An attempt to access a memory location that is not available.
  ## SIGTERM    
  ## A request that your program end execution.
  # should return the previous handler
  var t = "newlibSignal called"
  var signo = $sigNum
  echo_uart0(t,t.len)  
  echo_uart0(signo,signo.len)    
  return cast[cint](hdlr) 