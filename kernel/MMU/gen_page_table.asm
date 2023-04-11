%ifndef KERNEL_MMU_GEN_PAGE_TABLE
%define KERNEL_MMU_GEN_PAGE_TABLE

%include "kernel/kernel.asm"

[bits 16]

gen_page_table: ; This must be run from protected mode to access higher memory
    mov edx, page_table+4096
    mov edi, page_table

    movzx ebx, word [EXT_MEM_LEN]

    ; We will use esi as a backup variable so we can avoid the stack

    mov esi, ebx
    shr ebx, 9
    mov ecx, 1
    cmp ebx, 0
    cmove ebx, ecx
    xor ecx, ecx
    or edx, 7
    .l4loop:
        mov [edi], edx
        mov [edi+4], dword 0
        add edi, 8
        add edx, 4096
        inc ecx
        cmp ecx, ebx
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

    mov ebx, esi

    mov ecx, 0
    .l3loop:
        mov [edi], edx
        mov [edi+4], dword 0
        add edi, 8
        add edx, 4096
        inc ecx
        cmp ecx, ebx
        jne .l3loop

    cmp ebx, 512
    jae .skip_l3zloop

    .l3zloop:
        mov [edi], dword 0
        mov [edi+4], dword 0
        add edi, 8
        inc ecx
        cmp ecx, 512
        jne .l3zloop

    .skip_l3zloop:

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

    mov [FREE_MEM], edi

%endif
