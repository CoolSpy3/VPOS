%ifndef KERNEL_MMU_KALLOC
%define KERNEL_MMU_KALLOC

[bits 64]

%include "kernel/kernel.asm"
%include "kernel/MMU/init.asm"

setup_kalloc:
    push rax
    push rbx
    push rcx
    mov  rax, (( (KERNEL_LEN + (4096 - 1) ) / 4096 ) + 1) * 4096 ; The +1 is to account for the first 4 KiB. We want to skip this to preserve the BDA.

    movzx rcx, word [mem_map]
    shl   rcx, 5
    mov   rbx, mem_map + 2
    lea   rbx, [rbx + rcx + 2] ; rbx = start of formatted mem map

    xor rcx, rcx
    not rcx      ; rcx = previous block = 0xFFFFFFFFFFFFFFFF (None)

    .loop:
        push rbx

        .find_relevant_mem_map_entry_loop:
            cmp qword [rbx+FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET], 0
            je  .loop_end                                                                                            ; No more entries; we're done
            cmp rax,                                                 [rbx+FORMATTED_MEM_MAP_ENTRY_START_ADDR_OFFSET]
            jb  .irrelevent_mem_map_entry
            cmp rax,                                                 [rbx+FORMATTED_MEM_MAP_ENTRY_END_ADDR_OFFSET]
            jae .irrelevent_mem_map_entry
            jmp .relevant_mem_map_entry

            .irrelevent_mem_map_entry:
                add rbx, FORMATTED_MEM_MAP_ENTRY_LEN
                jmp .find_relevant_mem_map_entry_loop

        .relevant_mem_map_entry:
        ; We now have the relevant mem map entry in rbx

        cmp qword [rbx+FORMATTED_MEM_MAP_ENTRY_TYPE_OFFSET], 1
        jne .skip_entry                                                    ; Not free memory; skip it
        cmp rax,                                             EXT_MEM_START
        je  .skip_allocated_memory                                         ; We have already allocated memory for page tables and other stuff (seq_alloc), so make sure to jump over anything we've allocated

        ; Add the block at rax to the free memory list
        mov [rax], rcx ; Set the next pointer to the previous block
        mov rcx,   rax ; Set the previous block to the current block

        .skip_entry:
        add rax, 4096 ; Move to the next 4 KiB block

        .loop_continue:
        pop rbx   ; Restore rbx to the start of the formatted mem map
        jmp .loop

        .skip_allocated_memory:
            mov rax, [FREE_MEM]

            add rax, 4095  ; Align rax to the next 4 KiB boundary (this shouldn't be necessary, but it's here just in case)
            and rax, ~4095

            jmp .loop_continue

    .loop_end:
    pop rbx

    mov [FREE_MEM],             rcx ; Set the head of the free memory list to the last block we found
    mov byte [IS_KALLOC_SETUP], 1   ; Set the flag to indicate that kalloc is set up

    pop rcx
    pop rbx
    pop rax
    ret

kalloc: ; Allocates rcx sectors and returns the pointer in rax
    cmp byte [IS_KALLOC_SETUP], 0
    je  seq_alloc                 ; kalloc is not set up yet; use seq_alloc instead

    push rcx
    push rdi

    xor       rax,        rax                ; Fill with 0s
    mov       rdi,        [FREE_MEM]         ; rdi = Current free mem head pointer
    cmp       rdi,        0xFFFFFFFFFFFFFFFF ; Check if we've reached the end of the free memory list
    je        .error
    mov       rcx,        [rdi]
    mov       [FREE_MEM], rcx                ; Set the head to the next block
    mov       rcx,        512                ; 512 qwords = 4 KiB
    rep stosq                                ; 0mem

    mov rax, rdi  ; Return the allocated memory in rax
    sub rax, 4096 ; Subtract 4096 from the pointer to get the start of the allocated memory

    pop rdi
    pop rcx
    ret

    .error:
        mov rbx, OUT_OF_MEMORY_MSG
        jmp panic_with_msg

kfree: ; Frees rcx sectors starting from rax
    push rbx

    mov rbx, KALLOC_NOT_SETUP_MSG

    cmp byte [IS_KALLOC_SETUP], 0
    je  panic_with_msg            ; kalloc is not set up yet; we can't free memory yet

    mov rbx,        [FREE_MEM] ; rbx = Current free mem head pointer
    mov [rax],      rbx        ; Set the next pointer to the current head
    mov [FREE_MEM], rax        ; Set the head to the new block

    pop rbx
    ret

IS_KALLOC_SETUP      db 0
OUT_OF_MEMORY_MSG    db "Out of memory!", 0
KALLOC_NOT_SETUP_MSG db "kalloc is not set up yet!", 0

%endif
