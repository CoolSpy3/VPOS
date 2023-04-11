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
    call expand_page_table
    call setup_kernel_memory

    ret

%endif
