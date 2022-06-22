arraylist_new: ; eax: returns ptr
    mov eax, ARRAYLIST_LENGTH
    call malloc

    mov [eax], dword 0
    mov [eax+ARRAYLIST_ALLOCATED_SIZE_OFFSET], dword ARRAYLIST_DEFAULT_SIZE

    push eax
    push ebx

    mov ebx, eax
    mov eax, ARRAYLIST_DEFAULT_DATA_LENGTH
    call malloc
    mov [ebx+ARRAYLIST_DATA_OFFSET], eax

    pop ebx
    pop eax
    ret

arraylist_get: ; eax: ptr to arraylist, ebx: idx, returns val
    shl ebx, 2
    add ebx, [eax+ARRAYLIST_DATA_OFFSET]
    mov ebx, [ebx]

    ret

arraylist_add: ; eax: ptr to arraylist, ebx: val
    push edx

    mov edx, [eax]
    cmp edx, [eax+ARRAYLIST_ALLOCATED_SIZE_OFFSET]
    jmp .add

    push esi
    push edi
    push eax
    push ecx

    mov edx, eax
    add [eax+ARRAYLIST_ALLOCATED_SIZE_OFFSET], dword ARRAYLIST_DEFAULT_SIZE
    mov eax, [eax+ARRAYLIST_ALLOCATED_SIZE_OFFSET]
    shl eax, 2
    add eax, ARRAYLIST_DEFAULT_DATA_LENGTH
    call malloc
    mov esi, [edx+ARRAYLIST_DATA_OFFSET]
    mov edi, eax
    mov ecx, [edx]
    cld
    rep movsd
    pop ecx
    pop eax

    mov eax, [eax+ARRAYLIST_DATA_OFFSET]
    call free
    mov [edx+ARRAYLIST_DATA_OFFSET], edi

    pop edi
    pop esi

    .add:
    mov edx, [eax]
    shl edx, 2
    add edx, [eax+ARRAYLIST_DATA_OFFSET]
    mov [edx], ebx
    add [eax], dword 1

    pop edx
    ret

arraylist_remove: ; eax: ptr to arraylist
    push eax
    call arraylist_poll
    pop eax
    ret

arraylist_poll: ; eax: ptr to arraylist, ebx: returns the removed value
    sub [eax], dword 1
    mov ebx, [eax]
    call arraylist_get
    ret

arraylist_free: ; eax: ptr to arraylist
    push eax
    mov eax, [eax+ARRAYLIST_DATA_OFFSET]
    call free
    pop eax
    call free
    ret


ARRAYLIST_LENGTH equ 4 + 4 + 4 ; (size + allocated size + data ptr)
ARRAYLIST_ALLOCATED_SIZE_OFFSET equ 4 ; (size + data ptr)
ARRAYLIST_DATA_OFFSET equ 4 + 4
ARRAYLIST_DEFAULT_SIZE equ 10
ARRAYLIST_DEFAULT_DATA_LENGTH equ ARRAYLIST_DEFAULT_SIZE * 4
