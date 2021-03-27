import ospaths, strutils

# run with 
# nim build_lpc2148 project.nims
task build_lpc2148, " compile and link for lpc2148 ":
  echo "current directory is: " & thisDir()
  
  withDir thisDir() & "/src":
    echo "asm Startup.S"
    exec "arm-none-eabi-gcc -c -mcpu=arm7tdmi-s -x assembler-with-cpp -DROM_RUN -Wa,-adhlns=Startup.lst,-gdwarf-2 Startup.S -o Startup.o"
    echo "compile and link project"
    exec "nim c --cpu:arm --os:any --gc:arc --d:useMalloc --nimcache:nimcache main.nim"
    echo "generate motorola srecord output format"
    exec "arm-none-eabi-objcopy.exe -O srec -S main.elf main.srec"
  
  if not dirExists("out"):
    mkDir("out")

  var outfiles = @["main.elf","main.srec","Startup.o","Startup.lst"]

  for file2move in outfiles:
    mvFile("src/" & file2move,"out/" & file2move)
 