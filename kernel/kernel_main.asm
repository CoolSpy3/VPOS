kernel_main:

    ; call idt_install
    ; call pic_init

    call clear_textmode_buffer

    call vga_log_space
    call vga_log_space
    call vga_log_space
    call vga_log_space
    mov rax, MEM_START
    call vga_log_rax
    mov rax, MEM_END
    call vga_log_rax
    call vga_log_rax

    ret
