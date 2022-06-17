clear_textmode_buffer:
    pushad

    mov cl, 0 ; cols
    mov ch, 0 ; rows

    .loop:

        mov dl, byte ' '
        mov dh, 0x0
        call vga_textmode_setchar

        inc cl
        cmp cl, 80
        jl .loop
        mov cl, 0

        inc ch
        cmp ch, 25
        jl .loop


    popad
    ret


vga_textmode_setchar: ;ch: row, cl: col, dx: char_data
    pushad
    mov ebx, 0xb8000
    mov al, 160
    mul ch
    mov si, ax ;si = 160 * ch(row)

    mov al, 2
    mul cl ; al = 2 * cl
    add si, ax ; si = si + (2 * cl)
    add ebx, esi

    ;example:
    ; mov dl, byte 'X'
    ; mov dh, byte 0x5
    mov [ebx], dx

    popad
    ret

vga_textmode_setstring:
    pushad


    .loop:
        mov dl, byte [ebx]

        call vga_textmode_setchar

        inc ebx

        inc cl
        cmp cl, 80
        jl .again
        mov cl, 0

        ; inc ch     ; This bit of code breaks the char placement for some reason, 
        ; cmp ch, 25 ; program(with this code segment uncommented) output: test{club_symbol}
        ; jl .loop_end

        .again:

        cmp [ebx], byte 0
        jne .loop

    .end:

    popad
    ret