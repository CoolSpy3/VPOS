kernel_main:

    call idt_install
    call pic_init

    call clear_textmode_buffer

    mov eax, entrypoint
    call get_file_descriptor

    cmp ebx, 0
    je .entrypoint_find_failed

    mov eax, ebx
    call filestream_new

    call heapflow_init
    call heapflow_interpreter_new

    call heapflow_parse_filestream

    call heapflow_interpreter_free

    mov eax, ebx
    call free

    .return:

    ret

.entrypoint_find_failed:
    mov ebx, entrypoint_find_fail_text
    mov cx, 0x000
    mov dh, 7
    call vga_textmode_setstring
    jmp $

entrypoint db 'kernel_main.hf', 0
entrypoint_find_fail_text db 'Entrypoint file not found!', 0
