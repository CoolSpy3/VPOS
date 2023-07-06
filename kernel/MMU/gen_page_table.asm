%ifndef KERNEL_MMU_GEN_PAGE_TABLE
%define KERNEL_MMU_GEN_PAGE_TABLE

%include "kernel/kernel.asm"

[bits 16]

%include "common/system_constants.asm"

gen_page_table: ; This must be run from protected mode to access higher memory
    mov edx, page_table+PAGE_TABLE_LENGTH ; Each page table entry will be allocated in the order we use them, so edx will always point to the next entry we will allocate
    mov edi, page_table                   ; edi will point to the current entry we are allocating

    movzx ebx, word [EXT_MEM_LEN] ; Get the length of extended memory in 1GiB blocks

    ; We will use esi as a backup variable so we can avoid the stack

    mov      esi, ebx
    add      ebx, 511                     ; Ensure at least 1 entry is mapped
    shr      ebx, 9                       ; Convert to number of 512GiB blocks (Number of PML4 entries)
    xor      ecx, ecx                     ; ecx will be used as a counter for the number of entries we have allocated
    or       edx, PTE_P | PTE_RW | PTE_US
    .l4loop:                              ; Allocate <ebx> PML4 entries
        mov [edi],   edx                  ; Store address of PDP table and flags in PML4 entry
        mov [edi+4], dword 0              ; Set upper 32 bits to 0 (We are not allocating page tables this high in memory) (This also clears the XD bit)
        add edi,     PAGE_TABLE_ENTRY_LEN ; Move to next PML4 entry
        add edx,     PAGE_TABLE_LENGTH    ; Move to next PDP table
        inc ecx
        cmp ecx,     ebx                  ; Check if we have allocated all the PML4 entries we need
        jne .l4loop

    cmp ebx, PAGE_TABLE_NUM_ENTRIES ; If we haven't used all 512 PML4 entries, we need to zero out the rest
    jae .skip_l4zloop

    .l4zloop: ; Zero out the rest of the PML4 entries
        mov [edi],   dword 0
        mov [edi+4], dword 0
        add edi,     PAGE_TABLE_ENTRY_LEN
        inc ecx
        cmp ecx,     PAGE_TABLE_NUM_ENTRIES
        jne .l4zloop

    .skip_l4zloop:

    mov ebx, esi ; Because the PDP tables are allocated in the same order as the PML4 entries, we can just map as many PDP entries as we have GiB of memory

    xor ecx, ecx
    .l3loop:
        mov [edi],   edx                  ; Store address of PD table and flags in PDP entry
        mov [edi+4], dword 0
        add edi,     PAGE_TABLE_ENTRY_LEN ; Move to next PDP entry
        add edx,     PAGE_TABLE_LENGTH    ; Move to next PD table
        inc ecx
        cmp ecx,     ebx
        jne .l3loop

    test ebx, PAGE_TABLE_NUM_ENTRIES-1 ; If we haven't used a multiple of 512 PDP entries, we need to zero out the rest in the table
    jz   .skip_l3zloop

    and ecx, PAGE_TABLE_NUM_ENTRIES-1 ; ecx % 512 to get the number of PDP entries remaining in the current table

    .l3zloop: ; Zero out the rest of the PDP entries in the current table
        mov [edi],   dword 0
        mov [edi+4], dword 0
        add edi,     PAGE_TABLE_ENTRY_LEN
        inc ecx
        cmp ecx,     PAGE_TABLE_NUM_ENTRIES
        jne .l3zloop

    .skip_l3zloop:

    shl ebx, 9 ; Convert to number of 2MiB blocks (Number of PD entries)

    xor ecx, ecx
    xor edx, edx ; edx now contains the index of the 2MiB page we want to allocate
    .l2loop:
        mov esi,     edx
        shl edx,     21                               ; We have to do this shifting because now, our addresses can exceed 32 bits
        or  edx,     PTE_P | PTE_RW | PTE_US | PTE_PS
        mov [edi],   edx                              ; Store address of 2MiB page and flags in PD entry
        mov edx,     esi                              ; Restore edx to the page index to write the upper 32 bits of the address
        shr edx,     32-21
        mov [edi+4], edx
        add edi,     PAGE_TABLE_ENTRY_LEN             ; Move to next PD entry
        mov edx,     esi                              ; Increment the page index
        inc edx
        inc ecx
        cmp ecx,     ebx
        jne .l2loop

    mov [FREE_MEM], edi ; Store the address of the free memory (memory after the page tables)

    ; To avoid stack usage, this file should be included inline, so no need to return

%endif
