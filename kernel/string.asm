str_len: ; Put string addr in edi, length returned in eax
    push ecx
    mov al, 0
    mov ecx, -1
    cld
    repne scasb
    mov eax, -2
    sub eax, ecx
    pop ecx
    ret

substr: ; copies esi to a new string retuned in edi from [eax,ebx)
    push ecx
    
    pop ecx