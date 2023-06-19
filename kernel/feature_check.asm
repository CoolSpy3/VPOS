%ifndef KERNEL_FEATURE_CHECK
%define KERNEL_FEATURE_CHECK

%include "common/rm_print.asm"
%include "kernel/kernel.asm"

[bits 16]

%include "common/system_constants.asm"

%define MAX_REQUIRED_BASIC_CPUID_LEAF FEATURE_INFO_CPUID_LEAF
%define MAX_REQUIRED_EXTENDED_CPUID_LEAF EXTENDED_FEATURE_INFO_CPUID_LEAF

feature_check:
    ; Check if CPUID is supported
    ; CPUID check from https://wiki.osdev.org/Setting_Up_Long_Mode#Detection_of_CPUID
    pushfd ; Store EFLAGS in EAX
    pop eax
    mov ecx, eax ; Copy EFLAGS to ECX
    xor eax, EFLAGS_ID_BIT ; SET bit 21 (ID bit)
    push eax
    popfd ; Load EFLAGS with new value
    pushfd
    pop eax ; Store new EFLAGS in EAX
    push ecx
    popfd ; Load original EFLAGS
    xor eax, ecx ; Check if bit 21 was updated
    jz .cpuid_error

    .ignore_cpuid:

    mov eax, BASIC_CPUID_LEAF
    cpuid

    %macro supportCPU 3
        cmp ebx, %1
        jne %%not_this_cpu
        cmp edx, %2
        jne %%not_this_cpu
        cmp ecx, %3
        jne %%not_this_cpu
        jmp .ignore_cpu_unsupported ; The CPU is supported, but this label is used to skip the remaining checks. The name is used to match the macro convention.
        %%not_this_cpu:
    %endmacro

    supportCPU {"Genu"}, {"ineI"}, {"ntel"} ; Check if CPU is Intel
    supportCPU {"Auth"}, {"enti"}, {"cAMD"} ; Check if CPU is AMD

    jmp .cpu_unsupported_error ; CPU is not supported
    .ignore_cpu_unsupported:

    %unmacro supportCPU 3

    cmp eax, MAX_REQUIRED_BASIC_CPUID_LEAF
    jb .valid_leaves_error

    mov eax, EXTENDED_INFO_CPUID_LEAF
    cpuid
    cmp eax, MAX_REQUIRED_EXTENDED_CPUID_LEAF
    jb .valid_leaves_error
    .ignore_valid_leaves:


    mov eax, EXTENDED_FEATURE_INFO_CPUID_LEAF
    cpuid
    test edx, HAS_LONG_MODE
    jz .long_mode_error
    .ignore_long_mode:

    test edx, HAS_EXECUTE_DISABLE
    jz .xd_error
    .ignore_xd:

    mov eax, FEATURE_INFO_CPUID_LEAF
    cpuid

    test edx, MSR_SUPPORT_BIT ; Check if CPU supports MSRs
    jz .msr_error
    .ignore_msr:

    test edx, CMOV_SUPPORT_BIT ; Check if CPU supports CMOV instructions
    jz .cmov_error
    .ignore_cmov:

    push edx
    and edx, PSE_SUPPORT_BIT | PAE_SUPPORT_BIT | PAT_SUPPORT_BIT | PSE36_SUPPORT_BIT
    cmp edx, PSE_SUPPORT_BIT | PAE_SUPPORT_BIT | PAT_SUPPORT_BIT | PSE36_SUPPORT_BIT
    pop edx
    jne .paging_error
    .ignore_paging:

    test edx, APIC_SUPPORT_BIT
    jz .apic_error
    ; test ecx, X2APIC_SUPPORT_BIT ; x2APIC
    ; jz .apic_not_supported_error
    .ignore_apic:

    ret

    %macro featureError 2
        .%1_error:
            mov si, .%1_error_msg
            call handle_error
            jmp .ignore_%1

        .%1_error_msg db %2, `\n\r`, 0
    %endmacro

    featureError cpuid, {"Error! CPU does not support CPUID!"}
    featureError cpu_unsupported, {"Error! CPU is unsupported!"}
    featureError valid_leaves, {"Error! CPU does not support all CPUID leaves!"}
    featureError long_mode, {"Error! CPU does not support long mode!"}
    featureError xd, {"Error! CPU does not support Execute Disable bit!"}
    featureError msr, {"Error! CPU does not support Model Specific Registers!"}
    featureError cmov, {"Error! CPU does not support CMOV instructions!"}
    featureError paging, {"Error! CPU does not support all paging features!"}
    featureError apic, {"Error! CPU does not support APIC!"}

    %unmacro featureError 2

    handle_error:
        sti ; Enable interrupts to read keyboard
        call rm_print ; Print error message
        call rm_dump_regs ; Dump registers
        mov si, IGNORE_INFO ; Print ignore info message
        call rm_print
        xor ah, ah ; Wait for keypress
        int 0x16
        cli ; Re-disable interrupts
        ret ; Return to feature_check

%endif
