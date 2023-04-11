[bits 64]

%include "kernel/util/hashmap.asm"
%include "kernel/graphics_drivers/vga_textmode_driver.asm"

hash_string_test:
    mov rax, test_string2
    call hash_string
    mov rax, rbx
    mov cl, 0
    mov ch, 4
    mov dh, byte 0x5
    call vga_textmode_showhex
    ret


test_string2 db 'Password', 0
