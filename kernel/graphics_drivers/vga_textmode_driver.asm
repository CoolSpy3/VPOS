clear_textmode_buffer:
    pushaq

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

    popaq
    ret


vga_textmode_setchar: ;ch: row, cl: col, dx: char_data
    pushaq
    mov rax, 0
    mov rsi, 0
    mov rbx, 0xb8000
    mov al, 160
    mul ch
    mov si, ax ;si = 160 * ch(row)

    mov al, 2
    mul cl ; al = 2 * cl
    add si, ax ; si = si + (2 * cl)
    add rbx, rsi

    ;example:
    ; mov dl, byte 'X'
    ; mov dh, byte 0x5
    mov [rbx], dx

    popaq
    ret

vga_textmode_setstring:
    pushaq

    .loop:
        mov dl, byte [rbx]

        call vga_textmode_setchar

        inc rbx

        inc cl
        cmp cl, 80
        jl .again
        mov cl, 0

        ; inc ch     ; This bit of code breaks the char placement for some reason, 
        ; cmp ch, 25 ; program(with this code segment uncommented) output: test{club_symbol}
        ; jl .loop_end

        .again:

        cmp [rbx], byte 0
        jne .loop

    .end:

    popaq
    ret

vga_textmode_showhex: ; rax: val, cl: x, ch: y, dl: color
    pushaq

    push rcx

    mov rcx, 2*8+1

    .loop:
    call .readChar
    shr rax, 4
    sub rcx, 1

    cmp rcx, 2
    jae .loop

    pop rcx

    mov rbx, hex_string
    call vga_textmode_setstring

    popaq
    ret

    .readChar:
    push ax
    and al, 0xF

    cmp al, 0xA
    jae .readChar2
    add al, '0'
    jmp .readChar_put

    .readChar2:
    add al, 'A'-0xA

    .readChar_put:
    mov [hex_string+rcx], al
    pop ax
    ret

vga_textmode_showraxandhang:
    mov cl, 0
    mov ch, 0
    mov dh, byte 0x5
    call vga_textmode_showhex
    jmp $

vga_textmode_showalascharandhang:
    mov cl, 0
    mov ch, 0
    mov dh, byte 0x5
    mov dl, al
    call vga_textmode_setchar
    jmp $

hex_string:
    db '0x'
    times 8*2+1 db 0
