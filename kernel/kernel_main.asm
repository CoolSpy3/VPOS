kernel_main:

    call idt_install
    call pic_init

    call clear_textmode_buffer

    call vga_log_space
    call vga_log_space
    call vga_log_space
    call vga_log_space
    mov eax, MEM_START
    call vga_log_eax
    mov eax, MEM_END
    call vga_log_eax
    call vga_log_eax

    ret
