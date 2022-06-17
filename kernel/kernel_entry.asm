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

    ; mov eax, MEM_START
    ; mov ebx, 0x80400000
    ; call kinit1

jmp $

%include "kernel/kalloc.asm"
%include "kernel/malloc.asm"
%include "kernel/panic.asm"
%include "kernel/spinlock.asm"
%include "kernel/string.asm"
%include "kernel/graphics_drivers/vga_textmode_driver.asm"

test_string db 'test123', 0

MEM_START equ $
MEM_LEN equ 20*512 ; bytes

initial_memory_header:
    dd MEM_LEN ; length (size of free memory)
    db 0 ; Unallocated
    dd 0 ; No previous block
    dd 0 ; No next block

times MEM_LEN-BLOCK_HEADER_LENGTH db 0x00

times 20*512 db 0x00

; End of memory
MEM_END equ $
