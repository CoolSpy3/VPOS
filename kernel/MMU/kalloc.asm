%ifndef KERNEL_MMU_KALLOC
%define KERNEL_MMU_KALLOC

[bits 64]

%include "kernel/kernel.asm"

kalloc: ; Returns mem in rax
    push rcx ; TODO: This is currently the same as seq_alloc
             ; After free memory is located, it should be updated to read from FREE_MEM as a linked list,
             ; deferring to seq_alloc otherwise, and printing an error if there is no free memory.
    push rdi

    xor rax, rax
    mov rdi, [FREE_MEM]
    mov rcx, 512
    rep stosq
    mov [FREE_MEM], rdi

    mov rax, rdi
    sub rax, 4096

    pop rdi
    pop rcx
    ret

kfree: ; Frees mem in rax
    push rbx

    mov rbx, [FREE_MEM] ; rbx = Current free mem head pointer
    mov [rax], rbx ; Set the next pointer to the current head
    mov [FREE_MEM], rax ; Set the head to the new block

    pop rbx
    ret

%endif
