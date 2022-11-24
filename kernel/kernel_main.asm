kernel_main:

    ; call idt_install
    ; call pic_init

    call clear_textmode_buffer

    call ata_identify

    call malloc_init

    mov rax, [0x8000]
    and rax, 0xFFFF
    shl rax, 5
    add rax, 0x8002
    call vga_dump_long_mem_at_rax
    mov rcx, 20
    shl rcx, 3
    add rax, rcx
    call vga_dump_long_mem_at_rax
    mov rcx, 20
    shl rcx, 3
    add rax, rcx
    call vga_dump_long_mem_at_rax
    ; call dump_mem_map

    mov rax, [MEM_START]
    .loop:
    call vga_log_space
    call vga_log_rax
    call vga_log_qword_at_rax
    add rax, 8
    call vga_log_qword_at_rax
    add rax, 8
    call vga_log_qword_at_rax
    sub rax, 16
    cmp rax, [MEM_END]
    jae $
    add rax, [rax]
    jmp .loop

    ret
