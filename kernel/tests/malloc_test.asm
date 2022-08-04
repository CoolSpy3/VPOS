malloc_test:
    mov rax, MEM_START
    mov cl, 0
    mov ch, 0
    ; mov rbx, rax
    mov dh, byte 0x5
    call vga_textmode_showhex

    mov rax, 11
    call malloc
    mov [rax], byte '*'
    mov [rax+1], byte '*'
    mov [rax+2], byte '*'
    mov [rax+3], byte '*'
    mov [rax+4], byte '*'
    mov [rax+5], byte '*'
    mov [rax+6], byte '*'
    mov [rax+7], byte '*'
    mov [rax+8], byte '*'
    mov [rax+9], byte '*'
    mov [rax+10], byte 0

    mov cl, 0
    mov ch, 1
    ; mov rbx, rax
    mov dh, byte 0x5
    call vga_textmode_showhex

    push rax
    mov rax, 12
    call malloc
    mov rbx, rax
    pop rax
    mov [rbx], byte '='
    mov [rbx+1], byte '='
    mov [rbx+2], byte '='
    mov [rbx+3], byte '='
    mov [rbx+4], byte '='
    mov [rbx+5], byte '='
    mov [rbx+6], byte '='
    mov [rbx+7], byte '='
    mov [rbx+8], byte '='
    mov [rbx+9], byte '='
    mov [rbx+9], byte 'D'
    mov [rbx+10], byte 0

    xchg rax, rbx
    mov cl, 0
    mov ch, 2
    ; mov rbx, rax
    mov dh, byte 0x5
    call vga_textmode_showhex
    xchg rax, rbx

    call free
    mov rax, 5
    call malloc
    mov [rax], byte '6'
    mov [rax+1], byte '9'
    mov [rax+2], byte '6'
    mov [rax+3], byte '9'
    mov [rax+4], byte 0

    mov cl, 0
    mov ch, 3
    ; mov rbx, rax
    mov dh, byte 0x5
    call vga_textmode_showhex

    ret
