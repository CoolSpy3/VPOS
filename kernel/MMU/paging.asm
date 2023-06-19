%ifndef KERNEL_MMU_PAGING
%define KERNEL_MMU_PAGING

[bits 64]

%include "kernel/MMU/kalloc.asm"

map_region: ; rax: start address, rbx: virtual address, rcx: flags, rdx: length, EFlags.CF: error
    test rax, 4096-1 ; All addresses must be on a 4 KiB boundary
    jnz .error
    test rbx, 4096-1
    jnz .error
    test rdx, 4096-1
    jnz .error

    push rax
    push rbx
    push rdx
    push r8
    push r9

    lea rdx, [rax+rdx] ; rdx = end address

    test rax, 2*1024*1024-1 ; If any addresses are not on a 2 MiB boundary, we need to use 4 KiB pages
    jnz .small_pages
    test rbx, 2*1024*1024-1
    jnz .small_pages
    test rdx, 2*1024*1024-1
    jnz .small_pages

    .large_pages:
    mov r8, 2*1024*1024 ; r8 = 2 MiB
    mov r9, 1 ; r9 = 1 (for 2 MiB pages)
    jmp .map

    .small_pages:
    mov r8, 4096 ; r8 = 4 KiB
    xor r9, r9 ; r9 = 0 (for 4 KiB pages)

    .map:
    xchg rdx, r9 ; rdx = 2 MiB/4 KiB flag, r9 = end address

    .loop:
        call map_page ; Map 2 MiB/4 KiB bytes at rbx to rax with flags rcx
        jc .error ; If an error occurred, return
        add rax, r8 ; Increment linear address by 2 MiB/4 KiB
        add rbx, r8 ; Increment virtual address by 2 MiB/4 KiB
        cmp rax, r9 ; Compare linear address to end address
        jb .loop ; If linear address is less than end address, map more memory

    pop r9
    pop r8
    pop rdx
    pop rbx
    pop rax
    clc
    ret

    .error:
        stc
        ret

map_page: ; rax: linear address, rbx: virtual address, rcx: flags, rdx: 1 for 2 MiB page, 0 for 4 KiB page (other values result in undefined behavior), EFlags.CF: error
    test rax, 4096-1 ; All addresses must be on a 4 KiB boundary
    jnz .error
    test rbx, 4096-1
    jnz .error

    push rcx
    push rdx
    shl rdx, 7 ; Set the page size bit if needed
    or rcx, rdx
    or rcx, 1 ; Set the present bit
    pop rdx

    ; rcx now contains the flags

    push r8
    push rsi

    push rax

    mov r8, cr3 ; Get PML4E Address

    %define PML4E 39
    %define PDPTE 30
    %define PDE 21
    %define PTE 12

    %macro allocate 1 ; param: offset
        mov rax, rbx
        shr rax, %1
        and rax, 511 ; rax = offset into table
        lea rsi, [r8+rax*8] ; rsi = address of entry
        %if %1 = PDE
            test rdx, rdx ; If allocating a PDE, check to see if we should write a 2 MiB page
            jnz .map_page ; If so, skip the allocation of a PTE
        %endif

        %if %1 != PTE ; If we already have a PTE, we don't need to allocate anything
            mov r8, [rsi] ; r8 = entry
            btr r8, 63 ; Ignore the execute/disable bit (we only need the address)
            test r8, 1 ; Check if the entry is present
            jz %%allocate ; If not, allocate a new page

            and r8, ~4095 ; Otherwise, ignore any flags and write the entry
            jmp %%allocated

            %%allocate:
            call kalloc ; Allocate a new page table (rax = address)
            mov [rsi], rax ; Write the address of the new page table to the entry
            mov r8, rax ; r8 = address of new page table (for the next iteration)
            or [rsi], byte 7 ; Set present, read/write, and user bits

            %%allocated:
        %endif
    %endmacro

    allocate {PML4E} ; Allocate PML4E (PDPT)
    allocate {PDPTE} ; Allocate PDPTE (PD)
    allocate {PDE} ; Allocate PDE (PT)
    allocate {PTE} ; Get PTE Address

    %unmacro allocate 1

    %undef PML4E
    %undef PDPTE
    %undef PDE
    %undef PTE

    .map_page:
    pop rax ; rax = linear address

    or rcx, rax ; rcx = linear address + flags
    mov [rsi], rcx ; Write the entry

    .done:
    pop rsi
    pop r8

    pop rcx
    clc
    ret

    .error:
        stc
        ret

%endif
