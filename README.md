# nim_arm_template
a simple Nim template with the arm-none-eabi-gcc toolchain.

compile the project with "nim build_lpc2148 project.nims" 

### Remarks
don't expect that the outcome is running on the target - some symbols are still missing (memcpy for instance)