[bits 64]

%include "kernel/graphics_drivers/vga_textmode_driver.asm"

set_char_test:
    mov ch, 0 ; y
    mov cl, 1 ; x
    mov dl, byte 'U'=222
    mov dh, byte 0x5
    call vga_textmode_setchar
    ret
