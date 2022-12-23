setup_kernel_memory:
    test qword [page_table+64], 1
    jnz .limit_exceded

    push rax

    mov rax, [page_table]
    bts rax, 63 ; Set the execute disable bit

    mov [page_table+256*8], rax

    pop rax
    ret

    .limit_exceded:
    mov rbx, .LIMIT_MSG
    call panic_with_msg

    .LIMIT_MSG: db "Over 512GiB of memory detected! This is not supported!", 0

expand_page_table:
    push rbx
    push rdx

    movzx rbx, word [0x8000]
    shl rbx, 5
    add rbx, 0x8002

    .find_end_addr_loop:
        cmp qword [rbx+8+32], 0
        jz .find_end_addr_loop_done
        add rbx, 32
        jmp .find_end_addr_loop

    .find_end_addr_loop_done:

    mov rbx, [rbx+8] ; rbx = max addr
    xor rdx, rdx

    .expand_loop:
        cmp rdx, rbx
        jb .expand_loop_done
        call .expand_to_include
        add rdx, 2*1024*1024
        jmp .expand_loop

    .expand_loop_done:

    pop rdx
    pop rbx
    ret

    .expand_to_include:
        push rax
        push rbx
        push rsi

        mov rax, rdx
        shr rax, 39
        lea rsi, [page_table+rax*8]
        mov rbx, [rsi]
        btr rbx, 63 ; Clear the execute disable bit
        test rbx, 1
        jz .allocate_pdpt

        and rbx, ~4095 ; Clear flags
        jmp .pdpt_allocated

        .allocate_pdpt:
        call kalloc
        mov [rsi], rax
        mov rbx, rax
        or [rsi], byte 7 ; Set present, read/write, and user bits

        .pdpt_allocated:

        mov rax, rdx
        shr rax, 30
        and rax, 511
        lea rsi, [rbx+rax*8]
        mov rbx, [rsi]
        btr rbx, 63 ; Clear the execute disable bit
        test rbx, 1
        jz .allocate_pd

        and rbx, ~4095 ; Clear flags
        jmp .pd_allocated

        .allocate_pd:
        call kalloc
        mov [rsi], rax
        mov rbx, rax
        or [rsi], byte 7 ; Set present, read/write, and user bits

        .pd_allocated:

        mov rax, rdx
        shr rax, 21
        and rax, 511
        lea rsi, [rbx+rax*8]
        mov rbx, [rsi]
        btr rbx, 63 ; Clear the execute disable bit
        test rbx, 1
        jnz .entry_mapped

        mov [rsi], rdx
        or [rsi], byte 0x87 ; Set present, read/write, user, and page size bits

        .entry_mapped:

        pop rsi
        pop rbx
        pop rax
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
    movzx rcx, word [rsi-2]
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

            cmp [rdx], rax
            split_block rax

            cmp rbx, [rdx+8]
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
                lea rdi, [rdx+32]

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
        lea rdi, [rsi+32]
        add rsi, 64

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
