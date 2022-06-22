kernel_main:

    call idt_install
    call pic_init

    ; mov ch, 0 ; y
    ; mov cl, 1 ; x
    ; mov dl, byte 'U'=222
    ; mov dh, byte 0x5
    ; call vga_textmode_setchar
    call clear_textmode_buffer

    mov eax, MEM_START
    mov cl, 0
    mov ch, 0
    ; mov ebx, eax
    mov dh, byte 0x5
    call vga_textmode_showhex

    mov eax, 11
    call malloc
    mov [eax], byte '*'
    mov [eax+1], byte '*'
    mov [eax+2], byte '*'
    mov [eax+3], byte '*'
    mov [eax+4], byte '*'
    mov [eax+5], byte '*'
    mov [eax+6], byte '*'
    mov [eax+7], byte '*'
    mov [eax+8], byte '*'
    mov [eax+9], byte '*'
    mov [eax+10], byte 0

    mov cl, 0
    mov ch, 1
    ; mov ebx, eax
    mov dh, byte 0x5
    call vga_textmode_showhex

    push eax
    mov eax, 12
    call malloc
    mov ebx, eax
    pop eax
    mov [ebx], byte '='
    mov [ebx+1], byte '='
    mov [ebx+2], byte '='
    mov [ebx+3], byte '='
    mov [ebx+4], byte '='
    mov [ebx+5], byte '='
    mov [ebx+6], byte '='
    mov [ebx+7], byte '='
    mov [ebx+8], byte '='
    mov [ebx+9], byte '='
    mov [ebx+9], byte 'D'
    mov [ebx+10], byte 0

    xchg eax, ebx
    mov cl, 0
    mov ch, 2
    ; mov ebx, eax
    mov dh, byte 0x5
    call vga_textmode_showhex
    xchg eax, ebx

    call free
    mov eax, 5
    call malloc
    mov [eax], byte '6'
    mov [eax+1], byte '9'
    mov [eax+2], byte '6'
    mov [eax+3], byte '9'
    mov [eax+4], byte 0

    mov cl, 0
    mov ch, 3
    ; mov ebx, eax
    mov dh, byte 0x5
    call vga_textmode_showhex

    mov eax, MEM_END
    mov cl, 0
    mov ch, 4
    ; mov ebx, eax
    mov dh, byte 0x5
    call vga_textmode_showhex

    ; call VGA_write_regs
    ; call disable_cursor
    ; call VGA_clear_screen

    ; mov bx, 10
    ; mov ax, 10
    ; mov cl, 1
    ; call draw_pixel

    ; mov bx, 0
    ; draw_lp_1:
    ; mov ax, bx
    ; add ax, 60
    ; mov cl, 1
    ; call draw_pixel
    ; mov ax, 260
    ; sub ax, bx
    ; mov cl, 2
    ; call draw_pixel
    ; inc bx
    ; cmp bx, DISPLAY_height
    ; jl draw_lp_1

    ret


; test_string db 'test123', 0
