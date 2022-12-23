map_page: ; rax: linear address, rbx: virtual address, rcx: flags, rdx: 1 for 2 MiB page, 0 for 4 KiB page (other values result in undefined behavior)
    push rcx
    push rdx
    shl rdx, 7 ; Set the page size bit if needed
    or rcx, rdx
    or rcx, 1 ; Set the present bit
    pop rdx

    push r8
    push rsi

    push rax

    mov r8, cr3

    %macro allocateLevel 1 ; param: offset
        mov rax, rbx
        shr rax, %1
        and rax, 511
        lea rsi, [r8+rax*8]
        %if %1 = 21
            test rdx, rdx
            jnz .map_page
        %endif

        %if %1 != 12
            mov r8, [rsi]
            btr r8, 63 ; Clear the execute disable bit
            test r8, 1
            jz %%allocate

            and r8, ~4095 ; Clear flags
            jmp %%allocated

            %%allocate:
            call kalloc
            mov [rsi], rax
            mov r8, rax
            or [rsi], byte 7 ; Set present, read/write, and user bits

            %%allocated:
        %endif
    %endmacro

    allocateLevel 39 ; Allocate PML4E (PDPT)
    allocateLevel 30 ; Allocate PDPTE (PD)
    allocateLevel 21 ; Allocate PDE (PT)
    allocateLevel 12 ; Get PTE Address

    %unmacro allocateLevel 1

    .map_page:
    pop rax

    or rcx, rax
    mov [rsi], rcx

    .done:
    pop rsi
    pop r8

    pop rcx
    ret
