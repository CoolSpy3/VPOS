kernel_main:

    ; call idt_install
    ; call pic_init

    call clear_textmode_buffer

    call ata_identify

    call malloc_init

    mov rax, 0x8002
    mov rcx, 24
    shl rcx, 3
    add rax, rcx
    call vga_dump_long_mem_at_rax
    mov rcx, 20
    shl rcx, 3
    add rax, rcx
    call vga_dump_long_mem_at_rax
    ; call dump_mem_map

    ret
