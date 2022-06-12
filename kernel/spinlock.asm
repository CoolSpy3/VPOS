pushcli:
    cmp ncli, 0
    jne disint

    
    pushfd
    pop eax
    and eax, 0x200
    mov intea, eax

    disint:
        cli
        inc ncli
        ret
    


popcli:
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
        ret

aquire:
    call pushcli
    cmp [si], 0
    jne panic

    to_aquire:

        mov eax, 1
        lock xchg si, eax
        cmp [si], 0
        jne to_aquire

    ret

release:
    cmp [si], 0
    je panic
    mov [si], 0
    call popcli
    ret

ncli db 0
intea db 0



    