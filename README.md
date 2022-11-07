# VPOS
An operating system designed (primarily for fun) with the end goal of creating an OS from scratch. We hope to eventually implement advanced features such as native shared library linking support, a gui interface, etc. with minimal support from existing tutorials, so we can arrive at our own solutions and, hopefully, learn a lot about the methodology and issues which arise through this development.

At the moment, we are busy with other things in life, so changes will be slow to non-existant for now. Expect more rapid development to return in Summer 2023.

## Memory Layout
We are working on migrating the built live-image file to be a functional FAT-32 partition. At the moment, is arranged as follows:

1st sector (loaded to `0x7C00`): boot_section (Contains some FAT-32 metadata; ends with word `0xaa55`)

2nd sector: FS_INFO sector (More FAT-32 metadata)

(dynamic) (loaded to `0x1000`): kernel code (Note: due to the dynamic nature of kernel code, the following sections may not fall exactly on sector boundaries)

Next 2 sectors (1024 bytes): Reserved for the stack

Next 10 sectors (5120 bytes): Reserved for malloc (heap)

After this, any remaining space in the sector is padded with `0x00`

Memory Map (Will be loaded from BIOS into `0x8000`)

Page Tables (Will be generated at `0x100000`)

## Boot Process
At the moment, the process for booting the OS is as follows:

1. Begin Program
2. Jump over FAT_32 metadata
3. Setup a small stack (`ss = 0x07e0` `sp = 0x1200`)
4. Load the kernel from disk (to `0x1000`)
5. Enable A20 line
6. Jump to kernel
7. Make sure CPU supports all required features
8. Load the memory map from BIOS (into `0x8000`)
9. Load GDT
10. Enable protected mode in cr0
11. Set all segment registers (besides CS) to the data segment
12. Update the 32-bit stack pointer to use the stack defined in the kernel
13. Enable Physical Address Extensions (PAE) in cr4
14. Generate page tables (starting at `0x100000`)
15. Store page table location in cr3
16. Enable long mode in EFER_MSR
17. Enable paging in cr0
18. Jump to 64-bit kernel code
19. Reset 64-bit stack pointer to the kernel stack
20. Jump to kernel_main
