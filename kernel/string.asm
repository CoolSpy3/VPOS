memset:
    push eax
    push ecx

    and eax, 3
    cmp eax, 0
    jne memset_stosb

    and ecx, 3
    cmp ecx, 0
    jne memset_stosb

    pop eax
    pop ecx

    and ebx, 0xff
    mov edx, ebx
    shl edx, 8
    or ebx, edx
    shl edx, 8
    or ebx, edx
    shl edx, 8
    or ebx, edx
    div ecx, 4

    mov edi, eax
    mov eax, ebx
    cld
    rep stosd 
    ret

memset_stosb:
    mov edi, eax
    mov eax, ebx
    cld
    rep stosb
    ret
