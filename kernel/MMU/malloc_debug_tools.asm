

calculate_free_memory:
    mov eax, 0
    push ebx
    push edx

    mov ebx, MEM_START
    mov edx, 0

    .loop:
        add ebx, edx
        cmp ebx, MEM_END
        jae .done
        mov dx, [ebx]
        ; call vga_log_edx
        cmp [ebx+BLOCK_IN_USE_OFFSET], byte 0
        jne .loop
        add eax, edx
        jmp .loop

    .done:
    cmp eax, 0x0F00
    call vga_log_eax
    jb panic

    pop edx
    pop ebx
    ret

calculate_free_memory2:
    mov eax, 0
    push ebx
    push edx

    mov ebx, MEM_START
    mov edx, 0

    .loop:
        add ebx, edx
        cmp ebx, MEM_END
        jae .done
        mov dx, [ebx]
        ; call vga_log_edx
        cmp [ebx+BLOCK_IN_USE_OFFSET], byte 0
        jne .loop
        add eax, edx
        jmp .loop

    .done:
    cmp eax, 0x0F00
    jb .panic

    pop edx
    pop ebx
    ret

    .panic:
    call vga_log_eax
    mov [0xb8000], word 0x730
    jmp $

assert_valid_block: ; eax: ptr to block
    push eax
    push ebx
    push edx
    mov edx, 0
    mov ebx, MEM_START
    .loop:
        cmp eax, ebx
        je .done
        cmp ebx, MEM_END
        jae panic
        mov dx, [ebx]
        add ebx, edx
        jmp .loop

    .done:
    pop edx
    pop ebx
    pop eax
    ret

validate_memory:
    pushad

    mov eax, MEM_START

    mov ebx, 0

    .loop:
        cmp [eax], word 0
        je panic

        mov bx, [eax]
        add eax, ebx
        cmp eax, MEM_END
        jb .loop

    popad
    ret

validate_memory2:
    pushad

    mov eax, MEM_START

    mov ebx, 0

    .loop:
        cmp [eax], word 0
        je .panic

        mov bx, [eax]
        add eax, ebx
        cmp eax, MEM_END
        jb .loop

    popad
    ret

    .panic:
    mov [0xb8000], word 'Q' | 0x700
    jmp $
