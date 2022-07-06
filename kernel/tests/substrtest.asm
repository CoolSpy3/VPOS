substrtest:
    mov esi, test_string
    mov eax, 2
    mov ecx, 5
    call substr

    mov ebx, edi
    mov cx, 0x700
    call vga_textmode_setstring
    ret


test_string db 'test12323', 0
