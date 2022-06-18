[org 0x1000]
[bits 32]

main:
    call kernel_main

jmp $

%include "MMU/kalloc.asm"
%include "kernel_main.asm"
%include "MMU/malloc.asm"
%include "panic.asm"
%include "spinlock.asm"
%include "MMU/memset.asm"
%include "HAL/idt.asm"
%include "graphics_drivers/vga_serial_driver.asm"
%include "graphics_drivers/vga_textmode_driver.asm"

MEM_START equ $
MEM_LEN equ 20*512-MEM_START ; bytes

initial_memory_header:
    dd MEM_LEN ; length (size of free memory)
    db 0 ; Unallocated
    dd 0 ; No previous block
    dd 0 ; No next block

times MEM_LEN-BLOCK_HEADER_LENGTH db 0x00

; End of memory
MEM_END equ $
