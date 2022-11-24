malloc_init:
    call format_mem_map

; #region Set Pointers

    push rax
    push rbx

    mov rax, [0x8000]
    and rax, 0xFFFF
    shl rax, 5
    add rax, 0x8002

    mov rbx, [rax]
    cmp qword rbx, 0x100000
    push rdx
    mov rdx, 0x100000
    cmovb rbx, rdx
    pop rdx

    mov [MEM_START], rbx
    mov [HEAP_PTR], rbx

    .loop:
        add rax, 32
        cmp qword [rax+8], 0
        jne .loop

    sub rax, 32

    .loop2:
        cmp qword [rax+16], 1
        je .loop2_done
        sub rax, 32
        jmp .loop2

    .loop2_done:

    mov rax, [rax+8]
    mov [MEM_END], rax
    sub rax, rbx
    mov [MEM_SIZE], rax

    pop rbx
    pop rax

; #endregion

; #region Initialize Memory Blocks
    push rax
    push rbx
    push rcx
    push rdx
    push rdi

    mov rax, [0x8000]
    and rax, 0xFFFF
    shl rax, 5
    add rax, 0x8002

    xor rdx, rdx
    xor rdi, rdi

    .loop3:
        cmp qword [rax+8], 0
        jz .loop3_done

        cmp qword [rax], 0x100000
        jb .loop3_continue

        cmp qword [rax+16], 1
        jne .loop3_continue

        mov rcx, rdi
        mov rdi, [rax]

        cmp rdx, 0
        jz .write_block

        mov rbx, rdi
        sub rbx, rdx

        mov [rdx], rbx
        mov rcx, [rcx]
        mov [rdx+8], rcx
        mov byte [rdx+16], 1

        mov rdx, rbx

        .write_block:
        mov rbx, [rax+8]
        sub rbx, rdi
        sub rbx, BLOCK_HEADER_LENGTH ; Leave space for a header of unallocated space

        mov [rdi], rbx
        mov [rdi+8], rdx
        mov byte [rdi+16], 0

        mov rdx, rbx
        add rdx, rdi ; rdx should contain the end address of the block (exclusive)

        .loop3_continue:
        add rax, 32
        jmp .loop3

    .loop3_done:

    add qword [rdi], BLOCK_HEADER_LENGTH ; We left space on the last free block for a header, but one is not needed

    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax

; #endregion

    ret

; 1. Calculate the bounds of all memory
; 2. For each region in the memory map, compare all intersecting regions in the existing map, and overwrite if necessary
; 3. Loop through all the regions and merge any that are contiguous
format_mem_map:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rsi, 0x8002 ; Set correct values for rsi, rdi, and rcx
    mov rcx, [rsi-2]
    and rcx, 0xFFFF
    push rcx
    mov rdi, 0x8002
    shl rcx, 5
    add rdi, rcx
    pop rcx

    cmp rcx, 0
    jz .done

    push rcx
    push rsi
    mov rax, [rsi]
    mov rbx, rax
    add rbx, [rsi+8]
    add rsi, 32
    dec rcx
    .bounds_loop: ; Calculate max memory boundaries
        jrcxz .bounds_loop_end

        mov rdx, [rsi]
        cmp rax, rdx
        cmova rax, rdx
        add rdx, [rsi+8]
        cmp rbx, rdx
        cmovb rbx, rdx

        add rsi, 32
        dec rcx
        jmp .bounds_loop

    .bounds_loop_end:
    pop rsi
    pop rcx

    cmp rbx, 0
    jz panic ; There is no memory. How are we here?

    ; Create our new map
    mov [rdi], rax ; Start address
    mov [rdi+8], rbx ; End address
    mov qword [rdi+16], 0 ; Type
    mov qword [rdi+24], 0 ; Padding

    push rcx
    push rsi
    .intersect_loop:
        cmp rcx, 0
        jz .intersect_loop_end

        mov rax, [rsi]
        mov rbx, rax
        add rbx, [rsi+8]

            %macro split_block 1
                jnb %%skip
                push rdi
                mov rdi, rdx
                add rdi, 32
                call .allocate_region
                push %1
                mov [rdi], %1
                mov %1, [rdx+8]
                mov [rdi+8], %1
                mov %1, [rdx+16]
                mov [rdi+16], %1
                mov %1, [rdx+24]
                mov [rdi+24], %1
                pop %1
                mov [rdx+8], %1
                pop rdi
                jmp .intersect_entry_loop
                %%skip:
            %endmacro

        .intersect_entry_loop:
            call .find_first_intersecting_region

            push rbx
            mov rbx, [rdx]
            cmp rbx, rax
            pop rbx
            split_block rax

            push rax
            mov rax, [rdx+8]
            cmp rbx, rax
            pop rax
            split_block rbx

            push rax
            push rbx
            mov rax, [rsi+16]
            mov rbx, [rdx+16]
            and rax, 0xFFFF
            and rbx, 0xFFFF
            cmp rax, rbx
            jbe .skip_intesect_entry_type_overwrite
            mov [rdx+16], rax
            .skip_intesect_entry_type_overwrite:
            pop rbx
            pop rax

            cmp rbx, [rdx+8]
            je .intersect_entry_loop_end

            mov rax, [rdx+8]

            jmp .intersect_entry_loop

            %unmacro split_block 1

            .allocate_region:
                push rcx
                push rdi

                mov rcx, 0
                .allocate_region_loop:
                    cmp qword [rdi+8], 0
                    jz .allocate_region_loop_end
                    add rcx, 4
                    add rdi, 32
                    jmp .allocate_region_loop

                .allocate_region_loop_end:

                push rsi

                mov rsi, rdx
                mov rdi, rdx
                add rdi, 32

                rep movsq

                pop rsi

                pop rdi
                pop rcx
                ret

        .intersect_entry_loop_end:

        add rsi, 32
        dec rcx
        jmp .intersect_loop

    .intersect_loop_end:
    pop rsi
    pop rcx

    mov rsi, rdi
    .merge_loop:
        cmp qword [rsi+8+32], 0
        jz .merge_loop_done
        mov rax, [rsi+16]
        cmp rax, [rsi+16+32]
        jne .merge_loop_inc_and_continue

        mov rax, [rsi+8+32]
        mov [rsi+8], rax

        push rsi
        add rsi, 32
        mov rdi, rsi
        add rsi, 32

        .merge_copy_loop:
            mov rcx, 4
            rep movsq
            cmp qword [rsi+8], 0
            jne .merge_copy_loop

        pop rsi

        .merge_loop_inc_and_continue:
        add rsi, 32
        jmp .merge_loop

    .merge_loop_done:

    mov qword [rsi+32], 0
    mov qword [rsi+32+8], 0
    mov qword [rsi+32+16], 0
    mov qword [rsi+32+24], 0

    .done:
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

    .find_first_intersecting_region: ; edi: Start of map, rax: requested address, rdx: returns region
        push rbx
        push rdi

        mov rdx, 0

        .find_first_intersecting_region_loop:
            cmp qword [rdi+8], 0
            jz .find_first_intersecting_region_loop_end

            mov rbx, [rdi]
            cmp rax, rbx
            jb .find_first_intersecting_region_loop_continue

            mov rbx, [rdi+8]
            cmp rax, rbx
            jae .find_first_intersecting_region_loop_continue

            mov rdx, rdi
            jmp .find_first_intersecting_region_loop_end

            .find_first_intersecting_region_loop_continue:
            add rdi, 32
            jmp .find_first_intersecting_region_loop

        .find_first_intersecting_region_loop_end:

        cmp rdx, 0
        je panic

        pop rdi
        pop rbx
        ret


MEM_START dq 0
MEM_LEN dq 0
MEM_END dq 0
