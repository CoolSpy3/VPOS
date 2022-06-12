memset: ; Dest: edi, Val: eax, Cnt: ecx
    push ebx
    push edi
    push ecx

    and edi, 3
    cmp edi, 0
    jne memset_stosb

    and ecx, 3
    cmp ecx, 0
    jne memset_stosb

    pop edi
    pop ecx

    and eax, 0xff
    mov ebx, eax
    shl ebx, 8
    or eax, ebx
    shl ebx, 8
    or eax, ebx
    shl ebx, 8
    or eax, ebx
    shr ecx, 2

    cld
    rep stosd

memset_stosb:
    pop edi
    pop ecx
    cld
    rep stosb

memset_done:
    pop ebx
    ret
