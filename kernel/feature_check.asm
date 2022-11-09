feature_check:
    ; CPUID check from https://wiki.osdev.org/Setting_Up_Long_Mode#Detection_of_CPUID
    pushfd ; Store EFLAGS in EAX
    pop eax
    mov ecx, eax ; Copy EFLAGS to ECX
    xor eax, 0x00200000 ; SET bit 21 (ID bit)
    push eax
    popfd ; Load EFLAGS with new value
    pushfd
    pop eax ; Store new EFLAGS in EAX
    push ecx
    popfd ; Load original EFLAGS
    xor eax, ecx ; Check if bit 21 was updated
    jz .cpuid_error

    .ignore_cpuid:

    mov eax, 0
    cpuid

    cmp ebx, "Genu"
    jne .not_intel
    cmp edx, "ineI"
    jne .not_intel
    cmp ecx, "ntel"
    jne .not_intel
    jmp .ignore_cpu_unsupported

    .not_intel:
    cmp ebx, "Auth"
    jne .cpu_unsupported_error
    cmp edx, "enti"
    jne .cpu_unsupported_error
    cmp ecx, "cAMD"
    jne .cpu_unsupported_error

    .ignore_cpu_unsupported:

    cmp eax, 0x01
    jb .valid_leaves_error

    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000008
    jb .valid_leaves_error
    .ignore_valid_leaves:


    mov eax, 0x80000001
    cpuid
    test edx, 0x20000000
    jz .long_mode_error
    .ignore_long_mode:

    mov eax, 0x1
    cpuid

    test edx, 0x00000020
    jz .msr_error
    .ignore_msr:

    test edx, 0x00008000
    jz .cmov_error
    .ignore_cmov:

    test edx, 0x00000008 ; PSE
    jz .paging_error
    test edx, 0x00010040 ; PAE
    jz .paging_error
    test edx, 0x00010000 ; PAT
    jz .paging_error
    test edx, 0x00020000 ; PSE36
    .ignore_paging:

    test edx, 0x0000200
    jz .apic_error
    ; test ecx, 0x00200000 ; x2APIC
    ; jz .apic_not_supported_error
    .ignore_apic:

    ret

    %macro featureError 2
        .%1_error:
            mov si, .%1_error_msg
            call rm_print
            call rm_dump_regs
            mov si, IGNORE_INFO
            call rm_print
            xor ah, ah
            int 0x16
            jmp .ignore_%1

        .%1_error_msg db %2, 0xA, 0xD, 0
    %endmacro

    featureError cpuid, {"Error! CPU does not support CPUID!"}
    featureError cpu_unsupported, {"Error! CPU is unsupported!"}
    featureError valid_leaves, {"Error! CPU does not support all CPUID leaves!"}
    featureError long_mode, {"Error! CPU does not support long mode!"}
    featureError msr, {"Error! CPU does not support Model Specific Registers!"}
    featureError cmov, {"Error! CPU does not support CMOV instructions!"}
    featureError paging, {"Error! CPU does not support all paging features!"}
    featureError apic, {"Error! CPU does not support APIC!"}

    %unmacro featureError 2

IGNORE_INFO db "Press any key to ignore...", 0xA, 0xD, 0
