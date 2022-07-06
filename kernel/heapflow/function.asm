heapflow_function_new: ; ebx: returns ptr, ecx: ptr to lines, edx: ptr to ctx
    push eax

    mov eax, HEAPFLOW_FUNCTION_LENGTH
    call malloc

    mov [eax], ecx
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
    push esi
    push edx

    ; Create a new context for the function
    push eax
    push ebx
    mov eax, [ebx+HEAPFLOW_FUNCTION_CTX_OFFSET]
    call hashmap_copy
    mov eax, ebx
    pop ebx
    pop eax

    ; Add the args to the context
    push ebx
    push edx
    mov ebx, [HEAPFLOW_ARGS_HASH]
    mov edx, [eax+ARRAYLIST_DATA_OFFSET]
    call hashmap_put_data
    pop edx
    pop ebx

    ; Backup the interpreter state
    mov esi, edx
    push eax
    mov eax, HEAPFLOW_INTERPRETER_BKUP_LENGTH
    call malloc
    mov edi, eax
    pop eax
    mov ecx, HEAPFLOW_INTERPRETER_BKUP_LENGTH
    push esi
    push edi
    rep movsb
    pop edi
    pop esi

    mov eax, [ebx]
    call buffered_stream_new

    call heapflow_parse_bufferedstream
    call heapflow_interpreter_clean

    ; Restore the interpreter state
    push ecx
    mov ecx, HEAPFLOW_INTERPRETER_BKUP_LENGTH
    xchg esi, edi
    rep movsb
    pop ecx

    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    ret

heapflow_function_free: ; ebx: ptr to function
    push eax

    mov eax, [ebx]
    call arraylist_deep_free

    mov eax, [ebx+HEAPFLOW_FUNCTION_CTX_OFFSET]
    call hashmap_free

    mov eax, ebx
    call free

    pop eax
    ret


HEAPFLOW_FUNCTION_LENGTH equ 4 + 4 ; (lines + ctx)
HEAPFLOW_FUNCTION_CTX_OFFSET equ 4
HEAPFLOW_INTERPRETER_BKUP_LENGTH equ 4 + 4 + 4 + 4 ; (context + local ptrs + local functions + return cache + general cache)
HEAPFLOW_INTERPRETER_BKUP_LOCAL_LIST_OFFSET equ 4
HEAPFLOW_INTERPRETER_BKUP_LOCAL_FUNCTION_LIST_OFFSET equ 4 + 4
HEAPFLOW_INTERPRETER_BKUP_CACHE_OFFSET equ 4 + 4 + 4
