%ifndef KERNEL_MMU_KALLOC
%define KERNEL_MMU_KALLOC

[bits 64]

%include "kernel/kernel.asm"

kalloc: ; Returns mem in rax
    push rcx
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

    mov rbx, [FREE_MEM]
    mov [rax], rbx
    mov [FREE_MEM], rax

    pop rbx
    ret

%endif
