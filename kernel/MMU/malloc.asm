%ifndef KERNEL_MMU_MALLOC
%define KERNEL_MMU_MALLOC

[bits 64]

%include "kernel/kernel.asm"

%ifdef IDE_VALIDATOR
    MEM_START dq 0
    MEM_END dq 0
%endif

malloc: ; rax: size, returns ptr
    add rax, BLOCK_HEADER_LENGTH
    cmp rax, BLOCK_MIN_SIZE
    jae .allocate_memory
    mov rax, BLOCK_MIN_SIZE
    .allocate_memory:

    push rbx
    mov rbx, [MEM_START]
    call .find_and_allocate_memory
    pop rbx
    push rax
    push rbx
    mov rbx, 0
    mov bx, [rax]
    add rax, rbx
    pop rbx
    mov [HEAP_PTR], rax
    cmp rax, [MEM_START]
    jb .done
    mov rax, [MEM_START]
    mov [HEAP_PTR], rax
    .done:
    pop rax
    add rax, BLOCK_HEADER_LENGTH
    ret

    .find_and_allocate_memory: ; rax: size, returns ptr, rbx: first block to search
    cmp [rbx+BLOCK_IN_USE_OFFSET], byte 0
    jne .search_next_block ; Don't allocate an in-use block

    cmp [rbx], rax
    jb .search_next_block ; We cannot allocate more memory than rxists in a block

    ; Allocate the memory

    push rdx
    mov rdx, [rbx]
    sub rdx, rax
    cmp rdx, BLOCK_MIN_SIZE
    jbe .do_allocate_memory ; If there is not enough space to split the block, allocate the whole block

    ; Otherwise, create two smaller blocks
    mov [rbx], rax ; Our current block will be allocated to the requested size
    push rcx
    mov rcx, rbx
    add rcx, rax
    mov [rcx], rdx ; A new block will gain the remaining space
    mov [rcx+BLOCK_PREV_LENGTH_OFFSET], rax
    mov [rcx+BLOCK_IN_USE_OFFSET], byte 0 ; It is unallocated
    add rcx, rdx
    cmp rcx, [MEM_END]
    jae .skip_link_prev_of_next_block
    mov [rcx+BLOCK_PREV_LENGTH_OFFSET], rdx ; The block after the new block has the new block as its previous
    .skip_link_prev_of_next_block:
    pop rcx

    .do_allocate_memory:
    pop rdx
    mov [rbx+BLOCK_IN_USE_OFFSET], byte 1 ; Flag the block as in use
    ; We could zero the memory, but we don't care about nonsense data or leaking info
    mov rax, rbx ; return this block
    ret

    .search_next_block:
    push rdx
    mov rdx, [rbx]
    add rbx, rdx
    pop rdx
    cmp rbx, [MEM_END]
    jae .search_from_start ; There is no next block, we've run out of memory
    jmp .find_and_allocate_memory ; try to allocate the next block

    .search_from_start:
    mov rbx, [MEM_START]
    jmp .find_and_allocate_memory

free: ; rax: ptr to memory
    push rax
    push rbx
    sub rax, BLOCK_HEADER_LENGTH
    mov [rax+BLOCK_IN_USE_OFFSET], byte 0 ; Flag the memory as not in use (free it)
    ; We could zero the memory, but we don't care about nonsense data or leaking info

    mov rbx, [rax]
    add rbx, rax
    cmp rbx, [MEM_END]
    jae .merge_prev_block ; Skip if there is no next block
    call .try_merge_blocks

    .merge_prev_block:
    mov rbx, [rax+BLOCK_PREV_LENGTH_OFFSET]
    cmp rbx, 0
    je .free_return ; Skip if there is no prev block
    push rdx
    mov rdx, rax
    sub rax, rbx
    mov rbx, rdx
    pop rdx
    call .try_merge_blocks

    .free_return: ; general return from free
    pop rbx
    pop rax
    ret

    .try_merge_blocks: ; rax: first block (lower address), rbx: second block (higher address)
    ; If either block is allocated, just return
    cmp [rax+BLOCK_IN_USE_OFFSET], byte 0
    jne .try_return
    cmp [rbx+BLOCK_IN_USE_OFFSET], byte 0
    jne .try_return

    ; Otherwise, merge them
    push rax
    push rdx

    mov rdx, [rax]
    add rdx, [rbx]
    mov [rax], rdx ; The merged block has a size of the sum of the two blocks
    add rax, rdx
    cmp rax, [MEM_END]
    jae .skip_link_prev_of_next_block
    ; If there is a next block, set it's previous length to that of the merged block
    mov [rax+BLOCK_PREV_LENGTH_OFFSET], rdx

    .skip_link_prev_of_next_block:
    pop rdx
    pop rax

    ; We could zero the header of the second block, but we don't care about nonsense data or leaking info

    .try_return: ; general return from try_merge_blocks
    ret


HEAP_PTR dq 0
BLOCK_HEADER_LENGTH equ 8+8+1 ; length (including header), in use
BLOCK_PREV_LENGTH_OFFSET equ 8
BLOCK_IN_USE_OFFSET equ 8+8

BLOCK_MIN_SIZE equ BLOCK_HEADER_LENGTH + 4

%endif
