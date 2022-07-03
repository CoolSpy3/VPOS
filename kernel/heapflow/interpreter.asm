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

heapflow_interpreter_free: ; edx: ptr
    push eax

    mov eax, [edx]
    call free

    mov eax, [edx+HEAPFLOW_INTERPRETER_LOCAL_LIST_OFFSET]
    call free

    mov eax, [edx+HEAPFLOW_INTERPRETER_LOCAL_FUNCTION_LIST_OFFSET]
    call free

    mov eax, edx
    call free

    ret

heapflow_main:
    call parsehf_file_data

parsehf_file_data: ;esi: file data pointer ; eax: arraylist pointer
    push bx

    mov bl, byte 0x0a
    call split_string

    
    pop bx
    ret
    

heapflow_parse_stream: ; ebx: ptr to getLine function, ecx: returns flags
    push eax
    push ebx
    push edx

    call heapflow_interpreter_new

    .loop:
        call ebx
        cmp [eax], byte 0
        je .done

        call heapflow_parse_line
        jecxz .done
        jmp .loop

    .done:

    mov eax, [edx+HEAPFLOW_INTERPRETER_LOCAL_LIST_OFFSET]
    mov ebx, [eax]

    .local_free_loop:
        cmp ebx, 0
        je .local_free_loop_done
        push eax
        push ebx
        call arraylist_get
        mov eax, ebx
        call free
        pop ebx
        pop eax
        jmp .local_free_loop

    .local_free_loop_done:

    mov eax, [edx+HEAPFLOW_INTERPRETER_LOCAL_LIST_OFFSET]
    mov ebx, [eax]

    .local_free_function_loop:
        cmp ebx, 0
        je .local_free_function_loop_done
        push eax
        push ebx
        call arraylist_get
        mov eax, ebx
        call heapflow_function_free
        pop ebx
        pop eax
        jmp .local_free_function_loop

    .local_free_function_loop_done:

    call heapflow_interpreter_free

    pop edx
    pop ebx
    pop eax
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
            in al, dx
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

        call free_ebx

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

        call free_ebx

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

        call free_ebx

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

        call free_ebx

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

        call free_ebx

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

        push eax
        mov eax, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]
        call free
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

        .jmp_loop:
            call heapflow_resolve_argument
            push eax
            mov eax, ecx
            call arraylist_add
            pop eax

            cmp [eax], byte 0
            jne .jmp_loop

        .skip_loop:

        push eax
        mov eax, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]
        call heapflow_resolve_argument_i
        pop eax

        push eax
        mov eax, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]
        call free
        pop eax

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

        push eax
        mov eax, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]
        call free
        pop eax

        .while_loop:
            push eax
            push ebx
            call heapflow_resolve_argument
            cmp ebx, 0
            pop ebx
            pop eax
            je .done_with_flags

            call heapflow_function_call

            jmp .while_loop

    .in:
        call free_esi
        inc eax

        mov ebx, [edx+HEAPFLOW_INTERPRETER_CACHE_OFFSET]

        push bx
        call heapflow_resolve_argument
        mov eax, [edx]
        mov dx, bx
        push eax
        in al, dx
        mov edx, 0
        mov dl, al
        pop eax
        pop bx

        call hashmap_put

        call free_ebx

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
    call heapflow_skip_spaces

    cmp [eax], byte '"'
    je .string

    cmp [eax], byte '{'
    je .array

    call heapflow_resolve_argument
    push eax
    mov eax, 4
    call malloc
    mov [eax], ebx
    mov ebx, eax
    pop eax
    ret

    .string:
        inc eax

        push eax
        push edi
        mov edi, eax
        call str_len
        call malloc ; Malloc a buffer for temp string (this will always be larger than the string and is more efficient than arraylist)
        mov ebx, eax
        pop edi
        pop eax

        push ecx
        push ebx

        mov ecx, 0

        .string_loop:
            cmp [eax], byte '"'
            je .string_done

            cmp [eax], byte '\\'
            je .string_escape

            push dx
            mov dl, [eax]
            mov [ebx], dl
            pop dx

            inc eax
            inc ebx
            inc ecx

            jmp .string_loop

            .string_escape:
                inc eax
                inc ebx
                inc ecx

                cmp [eax], byte '\\'
                je .string_escape_backslash

                cmp [eax], byte '"'
                je .string_escape_string

                cmp [eax], byte 'n'
                je .string_escape_newline

                cmp [eax], byte 't'
                je .string_escape_tab

                cmp [eax], byte 'r'
                je .string_escape_carrage_return

                ; Unknown escape code :/

                mov [ebx-1], byte ' '
                jmp .string_loop

                .string_escape_backslash:
                    mov [ebx-1], byte '\\'
                    jmp .string_loop

                .string_escape_string:
                    mov [ebx-1], byte '"'
                    jmp .string_loop

                .string_escape_newline:
                    mov [ebx-1], byte '\n'
                    jmp .string_loop

                .string_escape_tab:
                    mov [ebx-1], byte '\t'
                    jmp .string_loop

                .string_escape_carrage_return:
                    mov [ebx-1], byte '\r'
                    jmp .string_loop

                jmp .string_loop

        .string_done:
        pop ebx

        push eax
        push esi
        push edi

        mov eax, ecx
        inc eax
        call malloc
        mov edi, eax
        mov esi, ebx
        mov ebx, edi
        push ecx
        rep movsb
        pop ecx
        push ebx
        add ebx, ecx
        mov [ebx], byte 0x00
        pop ebx

        pop edi
        pop esi
        pop eax

        inc eax
        pop ecx
        ret

    .array:
        inc eax

        push eax
        push ecx

        mov ecx, 0

        .array_element_count_loop:
            cmp [eax], byte ','
            je .array_element_count_inc

            cmp [eax], byte '}'
            je .array_element_count_loop_done

            inc eax
            jmp .array_element_count_loop

            .array_element_count_inc:
                inc eax
                inc ecx
                jmp .array_element_count_loop

        .array_element_count_loop_done:

        inc ecx
        mov eax, ecx
        shl eax, 2
        call malloc
        mov ebx, eax

        pop ecx
        pop eax

        push ebx

        .array_element_read_loop:
            call heapflow_skip_spaces
            cmp [eax], byte '}'
            je .array_done

            cmp [eax], byte ','
            jne .array_element_read

            inc eax

            .array_element_read:
            push ebx
            push ecx
            mov ecx, ebx
            call heapflow_resolve_argument
            mov [ecx], ebx
            pop ecx
            pop ebx

            add ebx, 4
            jmp .array_element_read_loop

        .array_done:
        pop ebx
        ret


heapflow_resolve_argument_f: ; eax: ptr to line (will be updated to point to n < ' '), ebx: ptr to getLine func, returns val, edx: ptr to interpreter
    ret

heapflow_resolve_argument_i: ; eax: ptr to line (will be updated to point to n < ' '), ebx: returns val, edx: ptr to interpreter
    ret

heapflow_skip_spaces: ; eax: ptr to line (will be updated to point to a non-space character)
    push edi
    mov edi, eax
    mov al, ' '
    repe scasb
    mov eax, edi
    pop edi
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

free_ebx: ; ebx: will be freed
    push eax
    mov eax, ebx
    call free
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
