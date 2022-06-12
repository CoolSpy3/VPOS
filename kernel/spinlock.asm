pushcli:
    push eax
    cmp ncli, 0
    jne pushcli_disint

    pushfd
    pop eax
    and eax, 0x200
    mov intea, eax

pushcli_disint:
        cli
        inc ncli
        pop eax
        ret


popcli:
    push eax
    pushfd
    pop eax
    and eax, 0x200

    cmp eax, 0x200
    je panic

    dec ncli
    js panic

    cmp ncli, 0
    jne popcli_return

    cmp intea, 0
    je popcli_return

    sti

popcli_return:
    pop eax
    ret

aquire:
    push eax
    call pushcli
    cmp [si], 0
    jne panic

to_aquire:

    mov eax, 1
    lock xchg si, eax
    cmp [esi], 0
    jne to_aquire

    pop eax
    ret

release:
    cmp [esi], 0
    je panic
    mov [esi], 0
    call popcli
    ret

ncli db 0
intea db 0
