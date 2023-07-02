%ifndef KERNEL_MMU_INIT
%define KERNEL_MMU_INIT

[bits 64]

%include "common/system_constants.asm"
%include "kernel/kernel.asm"
%include "kernel/MMU/paging.asm"

setup_kernel_memory:
    test qword [page_table+64], 1 ; Check if the second entry in the PML4 is present
    jnz .limit_exceded

    push rax
    push rbx
    push rcx
    push rdx

    ; Map video memory
    mov rax, VRAM_START ; linear address = start of VRAM
    mov rbx, VRAM_START ; virtual address = start of VRAM (Identity Map)
    mov rcx, PTE_PCD | PTE_US | PTE_RW ; Set Page Level Cache Disable (changes take effect instantly), User, and Write bits
    mov rdx, VRAM_END-VRAM_START ; 128KB (Video Memory)
    call map_region
    jc .map_error

    mov rax, [page_table]
    bts rax, 63 ; Set the execute disable bit

    mov [page_table+256*8], rax ; Copy a map of all memory to the 257th entry (entry 256) in the PML4

    sfence ; Flush the TLB
    mov rax, cr3 ; Reload the page table
    mov cr3, rax

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

    .limit_exceded:
        mov rbx, .LIMIT_MSG
        jmp panic_with_msg

    .LIMIT_MSG db "Over 512GiB of memory detected! This is not supported!", 0

    .map_error:
        mov rbx, .MAP_ERROR_MSG
        jmp panic_with_msg

    .MAP_ERROR_MSG db "Failed to map memory (This is probrably a code error)!", 0

seq_alloc: ; Returns mem in rax
    push rcx
    push rdi

    xor rax, rax ; Fill with 0s
    mov rdi, [FREE_MEM] ; rdi = free memory pointer
    mov rcx, 512 ; rcx = number of qwords to allocate
    rep stosq ; 0mem
    mov [FREE_MEM], rdi ; Update free memory pointer

    mov rax, rdi ; Return the allocated memory in rax
    sub rax, 4096 ; Subtract 4096 from the pointer to get the start of the allocated memory

    pop rdi
    pop rcx
    ret

expand_page_table:
    push rax
    push rbx
    push rcx
    push rdx
    push r8
    clc

    movzx rbx, word [mem_map] ; Set rbx to the first entry of the formatted memory map
    shl rbx, MEM_MAP_BUF_SHIFT
    add rbx, mem_map + 4 ; 2 bytes for the count in the original map; 2 bytes for the count in the formatted map

    .find_end_addr_loop: ; Move rbx to the last entry in the formatted memory map
        cmp qword [rbx+FORMATTED_MEM_MAP_ENTRY_LEN+FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET], 0 ; Compare to the next entry in the map, so we don't end on the null entry
        jz .find_end_addr_loop_done
        add rbx, FORMATTED_MEM_MAP_ENTRY_LEN ; Move to the next entry
        jmp .find_end_addr_loop

    .find_end_addr_loop_done:

    mov r8, [rbx+FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET] ; r8 = max addr
    xor rax, rax ; rax = 0
    mov rcx, PTE_US | PTE_RW ; Set Supervisor, and Write bits
    mov rdx, 1 ; Use 2MiB pages

    .expand_loop:
        cmp rax, r8 ; While rax < max addr
        jae .expand_loop_done
        mov rbx, rax ; virtual address = linear address (Identity Map)
        call map_page ; Map 2 MiB of memory
        jc .error ; If there was an error, panic
        add rax, 2*1024*1024
        jmp .expand_loop

    .expand_loop_done:

    pop r8
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

    .error:
        mov rbx, .ERROR_MSG
        jmp panic_with_msg

    .ERROR_MSG db "Failed to map memory (This is probrably a code error)!", 0


%include "kernel/graphics_drivers/vga_logger.asm"

; 1. Calculate the bounds of all memory
; 2. For each region in the memory map, compare all intersecting regions in the existing map, and overwrite if necessary
; 3. Loop through all the regions and merge any that are contiguous
; This creates a NEW memory map AFTER the old one (starting at address mem_map+32*[mem_map])
; The first 2 bytes of the new map are the number of entries
; The map will terminate with a null entry that has an end address of 0 (not counted in the number of entries)
format_mem_map:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    movzx rcx, word [mem_map] ; Number of entries in the memory map
    mov rsi, mem_map+2 ; Start of the memory map
    mov rdi, rcx ; Start of the new memory map
    shl rdi, 5
    add rdi, rsi

    cmp rcx, 0
    jz panic ; There is no memory. How are we here?

    ; 1
        push rcx
        push rsi
        mov rax, [rsi+MEM_MAP_BASE_OFFSET] ; Start of memory
        mov rbx, rax ; End of memory
        add rbx, [rsi+MEM_MAP_LENGTH_OFFSET]
        add rsi, MEM_MAP_BUF_SIZE
        dec rcx
        .bounds_loop: ; Calculate max memory boundaries
            jrcxz .bounds_loop_end

            mov rdx, [rsi+MEM_MAP_BASE_OFFSET]
            cmp rax, rdx
            cmova rax, rdx
            add rdx, [rsi+MEM_MAP_LENGTH_OFFSET]
            cmp rbx, rdx
            cmovb rbx, rdx

            add rsi, MEM_MAP_BUF_SIZE
            dec rcx
            jmp .bounds_loop

        .bounds_loop_end:
        pop rsi
        pop rcx

        cmp rbx, 0
        jz panic ; There is no memory. How are we here?

    ; Create our new map
    mov word [rdi], 1 ; Number of entries
    add rdi, 2
    mov [rdi+FORMATTED_MEM_MAP_ENTRY_START_ADDR_OFFSET], rax ; Start address
    mov [rdi+FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET], rbx ; End address
    mov qword [rdi+FORMATTED_MEM_MAP_ENTRY_TYPE_OFFSET], 0 ; Type
    mov qword [rdi+FORMATTED_MEM_MAP_ENTRY_PADDING_OFFSET], 0 ; Padding
    mov qword [rdi+FORMATTED_MEM_MAP_ENTRY_LEN+FORMATTED_MEM_MAP_ENTRY_START_ADDR_OFFSET], 0 ; Ensure that the next entry is null
    mov qword [rdi+FORMATTED_MEM_MAP_ENTRY_LEN+FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET], 0 ; Ensure that the next entry is null
    mov qword [rdi+FORMATTED_MEM_MAP_ENTRY_LEN+FORMATTED_MEM_MAP_ENTRY_TYPE_OFFSET], 0 ; Ensure that the next entry is null
    mov qword [rdi+FORMATTED_MEM_MAP_ENTRY_LEN+FORMATTED_MEM_MAP_ENTRY_PADDING_OFFSET], 0 ; Ensure that the next entry is null

    ; 2
        push rcx
        push rsi
        push rbp
        .intersect_loop: ; For each region in the memory map
            jrcxz .intersect_loop_end ; If we are at the end of the map, exit

            mov rax, [rsi + MEM_MAP_BASE_OFFSET] ; rax = start of the new region
            mov rbx, rax ; rbx = end of the new region
            add rbx, [rsi + MEM_MAP_LENGTH_OFFSET]
            mov ebp, [rsi + MEM_MAP_TYPE_OFFSET] ; ebp = type of the new region

            mov rdx, rdi ; rdx = current region

            .intersect_entry_loop: ; Intersect the old region with a region in the new map. Note that the new region will be bounded by the current region in the new map
                cmp qword [rdx+FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET], 0 ; Check if we are at the end of the map
                jz .intersect_entry_loop_end

                cmp ebp, [rdx+FORMATTED_MEM_MAP_ENTRY_TYPE_OFFSET] ; Only try to intersect the regions if the new region has a higher priority type
                jna .intersect_entry_loop_continue

                cmp rax, [rdx+FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET] ; If the current region ends before the intersecting region, skip it
                jae .intersect_entry_loop_continue
                cmp rbx, [rdx+FORMATTED_MEM_MAP_ENTRY_START_ADDR_OFFSET] ; If the current region starts after the intersecting region, skip it
                jbe .intersect_entry_loop_continue

                ; The regions intersect

                cmp rax, [rdx+FORMATTED_MEM_MAP_ENTRY_START_ADDR_OFFSET] ; If the current region starts before the intersecting region, split it
                jbe .skip_start_split

                call .allocate_region

                mov [rdx+FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET], rax ; allocate_region copies the current region to the new region, so we only need to update the addresses
                add rdx, FORMATTED_MEM_MAP_ENTRY_LEN ; Set rdx to the new region
                mov [rdx+FORMATTED_MEM_MAP_ENTRY_START_ADDR_OFFSET], rax

                .skip_start_split: ; If we jump here, the regions start in the same place

                cmp rbx, [rdx+FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET] ; If the current region ends after the intersecting region, split it
                jae .skip_end_split

                call .allocate_region

                mov [rdx+FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET], rbx
                mov [rdx+FORMATTED_MEM_MAP_ENTRY_LEN+FORMATTED_MEM_MAP_ENTRY_START_ADDR_OFFSET], rbx ; allocate_region copies the current region to the new region, so we only need to update the addresses
                ; We want to use the lower region, so we don't need to update rdx

                .skip_end_split: ; If we jump here, the regions end in the same place, or the new region ends later

                ; Now that we've isolated the region, update its type
                mov [rdx+FORMATTED_MEM_MAP_ENTRY_TYPE_OFFSET], bp

                .intersect_entry_loop_continue:

                add rdx, FORMATTED_MEM_MAP_ENTRY_LEN

                jmp .intersect_entry_loop

            .intersect_entry_loop_end:

            add rsi, MEM_MAP_BUF_SIZE ; Move to the next region in the original map
            dec rcx ; Decrement the number of regions left in the original map
            jmp .intersect_loop

        .intersect_loop_end:
        pop rbp
        pop rsi
        pop rcx

    ; 3
        mov rsi, rdi ; rsi = start of the map
        .merge_loop:
            cmp qword [rsi+8+32], 0 ; If we are at the end of the map, exit
            jz .merge_loop_done

            mov rax, [rsi+16] ; rax = current region type
            cmp rax, [rsi+16+32] ; If the current region is not the same type as the next region, don't merge them
            jne .merge_loop_inc_and_continue

            dec word [rdi-2] ; There is one fewer entry because we are merging two of them

            mov rax, [rsi+8+32] ; Set the end address of the current region to the end address of the next region
            mov [rsi+8], rax

            push rsi ; Copy all of the regions after the next region backward one
            push rdi
            lea rdi, [rsi+32] ; rdi = start of the next region
            add rsi, 64 ; rsi = start of the region after the next region

            .merge_copy_loop:
                mov rcx, 4 ; Copy 4 qwords (one region)
                rep movsq
                cmp qword [rsi+8], 0 ; If we are at the end of the map, stop copying
                jne .merge_copy_loop

            mov qword [rdi], 0 ; Clear the final region in the map
            mov qword [rdi+8], 0
            mov qword [rdi+16], 0
            mov qword [rdi+24], 0

            pop rdi
            pop rsi

            .merge_loop_inc_and_continue:
            add rsi, 32 ; Point rsi to the next region and loop
            jmp .merge_loop

        .merge_loop_done:

    mov qword [rsi+32], 0 ; Clear the final region in the map
    mov qword [rsi+32+8], 0
    mov qword [rsi+32+16], 0
    mov qword [rsi+32+24], 0

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

    .allocate_region: ; rdx = current entry, rdi = map ; TODO: Rewrite this so that it copies the region in edx forward one, copying all other regions forward, also increment word [rdi-2]
        push rcx
        push rsi
        push rdi

        ; Number of entries to copy = number of entries in the map + 1 null entry - index of the current entry
        ; = num_entries + 1 - (current_entry - map) / sizeof(entry)
        ; bytes_to_copy = (num_entries + 1 - (current_entry - map) / sizeof(entry)) * sizeof(entry)
        ; = (num_entries + 1) * size - (current_entry - map)
        ; = (num_entries + 1) * size + map - current_entry
        movzx rcx, word [rdi-2] ; bytes_to_copy
        inc rcx
        shl rcx, FORMATTED_MEM_MAP_ENTRY_SHIFT
        add rcx, rdi
        sub rcx, rdx

        std ; Copy backwards so that we don't overwrite the current data
        movzx rsi, word [rdi-2]
        inc rsi ; Include the null entry
        shl rsi, FORMATTED_MEM_MAP_ENTRY_SHIFT ; Convert to bytes
        add rsi, rdi
        ; rsi now points to the qword directly following the last entry in the map
        dec rsi ; rsi now points to the last byte in the map
        mov rdi, rsi
        add rdi, FORMATTED_MEM_MAP_ENTRY_LEN ; Move evrything forward one entry
        rep movsb
        cld

        pop rdi
        pop rsi
        pop rcx

        inc word [rdi-2] ; There is now one more entry in the map

        ret



FORMATTED_MEM_MAP_ENTRY_LEN equ 32 ; Only 18 bytes are used, but aligning to 32 makes the code easier
FORMATTED_MEM_MAP_ENTRY_SHIFT equ 5 ; log2(FORMATTED_MEM_MAP_ENTRY_LEN)
FORMATTED_MEM_MAP_ENTRY_START_ADDR_OFFSET equ 0
FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET equ 8
FORMATTED_MEM_MAP_ENTRY_TYPE_OFFSET equ 16
FORMATTED_MEM_MAP_ENTRY_PADDING_OFFSET equ 24

%endif
