vga_textmode_setchar:
    asm:
        mov rbx, {[args], rbx}
        mov rax, {[args+8], rax}
        mov ecx, 160
        mul ecx
        mov rcx, {[args+16], rcx}
        mov rdx, {[args+24], rdx}
        shl rdx, 8
        or rcx, rdx
        mov [0xB8000+rbx+rax], rcx
    pass

; ((func)faddr(vga_textmode_setchar))(0, 0, 'A', 0x07)
vga_textmode_setchar(0, 0, 'A', 0x07)
