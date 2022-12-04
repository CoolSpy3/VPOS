dump_mem_map:
    push rax
    push rcx
    push rsi
    movzx rcx, word [0x8000]

    mov rsi, 0x8002

    .loop:
        jrcxz .done
        mov rax, [rsi]
        call vga_log_rax ; Start Pos
        add rax, [rsi+8]
        call vga_log_rax ; End Pos
        mov rax, [rsi+8]
        call vga_log_rax ; Length
        mov eax, [rsi+16] ; This will zero out the upper 32 bits as well
        call vga_log_rax ; Type
        mov eax, [rsi+20]
        call vga_log_rax ; Extended Attributes
        call vga_log_space
        add rsi, 32
        dec cx
        jmp .loop

    .done:

    pop rsi
    pop rcx
    pop rax
    ret
