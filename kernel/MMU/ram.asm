MEM_START equ $
MEM_LEN equ 10*512 ; bytes

initial_memory_header:
    dw MEM_LEN ; length (size of free memory)
    dw 0 ; Previous block has 0 length
    db 0 ; Unallocated

times MEM_LEN-BLOCK_HEADER_LENGTH db 0x00

; End of memory
MEM_END equ $
