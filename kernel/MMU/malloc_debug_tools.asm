calculate_free_memory:
    mov rax, 0
    push rbx
    push rdx

    mov rbx, MEM_START
    mov rdx, 0

    .loop:
        add rbx, rdx
        cmp rbx, MEM_END
        jae .done
        mov dx, [rbx]
        ; call vga_log_rdx
        cmp [rbx+BLOCK_IN_USE_OFFSET], byte 0
        jne .loop
        add rax, rdx
        jmp .loop

    .done:
    cmp rax, 0x0F00
    call vga_log_rax
    jb panic

    pop rdx
    pop rbx
    ret

calculate_free_memory2:
    mov rax, 0
    push rbx
    push rdx

    mov rbx, MEM_START
    mov rdx, 0

    .loop:
        add rbx, rdx
        cmp rbx, MEM_END
        jae .done
        mov dx, [rbx]
        ; call vga_log_rdx
        cmp [rbx+BLOCK_IN_USE_OFFSET], byte 0
        jne .loop
        add rax, rdx
        jmp .loop

    .done:
    cmp rax, 0x0F00
    jb .panic

    pop rdx
    pop rbx
    ret

    .panic:
    call vga_log_rax
    mov [0xb8000], word 0x730
    jmp $

assert_valid_block: ; rax: ptr to block
    push rax
    push rbx
    push rdx
    mov rdx, 0
    mov rbx, MEM_START
    .loop:
        cmp rax, rbx
        je .done
        cmp rbx, MEM_END
        jae panic
        mov dx, [rbx]
        add rbx, rdx
        jmp .loop

    .done:
    pop rdx
    pop rbx
    pop rax
    ret

validate_memory:
    pushaq

    mov rax, MEM_START

    mov rbx, 0

    .loop:
        cmp [rax], word 0
        je panic

        mov bx, [rax]
        add rax, rbx
        cmp rax, MEM_END
        jb .loop

    popaq
    ret

validate_memory2:
    pushaq

    mov rax, MEM_START

    mov rbx, 0

    .loop:
        cmp [rax], word 0
        je .panic

        mov bx, [rax]
        add rax, rbx
        cmp rax, MEM_END
        jb .loop

    popaq
    ret

    .panic:
    mov [0xb8000], word 'Q' | 0x700
    jmp $

dump_mem_map:
    push rax
    push rcx
    push rsi
    xor rcx, rcx
    mov cx, [0x8000]

    mov rsi, 0x8002

    .loop:
        jrcxz .done
        mov rax, [rsi]
        call vga_log_rax ; Start Pos
        add rax, [rsi+8]
        call vga_log_rax ; End Pos
        mov rax, [rsi+8]
        call vga_log_rax ; Length
        xor rax, rax
        mov eax, [rsi+16]
        call vga_log_rax ; Type
        mov eax, [rsi+20]
        call vga_log_rax ; Extended Attributes
        call vga_log_space
        add rsi, 32
        dec cx
        jmp .loop

    .done:

    pop rsi
    pop rcx
    pop rax
    ret
