

clear_textmode_buffer:
    pushad

    mov cx, 0 ; cols
    mov dx, 0 ; rows

    vga_textmode_loop:

        inc dx
        cmp dx, vga_textmode_rows
        jl vga_textmode_loop

        inc cx
        cmp cx, vga_textmode_cols
        jl vga_textmode_loop

    popad
    ret


vga_textmode_setchar: ;dl: y, cl: x
    pushad
    mov ebx, 0xb8000
    mov al, 160
    mul dl
    mov dl, al ;dl = 160 * dl(row)


    mov al, 2
    mul cl ; al = 2 * cl
    add dl, al ; dl = dl + (2 * cl)

    ;ax = (ax * row) + colum

    add ebx, edx
    mov al, byte 'X'
    mov ah, byte 0xff
    mov [ebx], ax

    ;add bl, al
    ;mov [ebx], byte 'X'
    popad
    ret

vga_text_color db 0x0f
vga_textmode_ccol db 0
vga_textmode_crow db 0
vga_textmode_cols equ 158
vga_textmode_rows equ 25
vga_textmode_memory equ  0xb8000