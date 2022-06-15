[org 0x1000]
[bits 32]

main:
    call write_regs
    call disable_cursor

    mov ax, 10
    mov bx, 10
    mov cl, 0xff

    call draw_pixel

    mov eax, end_addr
    mov ebx, 0x80400000
    call kinit1
    ; mov [0xb8000], byte 'X'

jmp $

%include "kernel/kalloc.asm"
%include "kernel/panic.asm"
%include "kernel/spinlock.asm"
%include "kernel/string.asm"
%include "kernel/VGA/driver.asm"

times 20*256 dw 0xDADA

; Must be last line of kernel
end_addr equ $
