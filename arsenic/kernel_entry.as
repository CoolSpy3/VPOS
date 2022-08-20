vga_textmode_setchar:
    qword addr = 0xB8000 + (80 * [args+4]) + [args]
    addr < [args+8] | [args+12] | ([addr] ^ 0xFFFF)

((func)faddr(vga_textmode_setchar))(0, 0, 'A', 0x07)
