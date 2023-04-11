%ifndef KERNEL_PANIC
%define KERNEL_PANIC

[bits 64]

%include "kernel/graphics_drivers/vga_textmode_driver.asm"

panic:
    mov [0xb8000], word 'P' | 0x700
    jmp $

panic_with_msg: ; rbx: string
    mov cx, 0
    mov dh, 7
    call vga_textmode_setstring
    jmp $

%endif
