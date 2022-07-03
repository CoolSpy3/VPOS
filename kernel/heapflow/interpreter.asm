
heapflow_main:
    call parsehf_file_data

parsehf_file_data: ;esi: file data pointer ; eax: arraylist pointer
    push bx

    mov bl, byte 0x0a
    call split_string

    
    pop bx
    ret
    

heapflow_parse_stream: ; ebx: ptr to getLine function
    call ebx
    cmp [eax], byte 0
    je .done

    call heapflow_parse_line
    jmp heapflow_parse_stream

    .done:
    ret

heapflow_parse_line: ; eax: ptr to line, ebx: ptr to getLine function
    pushad

    call heapflow_read_until_space
    inc eax

    cld

    mov esi, eax
    call str_len_gr ; Sets ecx

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

    mov edi, HEAPFLOW_IN
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .in

    mov edi, HEAPFLOW_OUT
    push esi
    push ecx
    repe cmpsb
    pop ecx
    pop esi
    je .out

    jmp panic

    .done:
    popad
    ret

    ; Heapflow commands
    .return:
        call free_esi
        inc eax



        jmp .done

    .int:
        call free_esi
        inc eax



        jmp .done

    .del:
        call free_esi
        inc eax



        jmp .done

    .delf:
        call free_esi
        inc eax



        jmp .done

    .break:
        call free_esi
        inc eax



        jmp .done

    .continue:
        call free_esi
        inc eax



        jmp .done

    .in:
        call free_esi
        inc eax



        jmp .done

    .out:
        call free_esi
        inc eax



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

heapflow_resolve_argument: ; eax: ptr to line, ebx: returns val
    ret

free_esi: ; esi: will be freed
    push eax
    mov eax, esi
    call free
    pop eax
    ret