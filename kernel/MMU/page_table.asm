MEM_SIZE equ 64 ; GB (Max 512 gb)
; %define LARGE_PAGES ; Use large (1gb) pages

gen_page_table: ; This must be called from protected mode to access higher memory
    mov edx, page_table+4096
    mov edi, page_table

    ; We will use esi as a backup variable so we can avoid the stack

    mov ecx, 0
    or edx, 7
    .l4loop:
        mov [edi], edx
        mov [edi+4], dword 0
        add edi, 8
        add edx, 4096
        inc ecx
        cmp ecx, MEM_SIZE
        jne .l4loop

%if MEM_SIZE < 512
    .l4zloop:
        mov [edi], dword 0
        mov [edi+4], dword 0
        add edi, 8
        inc ecx
        cmp ecx, 512
        jne .l4zloop
%endif

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
        cmp ecx, 512*MEM_SIZE
        jne .l3loop
%else
    mov ecx, 0
    .l3loop:
        mov [edi], edx
        mov [edi+4], dword 0
        add edi, 8
        add edx, 4096
        inc ecx
        cmp ecx, 512*MEM_SIZE
        jne .l3loop

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
        cmp ecx, 512*512*MEM_SIZE
        jne .l2loop
%endif

    ret
