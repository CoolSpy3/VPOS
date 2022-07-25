heapflow_function_new: ; ebx: returns ptr, ecx: ptr to lines, edx: ptr to ctx
    push eax

    mov eax, HEAPFLOW_FUNCTION_LENGTH
    call malloc

    push eax
    call heapflow_function_create_virtual_file
    call filestream_new
    pop eax

    mov [eax], ebx
    mov [eax+HEAPFLOW_FUNCTION_CTX_OFFSET], edx

    mov ebx, eax

    pop eax
    ret

heapflow_function_call: ; ebx: ptr to function, ecx: returns flags, edx: ptr to interpreter
    push eax

    call arraylist_new
    call heapflow_function_call_with_params
    call arraylist_free

    pop eax
    ret

heapflow_function_call_with_params: ; eax: ptr to params, ebx: ptr to function, ecx: returns flags, edx: ptr to interpreter
    push eax
    push ebx
    push edx

    ; Create a new context for the function
    push eax
    push ebx
    mov eax, [ebx+HEAPFLOW_FUNCTION_CTX_OFFSET]
    call hashmap_copy
    mov edx, ebx
    pop ebx
    pop eax

    ; Add the args to the context
    push ebx
    push edx
    mov ebx, [HEAPFLOW_ARGS_HASH]
    mov eax, [eax+ARRAYLIST_DATA_OFFSET]
    xchg eax, edx
    call hashmap_put_data
    pop edx
    pop ebx

    ; Create a new interpreter for the function
    ; edx already contains the ctx from xchg above
    call heapflow_interpreter_new_with_ctx

    ; Call the function
    mov ebx, [ebx]
    call filestream_reset

    call heapflow_parse_filestream

    ; Free the interpreter
    call heapflow_interpreter_free

    pop edx
    pop ebx
    pop eax
    ret

heapflow_function_create_virtual_file: ; eax: returns file descriptor, ecx: ptr to lines
    push ebx
    push ecx
    push esi
    push edi

    mov eax, ecx
    mov ebx, 0
    mov ecx, 4
    add ecx, [eax]

    .loop1:
        cmp ebx, [eax]
        je .loop1_done

        push ebx
        call arraylist_get

        push eax
        mov edi, ebx
        call str_len
        add ecx, eax
        pop eax

        pop ebx

        inc ebx
        jmp .loop1

    .loop1_done:

    push eax
    mov eax, ecx
    call malloc
    mov edi, eax
    pop eax

    push edi

    mov [edi], ecx
    add edi, 4

    mov ebx, 0

    .loop2:
        cmp ebx, [eax]
        je .loop2_done

        push ebx
        call arraylist_get

        call str_len_gr
        mov esi, ebx

        cld
        rep movsb

        mov [edi], byte 0xA
        inc edi

        pop ebx

        inc ebx
        jmp .loop2

    .loop2_done:

    call arraylist_deep_free

    mov [edi-1], byte 0

    pop edi

    mov eax, edi

    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

heapflow_function_free: ; ebx: ptr to function
    push eax

    mov eax, [ebx]

    push eax
    mov eax, [eax+FILESTREAM_START_OFFSET]
    sub eax, 4
    call free
    pop eax

    call free

    mov eax, [ebx+HEAPFLOW_FUNCTION_CTX_OFFSET]
    call hashmap_free

    mov eax, ebx
    call free

    pop eax
    ret


HEAPFLOW_FUNCTION_LENGTH equ 4 + 4 ; (lines + ctx)
HEAPFLOW_FUNCTION_CTX_OFFSET equ 4
