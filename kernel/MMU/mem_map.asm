%ifndef KERNEL_MMU_MEM_MAP
%define KERNEL_MMU_MEM_MAP

%include "kernel/kernel.asm"

[bits 16]

%include "common/rm_print.asm"

%define MISC_SERVICES_INTERRUPT 0x15
%define GET_MEM_MAP_COMMAND 0xE820
%define MEM_MAP_BUF_SIZE 32
%define MEM_MAP_BUF_SHIFT 5 ; log2(MEM_MAP_BUF_SIZE)
%define MEM_MAP_EXT_FLAGS_OFFSET 20

; Based on https://wiki.osdev.org/Detecting_Memory_(x86)#Getting_an_E820_Memory_Map
load_mem_map:
    push es
    push bp

    xor bp, bp ; We will use bp to count the number of entries

    mov ax, mem_map / 0x10 ; Store the memory map at 0x8000 (divide by 16 to get the segment)
    mov es, ax ; Set the segment to 0x8000, so di is just an offset into the data structure
    mov di, 2 ; Save 2 bytes for the size of the memory map

    clc ; Clear carry (error) flag

    mov eax, GET_MEM_MAP_COMMAND
    xor ebx, ebx ; Zero ebx (the BIOS will provide this to us in future calls)
    mov ecx, MEM_MAP_BUF_SIZE
    mov edx, SMAP

    int MISC_SERVICES_INTERRUPT

    jc .error ; If any of these fail, the function is not supported or doesn't return useful data
    cmp eax, SMAP
    jne .error
    test ebx, ebx
    je .error

    ; I don't know why I added these empty checks.
    ; As far as I can tell (comming back to this code after a few months), 0xe820 will never return an empty entry.
    ; Additionally, the current implementation would not increment bp, but it would increment di, which would cause the last entry to not be read.
    ; jecxz .empty_entry1 ; If the size of the entry is 0, it is empty

    ; mov eax, dword [es:di+8]
    ; or eax, dword [es:di+16]
    ; test eax, eax
    ; je .empty_entry1

    cmp ecx, MEM_MAP_BUF_SIZE ; Check if the BIOS returned extended flags
    jae .ext1
    mov [es:di+MEM_MAP_EXT_FLAGS_OFFSET], dword 1 ; No extended flags loaded, so set the extended flags to 1 (Entry exists)
    .ext1:

    inc bp ; Increment the number of entries

    .empty_entry1:

    .loop:
        test ebx, ebx ; ebx = 0 when there are no more entries
        je .done

        add di, MEM_MAP_BUF_SIZE ; Move destination buffer to the next entry

        mov eax, GET_MEM_MAP_COMMAND ; Get the next entry from the memory map
        mov ecx, MEM_MAP_BUF_SIZE
        mov edx, SMAP

        int MISC_SERVICES_INTERRUPT

        jc .done ; Apparently, some BIOSs set CF=1 when there are no more entries (https://www.ctyme.com/intr/rb-1741.htm)

        ; This is another empty check
        ; mov eax, dword [es:di+8]
        ; or eax, dword [es:di+16]
        ; test eax, eax
        ; je .loop

        cmp ecx, MEM_MAP_BUF_SIZE ; Check if the BIOS returned extended flags
        jae .ext
        mov [es:di+MEM_MAP_EXT_FLAGS_OFFSET], dword 1 ; No extended flags loaded, so set the extended flags to 1 (Entry exists)
        .ext:

        inc bp ; Increment the number of entries

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
        call rm_dump_regs
        jmp $

MEM_MAP_ERROR_MSG db "Failed to read memory map!", 0

%endif
