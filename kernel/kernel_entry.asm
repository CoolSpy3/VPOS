[org 0x1000]
[bits 32]

main:
    mov dl, 1 ; y
    mov cl, 0 ; x
    call vga_textmode_setchar

    ; mov eax, end_addr
    ; mov ebx, 0x80400000
    ; call kinit1

jmp $

%include "kernel/kalloc.asm"
%include "kernel/panic.asm"
%include "kernel/spinlock.asm"
%include "kernel/string.asm"
%include "kernel/graphics_drivers/vga_textmode_driver.asm"

times 20*512 db 0x00

; Must be last line of kernel
end_addr equ $
