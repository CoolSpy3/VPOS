MEM_START equ $
MEM_LEN equ 10*512 ; bytes

initial_memory_header:
    dd MEM_LEN ; length (size of free memory)
    db 0 ; Unallocated
    dd 0 ; No previous block
    dd 0 ; No next block

times MEM_LEN-BLOCK_HEADER_LENGTH db 0x00

; End of memory
MEM_END equ $
