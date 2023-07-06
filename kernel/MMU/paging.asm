%ifndef KERNEL_MMU_PAGING
%define KERNEL_MMU_PAGING

[bits 64]

%include "kernel/MMU/kalloc.asm"

map_region: ; rax: start address, rbx: virtual address, rcx: flags, rdx: length, EFlags.CF: error
    test rax, 4096-1 ; All addresses must be on a 4 KiB boundary
    jnz  .error
    test rbx, 4096-1
    jnz  .error
    test rdx, 4096-1
    jnz  .error

    push rax
    push rbx
    push rdx
    push r8
    push r9

    lea rdx, [rax+rdx] ; rdx = end address

    test rax, 2*1024*1024-1 ; If any addresses are not on a 2 MiB boundary, we need to use 4 KiB pages
    jnz  .small_pages
    test rbx, 2*1024*1024-1
    jnz  .small_pages
    test rdx, 2*1024*1024-1
    jnz  .small_pages

    .large_pages:
    mov r8, 2*1024*1024 ; r8 = 2 MiB
    mov r9, 1           ; r9 = 1 (for 2 MiB pages)
    jmp .map

    .small_pages:
    mov r8, 4096 ; r8 = 4 KiB
    xor r9, r9   ; r9 = 0 (for 4 KiB pages)

    .map:
    xchg rdx, r9 ; rdx = 2 MiB/4 KiB flag, r9 = end address

    .loop:
        call map_page ; Map 2 MiB/4 KiB bytes at rbx to rax with flags rcx
        jc   .error   ; If an error occurred, return
        add  rax, r8  ; Increment linear address by 2 MiB/4 KiB
        add  rbx, r8  ; Increment virtual address by 2 MiB/4 KiB
        cmp  rax, r9  ; Compare linear address to end address
        jb   .loop    ; If linear address is less than end address, map more memory

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
    jnz  .error
    test rbx, 4096-1
    jnz  .error

    push rcx
    push rdx
    shl  rdx, 7     ; Set the page size bit if needed
    or   rcx, rdx
    or   rcx, PTE_P ; Set the present bit
    pop  rdx

    ; rcx now contains the flags

    push r8
    push rsi

    push rax

    mov r8, cr3 ; Get PML4 Address

    %define PML4E 39
    %define PDPTE 30
    %define PDE   21
    %define PTE   12

    %macro allocate 1 ; param: offset
        mov rax, rbx        ; rax = virtual address
        shr rax, %1
        and rax, 511        ; rax = offset into table
        lea rsi, [r8+rax*8] ; rsi = address of entry
        %if %1 = PDE
            test rdx, rdx   ; If allocating a PDE, check to see if we should write a 2 MiB page
            jz   %%alloc_PT ; If so, skip the allocation of a PTE

            test qword [rsi], PTE_P ; Check if the entry is present
            jz   .map_page          ; If the entry doesn't exist, we can just map the page

            test qword [rsi], PTE_PS ; Check if the entry is a 2 MiB page
            jnz  .map_page           ; If so, we can just map the page

            ; The entry points to another page table, we must deallocate it before we can allocate a 2 MiB page
            mov  rax, [rsi] ; rax = address of page table
            and  rax, ~4095 ; rax = address of page table (ignoring flags)
            btr  rax, 63    ; Ignore the execute/disable bit (we only need the address)
            call kfree      ; Deallocate the page table

            jmp .map_page ; Map the page

            %%alloc_PT:
        %endif

        %if %1 != PTE ; If we are allocating a PTE, we don't need to check if the entry is present
            mov  r8, [rsi]  ; r8 = entry
            btr  r8, 63     ; Ignore the execute/disable bit (we only need the address)
            test r8, PTE_P  ; Check if the entry is present
            jz   %%allocate ; If not, allocate a new page

            %if %1 = PDE
                test r8, PTE_PS ; Check if the entry is a 2 MiB page
                jnz  %%allocate ; If so, allocate a PT (If we needed a 2 MiB page, we would have set it up above)
                        ; TODO: In this case, we also need to add entries for all of the 4 KiB pages that make up this region
            %endif

            and r8, ~4095   ; Otherwise, ignore any flags and write the entry
            jmp %%allocated

            %%allocate:
            call kalloc ; Allocate a new page table (rax = address)

            push rbx ; Expand the old page directory entry to fill the new table
            push cx
            push rsi

            mov rbx, [rsi] ; rbx = old entry

            xor cx, cx ; cx = 0
            %%expand_entry_loop:
                mov [rax+rcx*8], rbx    ; Write the old entry to the new table
                add rbx,         4096   ; Increment the address
                inc cx                  ; Increment the index
                cmp cx,          512    ; Check if we have written all of the entries
                jb  %%expand_entry_loop ; If not, continue

            pop rsi
            pop cx
            pop rbx

            mov [rsi], rax                          ; Write the address of the new page table to the entry
            mov r8,    rax                          ; r8 = address of new table (for the next iteration)
            or  [rsi], byte PTE_US | PTE_RW | PTE_P

            %%allocated:
        %endif
    %endmacro

    allocate {PML4E} ; Allocate PML4E (PDPT)
    allocate {PDPTE} ; Allocate PDPTE (PD)
    allocate {PDE}   ; Allocate PDE (PT)
    allocate {PTE}   ; Get PTE Address

    %unmacro allocate 1

    %undef PML4E
    %undef PDPTE
    %undef PDE
    %undef PTE

    .map_page:
    pop rax ; rax = linear address

    or  rcx,   rax ; rcx = linear address + flags
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
