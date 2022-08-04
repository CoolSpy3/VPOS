hashmap_new: ; rax: returns ptr
    mov rax, HASHMAP_LENGTH
    call malloc

    mov [rax], dword 0
    mov [rax+HASHMAP_ALLOCATED_SIZE_OFFSET], dword HASHMAP_DEFAULT_SIZE

    push rax
    push rbx

    mov rbx, rax
    mov rax, HASHMAP_DEFAULT_DATA_LENGTH
    call malloc
    mov [rbx+HASHMAP_DATA_OFFSET], rax

    pop rbx
    pop rax
    ret

hashmap_get_addr: ; rax: ptr to hashmap, rbx: key, returns ptr to value
    push rax
    push rcx
    push rdx

    mov rdx, [rax]
    mov rax, [rax+HASHMAP_DATA_OFFSET]

    mov rcx, 0
    .loop:
        cmp rbx, [rax]
        je .found
        add rax, 8
        inc rcx
        cmp rcx, rdx
        jb .loop

    mov rbx, 0

    .done:
    pop rdx
    pop rcx
    pop rax
    ret

    .found:
    mov rbx, rax
    add rbx, 4
    jmp .done

hashmap_get: ; rax: ptr to hashmap, rbx: key, returns value
    push rax
    mov rax, rbx
    call hash_string
    pop rax
    call hashmap_get_data
    ret

hashmap_get_data: ; rax: ptr to hashmap, rbx: key, returns value
    call hashmap_get_addr
    cmp rbx, 0
    je .done
    mov rbx, [rbx]
    .done:
    ret

hashmap_put: ; rax: ptr to hashmap, rbx: key (ptr to string), rdx: val
    push rbx
    push rax
    mov rax, rbx
    call hash_string
    pop rax
    call hashmap_put_data
    pop rbx
    ret

hashmap_put_data: ; rax: ptr to hashmap, rbx: key, rdx: val
    push rcx

    push rbx
    call hashmap_get_addr
    mov rcx, rbx
    pop rbx
    cmp rcx, 0
    jne .do_put

    mov rcx, [rax]
    cmp rcx, [rax+HASHMAP_ALLOCATED_SIZE_OFFSET]
    jb .select_next_val

    push rsi
    push rdi
    push rax

    mov rcx, rax
    add [rax+HASHMAP_ALLOCATED_SIZE_OFFSET], dword HASHMAP_DEFAULT_SIZE
    mov rax, [rax+HASHMAP_ALLOCATED_SIZE_OFFSET]
    shl rax, 3
    call malloc
    mov rsi, [rcx+HASHMAP_DATA_OFFSET]
    mov rdi, rax
    mov rcx, [rcx]
    shl rcx, 1
    push rdi
    cld
    rep movsd
    pop rdi
    pop rax

    push rax
    mov rax, [rax+HASHMAP_DATA_OFFSET]
    call free
    pop rax

    mov [rax+HASHMAP_DATA_OFFSET], rdi

    pop rdi
    pop rsi

    .select_next_val:
    mov rcx, [rax]
    shl rcx, 3
    add rcx, [rax+HASHMAP_DATA_OFFSET]
    add rcx, 4

    .do_put:
    mov [rcx-4], rbx
    mov [rcx], rdx
    inc dword [rax]

    pop rcx
    ret

hashmap_free: ; rax: ptr to hashmap
    push rax
    mov rax, [rax+HASHMAP_DATA_OFFSET]
    call free
    pop rax
    call free
    ret

; Implementation of sdbm (see http://www.cse.yorku.ca/~oz/hash.html)
hash_string: ; rax: ptr to string, rbx: returns hash
    push rax
    push rcx
    push rdx

    mov rbx, 0

    .loop:
        cmp [rax], byte 0
        je .done

        mov rcx, rbx
        mov rdx, 0
        mov dl, [rax]
        shl rcx, 6
        add rdx, rcx
        shl rcx, 10
        add rdx, rcx
        sub rdx, rbx
        mov rbx, rdx

        inc rax
        jmp .loop

    .done:
    pop rdx
    pop rcx
    pop rax
    ret

hashmap_copy: ; rax: ptr to hashmap, rbx: returns ptr to new hashmap
    push rsi
    push rdi
    push rcx

    cld

    push rax
    mov rax, HASHMAP_LENGTH
    call malloc
    mov rbx, rax
    pop rax

    mov rsi, rax
    mov rdi, rbx
    mov rcx, HASHMAP_LENGTH
    rep movsb

    push rax
    mov rax, [rax+HASHMAP_ALLOCATED_SIZE_OFFSET]
    shl rax, 3
    mov rcx, rax ; This will be used for the next memcpy
    call malloc
    mov rdi, rax ; This will be used for the next memcpy
    mov [rbx+HASHMAP_DATA_OFFSET], rax
    pop rax

    mov rsi, [rax+HASHMAP_DATA_OFFSET]
    rep movsb

    pop rcx
    pop rdi
    pop rsi
    ret


HASHMAP_LENGTH equ 4 + 4 + 4 ; (size + allocated size + data ptr)
HASHMAP_ALLOCATED_SIZE_OFFSET equ 4 ; (size + data ptr)
HASHMAP_DATA_OFFSET equ 4 + 4
HASHMAP_DEFAULT_SIZE equ 2
HASHMAP_DEFAULT_DATA_LENGTH equ HASHMAP_DEFAULT_SIZE * 8
