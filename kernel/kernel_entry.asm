[org 0x1000]
[bits 32]

main:
    ; mov ch, 0 ; y
    ; mov cl, 1 ; x
    ; mov dl, byte 'U'=222
    ; mov dh, byte 0x5
    ; call vga_textmode_setchar

    call clear_textmode_buffer

    mov ch, 0
    mov cl, 0
    mov ebx, test_string
    mov dh, byte 0x5
    call vga_textmode_setstring

    

    ; mov eax, end_addr
    ; mov ebx, 0x80400000
    ; call kinit1

jmp $

%include "kernel/kalloc.asm"
%include "kernel/panic.asm"
%include "kernel/spinlock.asm"
%include "kernel/string.asm"
%include "kernel/graphics_drivers/vga_textmode_driver.asm"

test_string db 'test123', 0


times 20*512 db 0x00

; Must be last line of kernel
end_addr equ $
