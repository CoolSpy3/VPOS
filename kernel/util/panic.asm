panic:
    mov [0xb8000], word 'P' | 0x700
    jmp $
