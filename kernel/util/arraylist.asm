%ifndef UTIL_ARRAYLIST
%define UTIL_ARRAYLIST

[bits 64]

%include "kernel/MMU/malloc.asm"

arraylist_new: ; rax: returns ptr
    mov rax, ARRAYLIST_LENGTH
    call malloc

    mov [rax], dword 0
    mov [rax+ARRAYLIST_ALLOCATED_SIZE_OFFSET], dword ARRAYLIST_DEFAULT_SIZE

    push rax
    push rbx

    mov rbx, rax
    mov rax, ARRAYLIST_DEFAULT_DATA_LENGTH
    call malloc
    mov [rbx+ARRAYLIST_DATA_OFFSET], rax

    pop rbx
    pop rax
    ret

arraylist_get: ; rax: ptr to arraylist, rbx: idx, returns val
    shl rbx, 2
    add rbx, [rax+ARRAYLIST_DATA_OFFSET]
    mov rbx, [rbx]

    ret

arraylist_add: ; rax: ptr to arraylist, rbx: val
    push rdx

    mov rdx, [rax]
    cmp rdx, [rax+ARRAYLIST_ALLOCATED_SIZE_OFFSET]
    jb .add

    push rsi
    push rdi
    push rax
    push rcx

    mov rdx, rax
    add [rax+ARRAYLIST_ALLOCATED_SIZE_OFFSET], dword ARRAYLIST_DEFAULT_SIZE
    mov rax, [rax+ARRAYLIST_ALLOCATED_SIZE_OFFSET]
    shl rax, 2
    call malloc
    mov rsi, [rdx+ARRAYLIST_DATA_OFFSET]
    mov rdi, rax
    mov rcx, [rdx]
    push rdi
    cld
    rep movsd
    pop rdi
    pop rcx
    pop rax

    push rax
    mov rax, [rax+ARRAYLIST_DATA_OFFSET]
    call free
    pop rax

    mov [rax+ARRAYLIST_DATA_OFFSET], rdi

    pop rdi
    pop rsi

    .add:
    mov rdx, [rax]
    shl rdx, 2
    add rdx, [rax+ARRAYLIST_DATA_OFFSET]
    mov [rdx], rbx
    add [rax], dword 1

    pop rdx
    ret

arraylist_remove: ; rax: ptr to arraylist
    push rax
    call arraylist_poll
    pop rax
    ret

arraylist_poll: ; rax: ptr to arraylist, rbx: returns the removed value
    sub [rax], dword 1
    mov rbx, [rax]
    call arraylist_get
    ret

arraylist_free: ; rax: ptr to arraylist
    push rax
    mov rax, [rax+ARRAYLIST_DATA_OFFSET]
    call free
    pop rax
    call free
    ret

arraylist_clear_with_free: ; rax: ptr to arraylist
    push rax
    push rcx

    mov rcx, [rax]
    mov rax, [rax+ARRAYLIST_DATA_OFFSET]

    jrcxz .skip_loop

    .loop:
        push rax
        mov rax, [rax]
        call free
        pop rax
        add rax, 4
        dec rcx
        jnz .loop

    .skip_loop:

    pop rcx
    pop rax

    mov [rax], dword 0

    ret

arraylist_deep_free: ; rax: ptr to arraylist
    call arraylist_clear_with_free
    call arraylist_free
    ret

arraylist_copy: ; rax: ptr to arraylist, rbx: returns ptr to new arraylist
    push rsi
    push rdi
    push rcx

    cld

    push rax
    mov rax, ARRAYLIST_LENGTH
    call malloc
    mov rbx, rax
    pop rax

    mov rsi, rax
    mov rdi, rbx
    mov rcx, ARRAYLIST_LENGTH
    rep movsb

    push rax
    mov rax, [rax+ARRAYLIST_ALLOCATED_SIZE_OFFSET]
    shl rax, 2
    mov rcx, rax ; This will be used for the next memcpy
    call malloc
    mov rdi, rax ; This will be used for the next memcpy
    mov [rbx+ARRAYLIST_DATA_OFFSET], rax
    pop rax

    mov rsi, [rax+ARRAYLIST_DATA_OFFSET]
    rep movsb

    pop rcx
    pop rdi
    pop rsi
    ret

ARRAYLIST_LENGTH equ 4 + 4 + 4 ; (size + allocated size + data ptr)
ARRAYLIST_ALLOCATED_SIZE_OFFSET equ 4 ; (size + data ptr)
ARRAYLIST_DATA_OFFSET equ 4 + 4
ARRAYLIST_DEFAULT_SIZE equ 2
ARRAYLIST_DEFAULT_DATA_LENGTH equ ARRAYLIST_DEFAULT_SIZE * 4

%endif
