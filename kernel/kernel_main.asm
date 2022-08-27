kernel_main:

    ; call idt_install
    ; call pic_init

    call clear_textmode_buffer

    call dump_mem_map

    ret
