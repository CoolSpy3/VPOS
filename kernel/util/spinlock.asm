%ifndef UTIL_SPINLOCK
%define UTIL_SPINLOCK

[bits 64]

%include "kernel/MMU/malloc.asm"

pushcli:
    push rax
    cmp [ncli], byte 0
    jne .disint

    pushfq
    pop rax
    and rax, 0x200
    mov [intea], rax

    .disint:
        cli
        inc word [ncli]
        pop rax
        ret


popcli:
    push rax
    pushfq
    pop rax
    and rax, 0x200

    cmp rax, 0x200
    je panic

    dec word [ncli]
    js panic

    cmp [ncli], byte 0
    jne .return

    cmp [intea], word 0
    je .return

    sti

    .return:
    pop rax
    ret

aquire:
    push rax
    call pushcli
    cmp [esi], byte 0
    jne panic

    .do_aquire:

        mov rax, 1
        lock xchg [esi], rax
        cmp [esi], byte 0
        jne .do_aquire

    pop rax
    ret

release:
    cmp [esi], byte 0
    je panic
    mov [esi], byte 0
    call popcli
    ret

ncli db 0
intea dw 0

%endif
