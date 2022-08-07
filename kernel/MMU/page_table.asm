MEM_SIZE equ 64 ; GB (Max 512 gb)
; %define LARGE_PAGES ; Use large (1gb) pages

gen_page_table: ; We'll try to do this without the stack, so no guarantees on register clobbering
    mov ecx, page_table+4096
    mov edi, page_table

    ; We will use esi as a backup variable so we can avoid the stack

    mov edx, 0
    .l4loop:
        mov esi, ecx
        or ecx, 7
        mov [edi], ecx
        add edi, 4
        mov [edi], dword 0
        add edi, 4
        mov ecx, esi
        add ecx, 4096
        inc edx
        cmp edx, MEM_SIZE
        jne .l4loop

%if MEM_SIZE < 512
    mov edx, 0
    .l4zloop:
        mov [edi], dword 0
        add edi, 4
        mov [edi], dword 0
        add edi, 4
        inc edx
        cmp edx, 512-MEM_SIZE
        jne .l4zloop
%endif

%ifdef LARGE_PAGES
    mov ecx, 0
    mov edx, 0
    .l3loop:
        mov esi, ecx
        shl ecx, 30
        or ecx, 0x87
        mov [edi], ecx
        add edi, 4
        mov ecx, esi
        shr ecx, 32-30
        mov [edi], ecx
        add edi, 4
        mov ecx, esi
        inc ecx
        inc edx
        cmp edx, 512*MEM_SIZE
        jne .l3loop
%else
    mov edx, 0
    .l3loop:
        mov esi, ecx
        or ecx, 7
        mov [edi], ecx
        add edi, 4
        mov [edi], dword 0
        add edi, 4
        mov ecx, esi
        add ecx, 4096
        inc edx
        cmp edx, 512*MEM_SIZE
        jne .l3loop

    mov ecx, 0
    mov edx, 0
    .l2loop:
        mov esi, ecx
        shl ecx, 21
        or ecx, 0x87
        mov [edi], ecx
        add edi, 4
        mov ecx, esi
        shr ecx, 32-21
        mov [edi], ecx
        add edi, 4
        mov ecx, esi
        inc ecx
        inc edx
        cmp edx, 512*512*MEM_SIZE
        jne .l2loop
%endif

    jmp cont_pm
