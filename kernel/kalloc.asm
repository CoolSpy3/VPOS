kinit1:
    call freerange
    ret

freerange:
    add eax, 4095
    and eax, 4096

    kfree_loop:
        call kfree
        add eax, 4096
        cmp eax, ebx
        jle kfree_loop

    ret

kfree:
    push ecx
    push edi
    push esi
    push eax
    and eax, 4095
    cmp eax, 0
    jne panic
    pop eax

    push eax
    sub eax, 0x80000000
    cmp eax, 0xe000000
    jge panic
    pop eax

    push eax
    mov edi, eax
    mov eax, 1
    mov ecx, 4096
    pop eax

    cmp use_lock, 0
    je kfree_no_aquire

    mov si, slock
    call aquire

kfree_no_aquire:
    lea freelist, [freelist]

    cmp use_lock, 0
    je kfree_no_release

    call release

kfree_no_release:
    pop esi
    pop edi
    pop ecx
    ret

kmem:
    slock db 0
    use_lock db 0
    freelist dd 0