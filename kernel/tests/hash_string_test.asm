hash_string_test:
    mov eax, test_string2
    call hash_string
    mov eax, ebx
    mov cl, 0
    mov ch, 4
    mov dh, byte 0x5
    call vga_textmode_showhex
    ret


test_string2 db 'Password', 0
