# nim_arm_template
a simple Nim template with the arm-none-eabi-gcc toolchain and qemu.
qemu's versatilepb machine emulation is used.
newlib's "_write" is retargeted so "echo" outputs to uart0.

run the example with "nim run_armdemo project.nims" 

### Dependencies
[GNU-ARM](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads)
and [QEMU](https://www.qemu.org/download/)

### Remarks
- example is not running on real hardware because of the simplified uart function
- tested with Nim compiler version 1.5.1 / GNU-ARM toolchain  9.2.1 20191025 (release) with windows10 host
- TODO: get the timertick running