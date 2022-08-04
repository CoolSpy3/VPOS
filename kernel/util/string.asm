str_len: ; Put string addr in rdi, length returned in rax
    push rdi
    push rcx
    mov al, 0
    mov rcx, -1
    cld
    repne scasb
    mov rax, -2
    sub rax, rcx
    pop rcx
    pop rdi
    ret

substr: ; copies rsi to a new string retuned in rdi (rcx bytes starting from idx rax)
    push rsi
    push rax
    push rcx

    add rsi, rax
    mov rax, rcx
    add rax, 1
    call malloc
    mov rdi, rax

    push rdi
    cld
    rep movsb
    pop rdi
    pop rcx

    push rdi
    add rdi, rcx
    mov [edi], byte 0
    pop rdi

    pop rax
    pop rsi
    ret

split_string: ; rsi: string address, rax: returns pointer to arraylist, bl: split condition
    push bx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rdx, rsi ; current char position

    mov rcx, 0 ; length

    call arraylist_new ; rax pointer to arraylist

    .loop:

        cmp [rdx], bl
        jne .loop_end

        .found:
        push rax
        mov rax, 0
        call substr
        pop rax

        push rbx
        mov rbx, rdi
        call arraylist_add
        pop rbx

        inc rdx
        mov rsi, rdx
        mov rcx, 0

        cmp [esi], byte 0
        je .done
        jmp .loop

        .loop_end:
        inc rcx
        inc rdx
        cmp [rdx], byte 0
        je .found
        jmp .loop

    .done:

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop bx
    ret

trim_string: ; rax: ptr to string, returns ptr to new string
    push rsi
    push rdi
    push rcx

    mov rsi, rax
    mov rdi, rax
    call str_len
    mov rcx, rax

    cmp [esi], byte 0
    je .skip_trailing_loop

    cmp [esi], byte ' '
    ja .skip_leading_loop

    .leading_loop:
        inc rsi
        dec rcx
        cmp [esi], byte 0
        je .skip_leading_loop
        cmp [esi], byte ' '
        jbe .leading_loop

    .skip_leading_loop:

    cmp [esi], byte 0
    je .skip_trailing_loop

    mov rdi, rsi
    add rdi, rcx
    dec rdi
    cmp [edi], byte ' '
    ja .skip_trailing_loop

    .trailing_loop:
        dec rdi
        dec rcx
        cmp [edi], byte ' '
        jbe .trailing_loop

    .skip_trailing_loop:

    ; call calculate_free_memory
    ; call vga_log_rax
    mov rax, 0
    call substr
    mov rax, rdi

    pop rcx
    pop rdi
    pop rsi
    ret
