feature_check:
    ; CPUID check from https://wiki.osdev.org/Setting_Up_Long_Mode#Detection_of_CPUID
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 0x00200000
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    xor eax, ecx
    jz .cpuid_error

    .ignore_cpuid:

    mov eax, 0
    cpuid

    cmp ebx, "Genu" ; This check will fail on QEMU because it uses "AuthenticAMD"
    jne .genuine_intel_error
    cmp edx, "ineI"
    jne .genuine_intel_error
    cmp ecx, "ntel"
    jne .genuine_intel_error
    .ignore_genuine_intel:

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

    test edx, 0x00030048 ; PSE, PAE, PAT, and PSE36
    jz .paging_error
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
    featureError genuine_intel, {"Error! CPU is not GenuineIntel!"}
    featureError valid_leaves, {"Error! CPU does not support all CPUID leaves!"}
    featureError long_mode, {"Error! CPU does not support long mode!"}
    featureError msr, {"Error! CPU does not support Model Specific Registers!"}
    featureError paging, {"Error! CPU does not support all paging features!"}
    featureError apic, {"Error! CPU does not support APIC!"}

IGNORE_INFO db "Press any key to ignore...", 0xA, 0xD, 0
