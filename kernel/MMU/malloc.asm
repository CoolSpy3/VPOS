malloc: ; eax: size, returns ptr
    add eax, BLOCK_HEADER_LENGTH
    cmp eax, BLOCK_MIN_SIZE
    jae .allocate_memory
    mov eax, BLOCK_MIN_SIZE
    .allocate_memory:
    push ebx
    mov ebx, MEM_START
    call .find_and_allocate_memory
    pop ebx
    add eax, BLOCK_HEADER_LENGTH
    ret

    .find_and_allocate_memory: ; eax: size, returns ptr, ebx: first block to search
    cmp [ebx+BLOCK_IN_USE_OFFSET], byte 0
    jne .search_next_block ; Don't allocate an in-use block

    cmp [ebx], eax
    jb .search_next_block ; We cannot allocate more memory than exists in a block

    ; Allocate the memory

    push edx
    mov edx, [ebx]
    sub edx, eax
    cmp edx, BLOCK_HEADER_LENGTH
    jbe .do_allocate_memory ; If there is not enough space to split the block, allocate the whole block

    ; Otherwise, create two smaller blocks
    mov [ebx], eax ; Our current block will be allocated to the requested size
    push ecx
    mov ecx, ebx
    add ecx, eax
    mov [ecx], edx ; A new block will gain the remaining space
    mov [ecx+BLOCK_IN_USE_OFFSET], byte 0 ; It is unallocated
    mov [ecx+BLOCK_PREV_PTR_OFFSET], ebx ; Its previous block is our current block
    mov edx, [ebx+BLOCK_NEXT_PTR_OFFSET]
    mov [ecx+BLOCK_NEXT_PTR_OFFSET], edx ; Its next block is the block following our current block
    mov [ebx+BLOCK_NEXT_PTR_OFFSET], ecx ; Our next block is the new block
    pop ecx

    .do_allocate_memory:
    pop edx
    mov [ebx+BLOCK_IN_USE_OFFSET], byte 1 ; Flag the block as in use
    ; We could zero the memory, but we don't care about nonsense data or leaking info
    mov eax, ebx ; return this block
    ret

    .search_next_block:
    mov ebx, [ebx+BLOCK_NEXT_PTR_OFFSET]
    cmp ebx, 0
    je panic ; There is no next block, we've run out of memory
    jmp .find_and_allocate_memory ; try to allocate the next block

free: ; eax: ptr to memory
    push ebx
    sub eax, BLOCK_HEADER_LENGTH
    mov [eax+BLOCK_IN_USE_OFFSET], byte 0 ; Flag the memory as not in use (free it)
    ; We could zero the memory, but we don't care about nonsense data or leaking info

    mov ebx, [eax+BLOCK_NEXT_PTR_OFFSET]
    cmp ebx, 0
    je .merge_prev_block ; Skip if there is no next block
    call .try_merge_blocks

    .merge_prev_block:
    mov ebx, [eax+BLOCK_PREV_PTR_OFFSET]
    cmp ebx, 0
    je .free_return ; Skip if there is no prev block
    xchg eax, ebx ; Swap the registers so that the lower address (previous block) is in eax
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
    push edx

    mov edx, [eax]
    add edx, [ebx]
    mov [eax], edx ; The merged block has a size of the sum of the two blocks
    mov edx, [ebx+BLOCK_NEXT_PTR_OFFSET]
    mov [eax+BLOCK_NEXT_PTR_OFFSET], edx ; The next block of the merged block is the next block of the second block
    cmp edx, 0
    je .skip_link_prev_of_next_block
    ; If there is a next block, set it's previous block to the merged block
    mov [edx+BLOCK_PREV_PTR_OFFSET], eax

    .skip_link_prev_of_next_block:
    pop edx

    ; We could zero the header of the second block, but we don't care about nonsense data or leaking info

    .try_return: ; general return from try_merge_blocks
    ret

BLOCK_HEADER_LENGTH equ 4+1+4+4 ; length (including header), in use, prev, next
BLOCK_IN_USE_OFFSET equ 4
BLOCK_PREV_PTR_OFFSET equ 4+1
BLOCK_NEXT_PTR_OFFSET equ 4+1+4

BLOCK_MIN_SIZE equ BLOCK_HEADER_LENGTH + 4
