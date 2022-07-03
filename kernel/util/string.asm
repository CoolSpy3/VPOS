str_len: ; Put string addr in edi, length returned in eax
    push ecx
    mov al, 0
    mov ecx, -1
    cld
    repne scasb
    mov eax, -2
    sub eax, ecx
    pop ecx
    ret

substr: ; copies esi to a new string retuned in edi (ecx bytes starting from idx eax)
    push esi
    push eax
    push ecx

    add esi, eax
    mov eax, ecx
    add eax, 1
    call malloc
    mov edi, eax

    push edi
    cld
    rep movsb
    pop edi
    pop ecx

    push edi
    add edi, ecx
    mov [edi], byte 0
    pop edi

    pop eax
    pop esi
    ret

split_string: ; esi: string address, eax: returns pointer to arraylist, bl: split condition
    push bx
    push ecx
    push edx
    push esi
    push edi

    mov edx, esi ; current char position

    mov ecx, 0 ; length

    call arraylist_new ; eax pointer to arraylist

    .loop:

        cmp [edx], bl
        jne .loop_end

        .found:
        push eax
        mov eax, 0
        call substr
        pop eax

        push ebx
        mov ebx, edi
        call arraylist_add
        pop ebx

        inc edx
        mov esi, edx
        mov ecx, 0

        cmp [esi], byte 0
        je .done
        jmp .loop

        .loop_end:
        inc ecx
        inc edx
        cmp [edx], byte 0
        je .found
        jmp .loop

    .done:

    pop edi
    pop esi
    pop edx
    pop ecx
    pop bx
    ret

trim_string: ; eax: ptr to string, returns ptr to new string
    push esi
    push edi
    push ecx

    mov esi, eax
    mov edi, eax
    call str_len
    mov ecx, eax

    cmp [esi], byte ' '
    ja .skip_leading_loop

    .leading_loop:
        inc esi
        dec ecx
        cmp [esi], byte ' '
        jbe .leading_loop

    .skip_leading_loop:

    mov edi, esi
    add edi, ecx
    dec edi
    cmp [edi], byte ' '
    ja .skip_trailing_loop

    .trailing_loop:
        dec edi
        dec ecx
        cmp [edi], byte ' '
        jbe .trailing_loop

    .skip_trailing_loop:

    mov eax, 0
    call substr
    mov eax, edi

    pop ecx
    pop edi
    pop esi
    ret
