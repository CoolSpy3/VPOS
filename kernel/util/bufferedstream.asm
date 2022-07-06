buffered_stream_new: ; eax: ptr to arraylist, ebx: returns ptr
    push eax
    mov eax, BUFFERED_STREAM_LENGTH
    call malloc
    mov ebx, eax
    pop eax

    mov [ebx], dword 0
    mov [ebx+BUFFERED_STREAM_LIST_OFFSET], eax

    ret

buffered_stream_get_next: ; eax: returns next line, ebx: ptr to stream
    push ebx
    push edx

    mov eax, 0

    mov edx, [ebx+BUFFERED_STREAM_LIST_OFFSET]
    mov edx, [edx]
    cmp [ebx], edx
    jae .done

    mov eax, [ebx+BUFFERED_STREAM_LIST_OFFSET]
    mov edx, ebx
    mov ebx, [ebx]
    call arraylist_get
    mov eax, ebx
    inc dword [edx]

    .done:

    pop edx
    pop ebx
    ret

buffered_stream_free: ; ebx: ptr to stream
    push eax
    mov eax, ebx
    call free
    pop eax
    ret


BUFFERED_STREAM_LENGTH equ 4 + 4 ; (pos + list)
BUFFERED_STREAM_LIST_OFFSET equ 4
