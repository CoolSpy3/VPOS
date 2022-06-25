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


split_string: ;esi: string address, eax: returns pointer to arraylist, edi: split condition 
    push edx
    push ebx
    push ecx

    mov edx, 0 ; end index
    mov ebx, 0 ; start
    mov ecx, esi ; end address

    call arraylist_new ; eax pointer to arraylist

    .loop:

        cmp [ecx], edi
        jne .loop_end

        push eax
        mov eax, ebx
        call substr
        pop eax

        mov ebx, edi
        call arraylist_add
        mov ebx, edx ; mov start, end

        .loop_end:
        inc edx
        inc ecx
        cmp [ecx], byte 0
        jne .loop

    pop edx
    pop ebx
    pop ecx