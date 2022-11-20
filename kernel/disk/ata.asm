; I couldn't find any way to check which drive was used to
; load the OS which worked reliably on QEMU and VirtualBox,
; so we'll just assume the selected master drive for all functions
ata_identify:
    push rax
    push rcx
    push rdx
    push rdi

    ; Execute IDENTIFY command
    mov al, 0xA0
    mov dx, 0x1F6
    out dx, al
    xor al, al
    mov dx, 0x1F2
    out dx, al
    mov dx, 0x1F3
    out dx, al
    mov dx, 0x1F4
    out dx, al
    mov dx, 0x1F5
    out dx, al
    mov al, 0xE
    mov dx, 0x1F7
    out dx, al
    in al, dx

    cmp al, 0
    jz .error ; Drive does not exist

    ; Wait for drive to be ready
    .wait:
        in al, dx
        test al, 0x80
        jnz .wait

    mov dx, 0x1F4
    in al, dx
    cmp al, 0
    jnz .error ; Drive is not ATA
    mov dx, 0x1F5
    in al, dx
    cmp al, 0
    jnz .error ; Drive is not ATA

    mov dx, 0x1F7
    .wait2:
        in al, dx
        test al, 0x8 | 0x1
        jz .wait2

    test al, 0x1
    jz .read_data

    ; Drive returned error (some devices are supposed to do this)
    mov dx, 0x1F1
    in al, dx
    cmp al, 0x4
    jne .error ; Drive did not abort command (This shouldn't happen)

    %macro check_device_type 3

        mov dx, 0x1F4
        in al, dx
        cmp al, %1
        jne %%not_this_device
        mov dx, 0x1F5
        in al, dx
        cmp al, %2
        jne %%not_this_device
        mov [ata_device_type], byte %3

        jmp .valid_device

        %%not_this_device:

    %endmacro

    check_device_type 0x00, 0x00, 0x1 ; ATA
    check_device_type 0x14, 0xEB, 0x2 ; ATAPI
    check_device_type 0x3C, 0xC3, 0x3 ; SATA
    check_device_type 0x69, 0x96, 0x3 ; SATA
    check_device_type 0xCE, 0xAA, 0x4 ; Unknown

    jmp .error ; Drive is not one of the valid drive types

    .valid_device:

    %unmacro check_device_type 3

    .read_data:

    ; Read IDENTIFY data
    mov rcx, 256
    mov rdi, ata_identify_data

    mov dx, 0x1F0
    rep insw

    pop rdi
    pop rdx
    pop rcx
    pop rax
    ret

    .error:
        mov rbx, .error_msg
        jmp panic_with_msg

    .error_msg: db "ATA: Invalid Drive", 0

ata_read: ; esi = lba, edi = buffer, ecx = count
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    ; Enable LBA mode
    mov dx, 0x1F6
    in al, dx
    or al, 0x40
    out dx, al

    test [ata_identify_data+(2*83)], word 0x400 ; Check if LBA48 is supported
    jnz .lba48

    .lba28:
        mov rax, rsi ; Send drive select and high bits of LBA
        shr rax, 24
        and rax, 0xF
        or al, 0xE0
        mov dx, 0x1F6
        out dx, al

        mov rax, rcx ; Send sector count
        mov dx, 0x1F2
        out dx, al

        mov rax, rsi ; Send low bits of LBA
        mov dx, 0x1F3
        out dx, al
        shr rax, 8
        mov dx, 0x1F4
        out dx, al
        shr rax, 8
        mov dx, 0x1F5
        out dx, al

        mov al, 0x20 ; Send READ SECTORS command
        mov dx, 0x1F7
        out dx, al

        jmp .wait_and_read


    .lba48:
        mov al, 0x40 ; Select drive
        mov dx, 0x1F6
        out dx, al

        mov rax, rcx ; Send sector count
        mov dx, 0x1F2
        out dx, ax

        mov rax, rsi ; Send LBA
        mov dx, 0x1F3
        out dx, ax
        shr rax, 16
        mov dx, 0x1F4
        out dx, ax
        shr rax, 16
        mov dx, 0x1F5
        out dx, ax

        mov al, 0x24 ; Send READ SECTORS EXT command
        mov dx, 0x1F7
        out dx, al

    .wait_and_read:
        mov rbx, rcx
        .loop:
            mov dx, 0x1F7

            in al, dx ; Wait for drive to be ready (400 ns delay)
            in al, dx
            in al, dx
            in al, dx

            .wait:
                in al, dx
                test al, 0x1
                jz .error
                test al, 0x80
                jnz .wait
                test al, 0x8
                jz .wait

            mov dx, 0x1F0

            mov rcx, 256
            rep insw

            dec rbx
            jnz .loop

    .done:
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

    .error:
        stc
        jmp .done


ata_device_type: db 0
ata_identify_data:
    times 256 dw 0
