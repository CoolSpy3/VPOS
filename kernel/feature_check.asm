feature_check:
    mov eax, 0
    cpuid

    cmp ebx, 0x756e6547
    jne .genuine_intel_error
    cmp ecx, 0x6c65746e
    jne .genuine_intel_error
    cmp edx, 0x49656e69
    jne .genuine_intel_error

    cmp eax, 0x0
    jb .valid_leaves_error

    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000008
    jb .valid_leaves_error

    ret

    .genuine_intel_error:
        mov si, GENUINE_INTEL_ERROR
        call rm_print
        jmp $

    .valid_leaves_error:
        mov si, VALID_LEAVES_ERROR
        call rm_print
        jmp $

GENUINE_INTEL_ERROR db "Error! CPU is not Genuine Intel!", 0
VALID_LEAVES_ERROR db "Error! CPU does not support all CPUID leaves!", 0
