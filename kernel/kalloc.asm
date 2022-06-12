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

    


kmem:
    slock db 0
    use_lock db 0
    run dd 0