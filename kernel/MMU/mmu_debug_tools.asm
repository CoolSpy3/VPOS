%ifndef KERNEL_MMU_DEBUG_TOOLS
%define KERNEL_MMU_DEBUG_TOOLS

[bits 64]

%include "kernel/graphics_drivers/vga_logger.asm"
%include "kernel/kernel.asm"

dump_mem_map:
    push rax
    push rcx
    push rsi
    movzx rcx, word [mem_map]

    mov rsi, mem_map + 2

    call dump_map_entries

    pop rsi
    pop rcx
    pop rax
    ret

dump_formatted_mem_map:
    push rax
    push rcx
    push rsi

    movzx rcx, word [mem_map]
    shl rcx, 5
    mov rsi, mem_map + 2
    lea rsi, [rsi + rcx + 2] ; rsi = start of formatted mem map

    movzx rcx, word [rsi - 2] ; rcx = number of entries

    call dump_map_entries

    pop rsi
    pop rcx
    pop rax
    ret

dump_map_entries: ; rsi: first entry, rcx: number of entries (this function modifies rax)
    .loop:
        jrcxz .done
        mov rax, [rsi]
        call vga_log_rax ; Start Pos
        add rax, [rsi+8]
        call vga_log_rax ; End Pos (BIOS map) / undefined (formatted map)
        mov rax, [rsi+8]
        call vga_log_rax ; Length (BIOS map) / End Pos (formatted map)
        mov eax, [rsi+16] ; This will zero out the upper 32 bits as well
        call vga_log_rax ; Type
        mov eax, [rsi+20]
        call vga_log_rax ; Extended Attributes
        call vga_log_space
        add rsi, 32
        dec rcx
        jmp .loop

    .done:
    ret

dump_kalloc_list:
    push rax

    mov rax, FREE_MEM

    .loop:
        mov rax, [rax]
        call vga_log_rax
        cmp rax, 0
        jne .loop

    pop rax
    ret

%endif
