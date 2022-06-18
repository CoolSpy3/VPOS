kinit1:
    call freerange
    ret

freerange:
    add eax, 4095
    and eax, 4096

    .loop:
        call kfree
        add eax, 4096
        cmp eax, ebx
        jle .loop

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
    call memset
    pop eax

    cmp [use_lock], byte 0
    je .no_aquire

    mov si, slock
    call aquire

    .no_aquire:
    lea ecx, [freelist]
    mov [freelist], ecx

    cmp [use_lock], byte 0
    je .no_release

    call release

    .no_release:
    pop esi
    pop edi
    pop ecx
    ret

kalloc: ; allocates one 4096 byte page of memory
        ; ecx returns 0 if the page cant be allocated
        ; also this function probably dosent work at the moment
    push esi
    cmp [use_lock], byte 0
    je .cont1

    mov esi, slock
    call aquire

    .cont1:

    mov ecx, [freelist] ; r = kmem.freelist;
    cmp ecx, 0 ; if(r) in c
    je .cont2

    mov [freelist], ecx ; gets the next page(i think)
                      ; kmem.freelist = r->next;

    .cont2:

    cmp [use_lock], byte 0
    je .cont3

    call release

    .cont3:

    pop esi
    ret


kmem:
    slock db 0
    use_lock db 0
    freelist dd 0