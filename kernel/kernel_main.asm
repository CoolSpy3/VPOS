%ifndef KERNEL_MAIN
%define KERNEL_MAIN

%include "kernel/disk/ata.asm"
%include "kernel/graphics_drivers/vga_logger.asm"
%include "kernel/MMU/init.asm"
%include "kernel/MMU/mmu_debug_tools.asm"
%include "kernel/MMU/mem_map.asm"

kernel_main:

    call clear_textmode_buffer

    call ata_identify

    movzx rbx, word [EXT_MEM_LEN]
    call vga_log_rbx
    call vga_log_space
    call dump_mem_map

    call format_mem_map

    call vga_log_reset
    call dump_formatted_mem_map

    call expand_page_table
    call setup_kernel_memory

    call vga_log_reset

    mov rbx, INDEXING_MEMORY_MESSAGE
    xor rcx, rcx
    mov dh, 7
    call vga_textmode_setstring

    call setup_kalloc

    call clear_textmode_buffer

    mov rcx, 0
    mov rdx, 20
    .loop: ; for(int i = 0; i < rdx; i++) { print(kalloc()); }
        call kalloc
        call vga_log_rax
        call vga_log_space
        inc rcx
        cmp rcx, rdx
        jb .loop

    ; TODO: SETUP PIC
    ; sti ; Enable interrupts

    ret

INDEXING_MEMORY_MESSAGE db "Please Wait... Indexing memory... (This process could take a while)", 0

%endif
