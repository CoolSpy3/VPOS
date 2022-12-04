; %define LARGE_PAGES ; Use large (1gb) pages

gen_page_table: ; This must be called from protected mode to access higher memory
    mov edx, page_table+4096
    mov edi, page_table

    movzx ebx, word [EXT_MEM_LEN]

    ; We will use esi as a backup variable so we can avoid the stack

    xor cx, cx
    or edx, 7
    .l4loop:
        mov [edi], edx
        mov [edi+4], dword 0
        add edi, 8
        add edx, 4096
        inc cx
        cmp cx, [EXT_MEM_LEN]
        jne .l4loop

    cmp ebx, 512
    jae .skip_l4zloop

    .l4zloop:
        mov [edi], dword 0
        mov [edi+4], dword 0
        add edi, 8
        inc ecx
        cmp ecx, 512
        jne .l4zloop

    .skip_l4zloop:

    shl ebx, 9

%ifdef LARGE_PAGES
    mov ecx, 0
    mov edx, 0
    .l3loop:
        mov esi, edx
        shl edx, 30
        or edx, 0x87
        mov [edi], edx
        mov edx, esi
        shr edx, 32-30
        mov [edi+4], edx
        add edi, 8
        mov edx, esi
        inc edx
        inc ecx
        cmp ecx, ebx
        jne .l3loop
%else
    mov ecx, 0
    .l3loop:
        mov [edi], edx
        mov [edi+4], dword 0
        add edi, 8
        add edx, 4096
        inc ecx
        cmp ecx, ebx
        jne .l3loop

    shl ebx, 9

    mov ecx, 0
    mov edx, 0
    .l2loop:
        mov esi, edx
        shl edx, 21
        or edx, 0x87
        mov [edi], edx
        mov edx, esi
        shr edx, 32-21
        mov [edi+4], edx
        add edi, 8
        mov edx, esi
        inc edx
        inc ecx
        cmp ecx, ebx
        jne .l2loop
%endif
