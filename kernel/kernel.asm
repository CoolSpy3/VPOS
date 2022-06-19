[org 0x1000]
[bits 32]

main:
    mov esp, STACK_END
    call kernel_main

jmp $

%include "kernel_main.asm"
%include "panic.asm"
%include "spinlock.asm"
%include "HAL/idt.asm"
%include "MMU/kalloc.asm"
%include "MMU/malloc.asm"
%include "MMU/memset.asm"
%include "graphics_drivers/vga_serial_driver.asm"
%include "graphics_drivers/vga_textmode_driver.asm"

%include "MMU/stack.asm"
%include "MMU/ram.asm"

%include "MMU/padding.asm"
