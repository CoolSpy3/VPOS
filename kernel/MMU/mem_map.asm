%ifndef KERNEL_MMU_MEM_MAP
%define KERNEL_MMU_MEM_MAP

[bits 16]

%include "common/rm_print.asm"

; Based on https://wiki.osdev.org/Detecting_Memory_(x86)#Getting_an_E820_Memory_Map
load_mem_map:
    push es
    push bp

    xor bp, bp ; We will use bp to count the number of entries

    mov ax, 0x800 ; Store the memory map at 0x8000
    mov es, ax
    mov di, 2 ; Save 2 bytes for the size of the memory map

    clc ; Clear carry (error) flag

    mov eax, 0xe820
    xor ebx, ebx
    mov ecx, 32
    mov edx, SMAP

    int 0x15

    jc .error ; If any of these fail, the function is not supported or doesn't return useful data
    cmp eax, SMAP
    jne .error
    test ebx, ebx
    je .error

    jecxz .empty_entry1

    mov eax, dword [es:di+8]
    or eax, dword [es:di+16]
    test eax, eax
    je .empty_entry1

    cmp ecx, 32
    jae .ext1
    mov [es:di+20], dword 1 ; No extended flags loaded, so set the extended flags to 1 (Entry exists)
    .ext1:

    inc bp

    .empty_entry1:

    .loop:
        test ebx, ebx
        je .done

        add di, 32

        mov eax, 0xe820
        mov ecx, 32
        mov edx, SMAP

        int 0x15

        jc .done

        mov eax, dword [es:di+8]
        or eax, dword [es:di+16]
        test eax, eax
        je .loop

        cmp ecx, 32
        jae .ext
        mov [es:di+20], dword 1 ; No extended flags loaded, so set the extended flags to 1 (Entry exists)
        .ext:

        inc bp

        jmp .loop

    .done:

    xor di, di
    mov [es:di], bp ; Save the number of entries in the memory map

    clc

    pop bp
    pop es
    ret

    .error:
    mov si, MEM_MAP_ERROR_MSG
    call rm_print
    jmp $

SMAP equ 0x0534D4150 ; SMAP signature
MEM_MAP_ERROR_MSG db "Failed to read memory map!", 0

%endif
