%ifndef KERNEL_MMU_STATICRAM
%define KERNEL_MMU_STATICRAM

%include "kernel/MMU/malloc.asm"

malloc_init:
    mov qword [HEAP_PTR], MEM_START_POS
    ret

MEM_START dq MEM_START_POS
MEM_LEN dq MEM_LEN_VAL

MEM_START_POS equ $
MEM_LEN_VAL equ 20*512 ; bytes

initial_memory_header:
    dq MEM_LEN_VAL ; length (size of free memory)
    dq 0 ; Previous block has 0 length
    db 0 ; Unallocated

times MEM_LEN_VAL-BLOCK_HEADER_LENGTH db 0x00

; End of memory
MEM_END_POS equ $
MEM_END dq MEM_END_POS

%endif
