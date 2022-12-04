kernel_main:

    call clear_textmode_buffer

    call ata_identify

    movzx rbx, word [EXT_MEM_LEN]
    call vga_log_rbx
    call vga_log_space

    call dump_mem_map

    ret
