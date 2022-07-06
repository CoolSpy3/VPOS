get_file_descriptor: ; eax: ptr to filename, ebx: returns descriptor (null if not exists)
    push esi
    push edi
    push ecx

    mov edi, eax
    push eax
    call str_len
    mov ecx, eax
    pop eax

    mov esi, FS_START

    .loop:
        cmp [esi], dword 0
        je .not_found

        push esi
        push edi
        push ecx
        mov esi, [esi]
        add esi, FS_START
        cld
        repe cmpsb
        pop ecx
        pop edi
        pop esi
        je .found
        add esi, 8
        jmp .loop

    .found:
    mov ebx, [esi+4]
    add ebx, FS_START
    jmp .done

    .not_found:
    mov ebx, 0

    .done:

    pop ecx
    pop edi
    pop esi
    ret

read_file: ; ebx: file descriptor, returns ptr to data
    push eax
    push ecx
    push esi
    push edi
    mov eax, [ebx]
    mov ecx, eax
    call malloc
    mov ebx, eax
    mov edi, eax
    mov esi, [ebx+4]
    cld
    rep movsb
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
