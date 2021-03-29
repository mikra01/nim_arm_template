import ospaths, strutils

# run with 
# nim build_lpc2148 project.nims
task build_lpc2148, " compile and link for lpc2148 ":
  echo "current directory is: " & thisDir()
  
  if not dirExists("out"):
    mkDir("out")
  
  withDir thisDir() & "/src":
    echo "asm Startup.S"
    exec "arm-none-eabi-gcc -c -mcpu=arm7tdmi-s -x assembler-with-cpp -DROM_RUN -Wa,-adhlns=Startup.lst,-gdwarf-2 Startup.S -o Startup.o"
    echo "compile and link project"
    exec "nim c --listFullPaths:on --genDeps:on --genScript:on --cpu:arm --os:any --gc:arc --d:useMalloc --nimcache:../out/nimcache main.nim"
    echo "generate motorola srecord output format"
    exec "arm-none-eabi-objcopy.exe -O srec -S main.elf main.srec"
  
  var outfiles = @["main.elf","main.srec","Startup.o","Startup.lst"]

  for file2move in outfiles:
    mvFile("src/" & file2move,"out/" & file2move)
 