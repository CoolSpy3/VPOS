heapflow_interpreter_new: ; edx: returns ptr
    push eax

    mov eax, HEAPFLOW_INTERPRETER_LENGTH
    call malloc
    mov edx, eax

    call hashmap_new
    mov [edx], eax

    call arraylist_new
    mov [edx+HEAPFLOW_INTERPRETER_LOCAL_LIST_OFFSET], eax

    call arraylist_new
    mov [edx+HEAPFLOW_INTERPRETER_LOCAL_FUNCTION_LIST_OFFSET], eax

    mov [edx+HEAPFLOW_INTERPRETER_RETURN_OFFSET], dword 0

    pop eax
    ret

heapflow_main:
    call parsehf_file_data

parsehf_file_data: ;esi: file data pointer ; eax: arraylist pointer
    push bx

    mov bl, byte 0x0a
    call split_string

    
    pop bx
    ret
    

heapflow_parse_stream: ; ebx: ptr to getLine function, ecx: returns flags, edx: ptr to interpreter
    call ebx
    cmp [eax], byte 0
    je .done

    call heapflow_parse_line
    cmp ecx, 0
    jne .done
    jmp heapflow_parse_stream

    .done:
    ret

heapflow_parse_line: ; eax: ptr to line, ebx: ptr to getLine function, ecx: returns flags, edx: ptr to interpreter
    push eax
    push ebx
    push edx
    push esi
    push edi

    call trim_string

    cld

    cmp [eax], byte ';'
    je .done

    push ebx

    call heapflow_read_until_space

    mov esi, ebx
    call str_len_gr ; Sets ecx

    pop ebx

    mov edi, HEAPFLOW_RETURN
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .return

    mov edi, HEAPFLOW_INT
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .int

    mov edi, HEAPFLOW_DEL
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .del

    mov edi, HEAPFLOW_DELF
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .delf

    mov edi, HEAPFLOW_BREAK
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .break

    mov edi, HEAPFLOW_CONTINUE
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .continue

    mov edi, HEAPFLOW_OUT
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .out

    mov [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET], esi ; The first argument is likely a label name. We need more registers to parse the rest of the line, so just cache it for now

    inc eax

    push ebx

    call heapflow_read_until_space

    mov esi, ebx
    call str_len_gr ; Sets ecx

    pop ebx

    mov edi, HEAPFLOW_EQU
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .equ

    mov edi, HEAPFLOW_PT
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .pt

    mov edi, HEAPFLOW_PTF
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .ptf

    mov edi, HEAPFLOW_LPT
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .lpt

    mov edi, HEAPFLOW_LPTF
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .lptf

    mov edi, HEAPFLOW_IF
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .if

    mov edi, HEAPFLOW_JMP
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .jmp

    mov edi, HEAPFLOW_WHILE
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .while

    mov edi, HEAPFLOW_IN
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .in

    ; Unknown Command!

    call free_esi
    mov esi, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]
    call free_esi
    mov ecx, HEAPFLOW_ERROR_FLAG
    jmp .done_with_flags

    .done:
    mov ecx, 0
    .done_with_flags:
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    ret

    ; Heapflow instructions

    ; First-word instructions

    .return:
        call free_esi

        cmp [eax], byte 0
        je .return_null
        inc eax

        push ebx

        call heapflow_read_until_space

        mov esi, ebx
        call str_len_gr ; Sets ecx

        pop ebx

        mov edi, HEAPFLOW_EQU
        push esi
        push ecx
        repe cmpsb
        pop ecx
        pop esi
        je .return_equ

        mov edi, HEAPFLOW_PT
        push esi
        push ecx
        repe cmpsb
        pop ecx
        pop esi
        je .return_pt

        mov edi, HEAPFLOW_PTF
        push esi
        push ecx
        repe cmpsb
        pop ecx
        pop esi
        je .return_ptf

        mov edi, HEAPFLOW_IN
        push esi
        push ecx
        repe cmpsb
        pop ecx
        pop esi
        je .return_in

        ; Unknown command!

        call free_esi
        mov ecx, HEAPFLOW_ERROR_FLAG
        jmp .done_with_flags

        .return_equ:
            call free_esi
            inc eax
            call heapflow_resolve_argument
            jmp .return_val

        .return_pt:
            call free_esi
            inc eax
            call heapflow_resolve_argument_p
            jmp .return_val

        .return_ptf:
            call free_esi
            inc eax
            call heapflow_resolve_argument_f
            jmp .return_val

        .return_in:
            call free_esi
            inc eax

            call heapflow_resolve_argument
            mov dx, bx
            in dx, al
            mov ebx, 0
            mov bl, al

        .return_val:

        mov [edx+HEAPFLOW_INTERPRETER_RETURN_OFFSET], ebx

        .return_null:

        mov ecx, HEAPFLOW_RETURN_FLAG
        jmp .done_with_flags

    .int:
        call free_esi
        inc eax

        ; This instruction is currently unsupported, so (for now) just give an error
        mov ecx, HEAPFLOW_ERROR_FLAG
        jmp .done_with_flags

        push eax ; Allocate a buffer for register operands in edi
        mov eax, 16
        call malloc
        mov edi, eax
        mov al, 0
        mov ecx, 4
        push edi
        rep stosd
        pop edi
        pop eax

        call heapflow_resolve_argument
        cmp eax, byte 0

        ; int bl

        mov eax, edi
        call free

        jmp .done

    .del:
        call free_esi
        inc eax

        call heapflow_resolve_argument
        mov eax, ebx
        call free

        jmp .done

    .delf:
        call free_esi
        inc eax

        call heapflow_resolve_argument
        mov eax, ebx
        call heapflow_function_free

        jmp .done

    .break:
        call free_esi
        inc eax

        mov ecx, HEAPFLOW_BREAK_FLAG

        jmp .done_with_flags

    .continue:
        call free_esi
        inc eax

        mov ecx, HEAPFLOW_CONTINUE_FLAG

        jmp .done_with_flags

    .out:
        call free_esi
        inc eax

        call heapflow_resolve_argument
        mov dx, bx
        inc eax
        call heapflow_resolve_argument
        mov al, bl

        out dx, al

        jmp .done

    ; Second-word instructions
    .equ:
        call free_esi
        inc eax

        mov ebx, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]

        push ebx
        call heapflow_resolve_argument
        mov eax, [edx]
        mov edx, ebx
        pop ebx

        call hashmap_put

        jmp .done

    .pt:
        call free_esi
        inc eax

        mov ebx, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]

        push ebx
        call heapflow_resolve_argument_p
        mov eax, [edx]
        mov edx, ebx
        pop ebx

        call hashmap_put

        jmp .done

    .ptf:
        call free_esi
        inc eax

        mov ebx, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]

        push ebx
        call heapflow_resolve_argument_f
        mov eax, [edx]
        mov edx, ebx
        pop ebx

        call hashmap_put

        jmp .done

    .lpt:
        call free_esi
        inc eax

        mov ebx, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]

        push edx

        push ebx
        call heapflow_resolve_argument_p
        mov eax, [edx]
        mov edx, ebx
        pop ebx

        call hashmap_put

        mov ebx, edx

        pop edx

        mov eax, [edx+HEAPFLOW_INTERPRETER_LOCAL_LIST_OFFSET]

        call arraylist_add

        jmp .done

    .lptf:
        call free_esi
        inc eax

        mov ebx, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]

        push edx

        push ebx
        call heapflow_resolve_argument_f
        mov eax, [edx]
        mov edx, ebx
        pop ebx

        call hashmap_put

        mov ebx, edx

        pop edx

        mov eax, [edx+HEAPFLOW_INTERPRETER_LOCAL_FUNCTION_LIST_OFFSET]

        call arraylist_add

        jmp .done

    .if:
        call free_esi
        inc eax

        push eax
        mov eax, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]
        call heapflow_resolve_argument_i
        pop eax

        push ebx
        call heapflow_resolve_argument
        cmp ebx, 0
        pop ebx
        je .if_skip_call

        call heapflow_function_call

        .if_skip_call:

        jmp .done_with_flags

    .jmp:
        call free_esi
        inc eax

        push eax
        call arraylist_new
        mov ecx, eax
        pop eax

        cmp [eax], byte 0
        je .skip_loop

        .loop:
            call heapflow_resolve_argument
            push eax
            mov eax, ecx
            call arraylist_add
            pop eax

            cmp [eax], byte 0
            jne .loop

        .skip_loop:

        mov ebx, [edx]
        mov edx, ecx

        call heapflow_function_call_with_params

        mov eax, edx
        call free

        jmp .done_with_flags

    .while:
        call free_esi
        inc eax

        push eax
        mov eax, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]
        call heapflow_resolve_argument_i
        pop eax

        .loop:
            push eax
            push ebx
            call heapflow_resolve_argument
            cmp ebx, 0
            pop ebx
            pop eax
            je .done_with_flags

            call heapflow_function_call

            jmp .loop

    .in:
        call free_esi
        inc eax

        mov ebx, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]

        push bx
        call heapflow_resolve_argument
        mov eax, [edx]
        mov dx, bx
        push eax
        in dx, al
        mov edx, 0
        mov dl, al
        pop eax
        pop bx

        call hashmap_put

        jmp .done

heapflow_read_until_space: ; eax: ptr to line (will be updated to point to n < ' '), ebx: returns ptr to string
    push esi
    push edi
    push ecx

    mov esi, eax
    mov ecx, 0

    cmp [eax], byte ' '
    jbe .skip_loop

    .loop:
        inc edi
        inc ecx
        cmp [eax], byte ' '
        ja .loop

    .skip_loop:

    push eax
    mov eax, 0
    call substr
    mov ebx, edi
    pop eax

    pop ecx
    pop edi
    pop esi
    ret

heapflow_resolve_argument: ; eax: ptr to line (will be updated to point to n < ' '), ebx: returns val, edx: ptr to interpreter
    ret

heapflow_resolve_argument_p: ; eax: ptr to line (will be updated to point to n < ' '), ebx: returns val, edx: ptr to interpreter
    ret

heapflow_resolve_argument_f: ; eax: ptr to line (will be updated to point to n < ' '), ebx: ptr to getLine func, returns val, edx: ptr to interpreter
    ret

heapflow_resolve_argument_i: ; eax: ptr to line (will be updated to point to n < ' '), ebx: returns val, edx: ptr to interpreter
    ret

str_len_gr: ; Put string addr in ebx, length returned in ecx
    push eax
    push edi

    mov edi, ebx
    call str_len
    mov ecx, eax

    pop edi
    pop eax
    ret

free_esi: ; esi: will be freed
    push eax
    mov eax, esi
    call free
    pop eax
    ret

HEAPFLOW_INTERPRETER_LENGTH equ 4 + 4 + 4 + 4 + 4 ; (context + local ptrs + local functions + return cache + general cache)
HEAPFLOW_INTERPRETER_LOCAL_LIST_OFFSET equ 4
HEAPFLOW_INTERPRETER_LOCAL_FUNCTION_LIST_OFFSET equ 4 + 4
HEAPFLOW_INTERPRETER_RETURN_OFFSET equ 4 + 4 + 4
HEAPFLOW_INTERPRETER_CACHE_OFFSET equ 4 + 4 + 4 + 4
