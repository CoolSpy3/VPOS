; I couldn't find any way to check which drive was used to
; load the OS which worked reliably on QEMU and VirtualBox,
; so we'll just assume the selected master drive for all functions
ata_identify:
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
    mov cx, 256
    mov rsi, ata_identify_data

    mov dx, 0x1F0
    .read:
        in ax, dx
        mov [rsi], ax
        add rsi, 2
        dec cx
        jnz .read

    ret

    .error:
        mov rbx, .error_msg
        call panic_with_msg

    .error_msg: db "ATA: Invalid Drive", 0

ata_device_type: db 0
ata_identify_data:
    times 256 dw 0
