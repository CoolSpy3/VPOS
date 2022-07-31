vga_textmode_setchar:
    addr = 0xB8000 + (80 * [args+4]) + [args]
    addr < [args+8] | [args+12] | ([addr] & 0xFFFF0000)