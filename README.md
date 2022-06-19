# VPOS
An operating system designed (primarily for fun) with the end goal of creating an OS based around a derivative of the language [StackFlow](https://github.com/CoolSpy3/StackFlow).

## Memory Layout
For reference, the built live-image contains 21 sectors (512 byte segments) arranged as follows:

1st sector: boot_section (ending with word `0xaa55`)

(dynamic): kernel code (Note: due to the dynamic nature of kernel code, the following sections may not fall exactly on sector boundaries)

Next 2 sectors (1024 bytes): Reserved for the stack

Next 10 sectors (5120 bytes): Reserved for malloc (heap)

Remaining sectors: Padding
