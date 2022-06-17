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
%include "kernel/malloc.asm"
%include "kernel/panic.asm"
%include "kernel/spinlock.asm"
%include "kernel/string.asm"
%include "kernel/graphics_drivers/vga_textmode_driver.asm"

MEM_START equ $
MEM_LEN equ 20*512 ; bytes

initial_memory_header:
    dd MEM_LEN ; length (size of free memory)
    db 0 ; Not in use
    dd 0 ; No previous block
    dd 0 ; No next block

times MEM_LEN-BLOCK_HEADER_LENGTH db 0x00

; Must be last line of kernel
end_addr equ $
