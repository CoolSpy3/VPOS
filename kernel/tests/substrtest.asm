[bits 64]

%include "kernel/util/string.asm"


substrtest:
    mov rsi, test_string
    mov rax, 2
    mov rcx, 5
    call substr

    mov rbx, rdi
    mov cx, 0x700
    call vga_textmode_setstring
    ret


test_string db 'test12323', 0
