# nim_arm_template
a simple Nim template with the arm-none-eabi-gcc toolchain and qemu.
qemu's versatilepb machine emulation is used.
newlib's "_write" is retargeted so "echo" outputs to uart0.

run the example with "nim run_armdemo project.nims" 

### Remarks
- example is not running on real hardware because of the simplified uart function
- TODO: get the timertick running