import ospaths, strutils

# run with 
# nim run_armdemo project.nims
task run_armdemo, " compile and link with arm-none-eabi-gcc toolchain and start qemu ":
  mkdir("out")
  exec "arm-none-eabi-as --keep-locals -march=armv5te -g src/startup.S -o out/startup.o"
  "out/startup.sym".writeFile(staticExec("arm-none-eabi-nm -n out/startup.o"))
 
  exec "nim c --cpu:arm --os:any --mm:arc -d:release -d:useMalloc -d:danger --threads:off --define:posix --listCmd --hint:cc --hint:link  --nimcache:out/nimcache src/test.nim"
  # exec "arm-none-eabi-strip out/test.elf"
  "out/section_hdr.txt".writeFile(staticExec("arm-none-eabi-readelf -S out/test.elf"))
  exec "arm-none-eabi-objcopy -O binary out/test.elf out/test.bin"
  "out/test.sym".writeFile(staticExec("arm-none-eabi-nm -n out/test.elf"))
  # dump symbol table
  "out/test.lss".writeFile(staticExec("arm-none-eabi-objdump -h -S -C out/test.elf")) 
  exec "qemu-system-arm -M versatilepb -m 128M -nographic -no-reboot -kernel out/test.bin"
  # use the versatilepb machine
  # "-no-reboot" ensures that we exit qemu on reset
  