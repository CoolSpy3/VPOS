panic:
    mov [0xb8000], word 'P' | 0x700
    jmp $

panic_with_msg:
    mov cx, 0
    mov dh, 7
    call vga_textmode_setstring
    jmp $
