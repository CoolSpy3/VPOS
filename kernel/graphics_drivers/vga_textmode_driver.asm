%ifndef KERNEL_VGA_TEXTMODE_DRIVER
%define KERNEL_VGA_TEXTMODE_DRIVER

[bits 64]

%include "common/system_constants.asm"
%include "kernel/util/stackmacros.asm"

clear_textmode_buffer:
    push ax
    push rcx
    push rdi

    mov rcx, SCREEN_NUM_COLS * SCREEN_NUM_ROWS

    mov al, byte ' ' ; Fill with spaces
    mov ah, 0x0

    mov rdi, VRAM_TEXT_START

    rep stosw

    pop rdi
    pop rcx
    pop ax
    ret


vga_textmode_setchar: ;ch: row, cl: col, dx: char_data
    pushaq
    mov rax, 0
    mov rsi, 0
    mov rbx, VRAM_TEXT_START
    mov al, SCREEN_NUM_COLS * 2 ; Each character is 2 bytes
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

vga_textmode_setstring: ; rbx: string, ch: row, cl: col, dx: char_data
    pushaq

    .loop:
        mov dl, byte [rbx] ; Get the next character in the string

        call vga_textmode_setchar ; Print the character

        inc rbx ; Move to the next character in the string

        inc cl ; Move to the next column
        cmp cl, SCREEN_NUM_COLS
        jl .again
        mov cl, 0 ; If we're at the end of the line, go to the next line

        inc ch ; This code was (maybe) being buggy before. I uncommented it, and it appears to work now, so ima assume the previous comment was wrong
        cmp ch, SCREEN_NUM_ROWS
        jl .end ; If we're at the end of the screen, stop

        .again:

        cmp [rbx], byte 0 ; If we're not at the end of the string, go back to the top of the loop
        jne .loop

    .end:

    popaq
    ret

vga_textmode_showhex: ; rax: val, cl: x, ch: y, dl: color
    pushaq

    push rcx

    mov rcx, 2*8+2-1 ; 2 chars per byte, 8 bytes, '0x', subtract 1 to target the last character

    .loop:
    call .readChar ; Put the lower 4 bits of rax into hex_string[rcx]
    shr rax, 4 ; Shift rax right 4 bits and shift rcx to the next character
    sub rcx, 1

    cmp rcx, 2 ; If we're at the beginning of the string, stop
    jae .loop

    pop rcx

    mov rbx, hex_string ; Print hex_string
    call vga_textmode_setstring

    popaq
    ret

    .readChar: ; al: val, rcx: offset into hex_string
        push ax
        and al, 0xF ; Get the lower 4 bits of al
        add al, '0' ; Convert to ASCII
        cmp al, 0xA+'0' ; If al is greater than 0xA, we need to convert it to a letter
        jb .readChar_put
        add al, 'A'-'0'-0xA ; Convert to ASCII letter
        .readChar_put:
        mov [hex_string+rcx], al ; Put the character into hex_string
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

%endif
