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
        inc ecx
        cmp ecx, edx
        jb .loop

    mov ebx, 0

    .done:
    pop edx
    pop ecx
    pop eax
    ret

    .found:
    mov ebx, eax
    add ebx, 4
    jmp .done

hashmap_get: ; eax: ptr to hashmap, ebx: key, returns value
    push eax
    mov eax, ebx
    call hash_string
    pop eax
    call hashmap_get_data
    ret

hashmap_get_data: ; eax: ptr to hashmap, ebx: key, returns value
    call hashmap_get_addr
    cmp ebx, 0
    je .done
    mov ebx, [ebx]
    .done:
    ret

hashmap_put: ; eax: ptr to hashmap, ebx: key (ptr to string), edx: val
    push ebx
    push eax
    mov eax, ebx
    call hash_string
    pop eax
    call hashmap_put_data
    pop ebx
    ret

hashmap_put_data: ; eax: ptr to hashmap, ebx: key, edx: val
    push ecx

    push ebx
    call hashmap_get_addr
    mov ecx, ebx
    pop ebx
    cmp ecx, 0
    jne .do_put

    mov ecx, [eax]
    cmp ecx, [eax+HASHMAP_ALLOCATED_SIZE_OFFSET]
    jb .select_next_val

    push esi
    push edi
    push eax

    mov ecx, eax
    add [eax+HASHMAP_ALLOCATED_SIZE_OFFSET], dword HASHMAP_DEFAULT_SIZE
    mov eax, [eax+HASHMAP_ALLOCATED_SIZE_OFFSET]
    shl eax, 3
    call malloc
    mov esi, [ecx+HASHMAP_DATA_OFFSET]
    mov edi, eax
    mov ecx, [ecx]
    shl ecx, 1
    push edi
    cld
    rep movsd
    pop edi
    pop eax

    push eax
    mov eax, [eax+HASHMAP_DATA_OFFSET]
    call free
    pop eax

    mov [eax+HASHMAP_DATA_OFFSET], edi

    pop edi
    pop esi

    .select_next_val:
    mov ecx, [eax]
    shl ecx, 3
    add ecx, [eax+HASHMAP_DATA_OFFSET]
    add ecx, 4

    .do_put:
    mov [ecx-4], ebx
    mov [ecx], edx
    inc dword [eax]

    pop ecx
    ret

hashmap_free: ; eax: ptr to hashmap
    push eax
    mov eax, [eax+HASHMAP_DATA_OFFSET]
    call free
    pop eax
    call free
    ret

; Implementation of sdbm (see http://www.cse.yorku.ca/~oz/hash.html)
hash_string: ; eax: ptr to string, ebx: returns hash
    push eax
    push ecx
    push edx

    mov ebx, 0

    .loop:
        cmp [eax], byte 0
        je .done

        mov ecx, ebx
        mov edx, 0
        mov dl, [eax]
        shl ecx, 6
        add edx, ecx
        shl ecx, 10
        add edx, ecx
        sub edx, ebx
        mov ebx, edx

        inc eax
        jmp .loop

    .done:
    pop edx
    pop ecx
    pop eax
    ret

hashmap_copy: ; eax: ptr to hashmap, ebx: returns ptr to new hashmap
    push esi
    push edi
    push ecx

    cld

    push eax
    mov eax, HASHMAP_LENGTH
    call malloc
    mov ebx, eax
    pop eax

    mov esi, eax
    mov edi, ebx
    mov ecx, HASHMAP_LENGTH
    rep movsb

    push eax
    mov eax, [eax+HASHMAP_ALLOCATED_SIZE_OFFSET]
    shl eax, 3
    mov ecx, eax ; This will be used for the next memcpy
    call malloc
    mov edi, eax ; This will be used for the next memcpy
    mov [ebx+HASHMAP_DATA_OFFSET], eax
    pop eax

    mov esi, [eax+HASHMAP_DATA_OFFSET]
    rep movsb

    pop ecx
    pop edi
    pop esi
    ret


HASHMAP_LENGTH equ 4 + 4 + 4 ; (size + allocated size + data ptr)
HASHMAP_ALLOCATED_SIZE_OFFSET equ 4 ; (size + data ptr)
HASHMAP_DATA_OFFSET equ 4 + 4
HASHMAP_DEFAULT_SIZE equ 2
HASHMAP_DEFAULT_DATA_LENGTH equ HASHMAP_DEFAULT_SIZE * 8
