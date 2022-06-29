malloc: ; eax: size, returns ptr
    add eax, BLOCK_HEADER_LENGTH
    cmp eax, BLOCK_MIN_SIZE
    jae .allocate_memory
    mov eax, BLOCK_MIN_SIZE
    .allocate_memory:
    cmp eax, 0xFFFF
    ja panic

    push ebx
    ; mov ebx, [HEAP_PTR]
    ; add [HEAP_PTR], eax
    mov ebx, MEM_START
    call .find_and_allocate_memory
    pop ebx
    add eax, BLOCK_HEADER_LENGTH
    ret

    .find_and_allocate_memory: ; eax: size, returns ptr, ebx: first block to search
    cmp [ebx+BLOCK_IN_USE_OFFSET], byte 0
    jne .search_next_block ; Don't allocate an in-use block

    cmp [ebx], ax
    jb .search_next_block ; We cannot allocate more memory than exists in a block

    ; Allocate the memory

    push edx
    mov edx, 0
    mov dx, [ebx]
    sub dx, ax
    cmp dx, BLOCK_MIN_SIZE
    jbe .do_allocate_memory ; If there is not enough space to split the block, allocate the whole block

    ; Otherwise, create two smaller blocks
    mov [ebx], ax ; Our current block will be allocated to the requested size
    push ecx
    mov ecx, ebx
    add ecx, eax
    mov [ecx], dx ; A new block will gain the remaining space
    mov [ecx+BLOCK_PREV_LENGTH_OFFSET], ax
    mov [ecx+BLOCK_IN_USE_OFFSET], byte 0 ; It is unallocated
    add ecx, edx
    mov [ecx+BLOCK_PREV_LENGTH_OFFSET], dx ; The block after the new block has the new block as its previous
    pop ecx

    .do_allocate_memory:
    pop edx
    mov [ebx+BLOCK_IN_USE_OFFSET], byte 1 ; Flag the block as in use
    ; We could zero the memory, but we don't care about nonsense data or leaking info
    mov eax, ebx ; return this block
    ret

    .search_next_block:
    push edx
    mov edx, 0
    mov dx, [ebx]
    add ebx, edx
    pop edx
    cmp ebx, MEM_END
    jae panic ; There is no next block, we've run out of memory
    call .find_and_allocate_memory ; try to allocate the next block
    ret

free: ; eax: ptr to memory
    ret
    push ebx
    sub eax, BLOCK_HEADER_LENGTH
    mov [eax+BLOCK_IN_USE_OFFSET], byte 0 ; Flag the memory as not in use (free it)
    ; We could zero the memory, but we don't care about nonsense data or leaking info

    cmp [HEAP_PTR], eax
    jb .free
    mov [HEAP_PTR], eax
    .free:

    mov ebx, 0
    mov bx, [eax]
    add ebx, eax
    cmp ebx, MEM_END
    jae .merge_prev_block ; Skip if there is no next block
    call .try_merge_blocks

    .merge_prev_block:
    mov ebx, 0
    mov bx, [eax+BLOCK_PREV_LENGTH_OFFSET]
    cmp bx, 0
    je .free_return ; Skip if there is no prev block
    push edx
    mov edx, eax
    sub eax, ebx
    mov ebx, edx
    pop edx
    call .try_merge_blocks

    .free_return: ; general return from free
    pop ebx
    ret

    .try_merge_blocks: ; eax: first block (lower address), ebx: second block (higher address)
    ; If either block is allocated, just return
    cmp [eax+BLOCK_IN_USE_OFFSET], byte 0
    jne .try_return
    cmp [ebx+BLOCK_IN_USE_OFFSET], byte 0
    jne .try_return

    ; Otherwise, merge them
    push eax
    push edx

    mov edx, 0
    mov dx, [eax]
    add dx, [ebx]
    mov [eax], dx ; The merged block has a size of the sum of the two blocks
    add eax, edx
    cmp eax, MEM_END
    jae .skip_link_prev_of_next_block
    ; If there is a next block, set it's previous length to that of the merged block
    mov [eax+BLOCK_PREV_LENGTH_OFFSET], dx

    .skip_link_prev_of_next_block:
    pop edx
    pop eax

    ; We could zero the header of the second block, but we don't care about nonsense data or leaking info

    .try_return: ; general return from try_merge_blocks
    ret


HEAP_PTR dd MEM_START
BLOCK_HEADER_LENGTH equ 2+2+1 ; length (including header), in use
BLOCK_PREV_LENGTH_OFFSET equ 2
BLOCK_IN_USE_OFFSET equ 2+2

BLOCK_MIN_SIZE equ BLOCK_HEADER_LENGTH + 4
