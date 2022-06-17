pushcli:
    push eax
    cmp [ncli], byte 0
    jne .disint

    pushfd
    pop eax
    and eax, 0x200
    mov [intea], eax

    .disint:
        cli
        inc word [ncli]
        pop eax
        ret


popcli:
    push eax
    pushfd
    pop eax
    and eax, 0x200

    cmp eax, 0x200
    je panic

    dec word [ncli]
    js panic

    cmp [ncli], byte 0
    jne .return

    cmp [intea], word 0
    je .return

    sti

    .return:
    pop eax
    ret

aquire:
    push eax
    call pushcli
    cmp [esi], byte 0
    jne panic

    .do_aquire:

        mov eax, 1
        lock xchg [esi], eax
        cmp [esi], byte 0
        jne .do_aquire

    pop eax
    ret

release:
    cmp [esi], byte 0
    je panic
    mov [esi], byte 0
    call popcli
    ret

ncli db 0
intea dw 0
