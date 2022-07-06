split_string_test:
    mov esi, test_split
    mov bl, byte '.'
    call split_string
    mov ebx, 0
    call arraylist_get
    mov cx, 0x000
    mov dh, 5
    call vga_textmode_setstring
    mov ebx, 1
    call arraylist_get
    mov cx, 0x100
    mov dh, 5
    call vga_textmode_setstring
    mov ebx, 2
    call arraylist_get
    mov cx, 0x200
    mov dh, 5
    call vga_textmode_setstring
    mov ebx, 3
    call arraylist_get
    mov cx, 0x300
    mov dh, 5
    call vga_textmode_setstring
    ret


test_split db 'a.bb.ccc.dddd', 0
