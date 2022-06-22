hashmap_new: ; eax: returns ptr
    mov eax, HASHMAP_LENGTH
    call malloc

    mov [eax], dword 0
    mov [eax+HASHMAP_ALLOCATED_SIZE_OFFSET], dword HASHMAP_DEFAULT_SIZE

    push eax
    push ebx

    mov ebx, eax
    mov eax, HASHMAP_DEFAULT_DATA_LENGTH
    call malloc
    mov [ebx+HASHMAP_DATA_OFFSET], eax

    pop ebx
    pop eax
    ret

hashmap_get_addr: ; eax: ptr to hashmap, ebx: key, returns ptr to value
    push eax
    push ecx
    push edx

    mov edx, [eax]
    mov eax, [eax+HASHMAP_DATA_OFFSET]

    mov ecx, 0
    .loop:
    cmp ebx, [eax]
    je .found
    add eax, 8
    add ecx, 1
    cmp ecx, edx
    jb .loop

    mov ebx, 0

    .done:
    pop ecx
    pop ebx
    pop eax
    ret

    .found:
    mov ebx, eax
    jmp done

hashmap_get: ; eax: ptr to hashmap, ebx: key, returns value
    call hashmap_get_addr
    cmp ebx, 0
    je .done
    mov ebx, [ebx]
    .done:
    ret

hashmap_put: ; eax: ptr to hashmap, ebx: key, edx: val
    call hashmap_get_addr
    cmp ebx, 0
    jne .do_put

    cmp [eax], [eax+HASHMAP_ALLOCATED_SIZE_OFFSET]
    jb .select_next_val

    .select_next_val:
    push edx
    mov edx, [edx]
    shl edx, 3
    add edx, [eax+HASHMAP_DATA_OFFSET]
    

    .do_put:
    mov [ebx], edx
    ret

hashmap_free: ; eax: ptr to hashmap
    push eax
    mov eax, [eax+HASHMAP_DATA_OFFSET]
    call free
    pop eax
    call free
    ret


HASHMAP_LENGTH equ 4 + 4 + 4 ; (size + allocated size + data ptr)
HASHMAP_ALLOCATED_SIZE_OFFSET equ 4 + 4 ; (size + data ptr)
HASHMAP_DATA_OFFSET equ 4 + 4
HASHMAP_DEFAULT_SIZE equ 10
HASHMAP_DEFAULT_DATA_LENGTH equ ARRAYLIST_DEFAULT_SIZE * 8
