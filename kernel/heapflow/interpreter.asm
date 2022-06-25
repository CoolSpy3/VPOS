
heapflow_main:
    call parsehf_file_data

parsehf_file_data: ;esi: file data pointer ; eax: arraylist pointer
    push edi

    mov edi, byte 0x0a
    call split_string

    
    pop edi
    ret
    