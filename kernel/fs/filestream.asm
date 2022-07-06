filestream_new: ; eax: file descriptor, ebx: returns ptr
    push eax
    mov eax, FILESTREAM_LENGTH
    call malloc
    mov ebx, eax
    pop eax

    push edx
    mov edx, [eax]
    mov [ebx+FILESTREAM_LENGTH_OFFSET], edx
    mov edx, eax
    add edx, 4
    mov [ebx], edx
    mov [ebx+FILESTREAM_START_OFFSET], edx
    pop edx

    ret

filestream_read_line: ; eax: returns next line, ebx: ptr to stream
    push esi
    push edi
    push ecx

    mov eax, [ebx+FILESTREAM_LENGTH_OFFSET]
    add eax, [ebx+FILESTREAM_START_OFFSET]
    mov esi, [ebx]
    mov ecx, 0

    push esi
    .loop:
        cmp esi, eax
        jae .done
        cmp [esi], byte 0xA
        je .lf
        inc esi
        inc ecx
        jmp .loop

    .lf:
    inc dword [ebx]

    .done:
    pop esi

    add [ebx], ecx

    cmp ecx, 0
    je .null

    mov eax, 0
    call substr
    mov eax, edi

    .return:

    pop ecx
    pop edi
    pop esi
    ret

    .null:
    mov eax, 0
    jmp .return

filestream_reset: ; ebx: ptr to stream
    push edx

    mov edx, [ebx+FILESTREAM_START_OFFSET]
    mov [ebx], edx

    pop edx
    ret


FILESTREAM_LENGTH equ 4 + 4 + 4 ; (pos + len + start)
FILESTREAM_LENGTH_OFFSET equ 4
FILESTREAM_START_OFFSET equ 4 + 4
