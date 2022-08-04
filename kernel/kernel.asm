[org 0x1000]
[bits 64]

%macro pushaq 0
push rax
push rbx
push rcx
push rdx
push rsi
push rdi
%endmacro

%macro popaq 0
pop rdi
pop rsi
pop rdx
pop rcx
pop rbx
pop rax
%endmacro

main:
    mov rsp, STACK_END
    call kernel_main

jmp $

%include "kernel_main.asm"
%include "HAL/idt.asm"
%include "HAL/pic.asm"
%include "MMU/malloc.asm"
%include "MMU/malloc_debug_tools.asm"
%include "graphics_drivers/vga_logger.asm"
%include "graphics_drivers/vga_serial_driver.asm"
%include "graphics_drivers/vga_textmode_driver.asm"
%include "util/arraylist.asm"
%include "util/hashmap.asm"
%include "util/panic.asm"
%include "util/string.asm"
%include "util/spinlock.asm"

%include "MMU/stack.asm"
%include "MMU/ram.asm"

%include "MMU/padding.asm"

FS_START equ $
