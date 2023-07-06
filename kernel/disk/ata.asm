%ifndef KERNEL_DISK_ATA
%define KERNEL_DISK_ATA

[bits 64]

%include "common/system_constants.asm"
%include "kernel/util/panic.asm"

%define ATA_SELECTED_DRIVE    ATA_MASTER_DRIVE

%define ATA_DRIVE_TYPE_ATA    0x1
%define ATA_DRIVE_TYPE_ATAPI  0x2
%define ATA_DRIVE_TYPE_SATA   0x3
%define ATA_DRIVE_TYPE_SATAPI 0x4

%if ATA_SELECTED_DRIVE == ATA_MASTER_DRIVE ; Calculate the value that should be written to the drive select port
    %define ATA_IO_PORT_DRIVE_SELECT_VALUE ATA_DRIVE_SELECT_LBA
%else
    %define ATA_IO_PORT_DRIVE_SELECT_VALUE ATA_DRIVE_SELECT_LBA | ATA_DRIVE_SELECT_DRV
%endif

; I couldn't find any way to check which drive was used to
; load the OS which worked reliably on QEMU and VirtualBox,
; so we'll just assume the selected master drive for all functions
ata_identify:
    push rax
    push rcx
    push rdx
    push rdi

    ; Execute IDENTIFY command
    mov al, ATA_SELECTED_DRIVE
    mov dx, ATA_IO_PORT_DRIVE_SELECT
    out dx, al
    xor al, al
    mov dx, ATA_IO_PORT_SECTOR_COUNT
    out dx, al
    mov dx, ATA_IO_PORT_LBA_LOW
    out dx, al
    mov dx, ATA_IO_PORT_LBA_MID
    out dx, al
    mov dx, ATA_IO_PORT_LBA_HIGH
    out dx, al
    mov al, ATA_COMMAND_IDENTIFY
    mov dx, ATA_IO_PORT_COMMAND
    out dx, al
    in  al, dx

    cmp al, 0
    jz  .error ; Drive does not exist

    ; Wait for drive to be ready
    mov dx, ATA_IO_PORT_STATUS
    .wait:
        in   al, dx
        test al, ATA_STATUS_BSY
        jnz  .wait

    mov dx, ATA_IO_PORT_LBA_MID
    in  al, dx
    cmp al, 0
    jnz .error                   ; Drive is not ATA
    mov dx, ATA_IO_PORT_LBA_HIGH
    in  al, dx
    cmp al, 0
    jnz .error                   ; Drive is not ATA

    mov dx, ATA_IO_PORT_STATUS
    .wait2:
        in   al, dx
        test al, ATA_STATUS_DRQ | ATA_STATUS_ERR
        jz   .wait2

    test al, ATA_STATUS_ERR
    jz   .read_data

    ; Drive returned error (some devices are supposed to do this)
    mov dx, ATA_IO_PORT_ERROR
    in  al, dx
    cmp al, ATA_ERROR_ABRT
    jne .error                ; Drive did not abort command (This shouldn't happen)

    %macro check_device_type 3 ; %1 = expected LBA_MID, %2 = expected LBA_HIGH, %3 = device type

        mov dx,                ATA_IO_PORT_LBA_MID
        in  al,                dx
        cmp al,                %1
        jne %%not_this_device
        mov dx,                ATA_IO_PORT_LBA_HIGH
        in  al,                dx
        cmp al,                %2
        jne %%not_this_device
        mov [ata_device_type], byte %3

        jmp .valid_device

        %%not_this_device:

    %endmacro

    check_device_type    ATA_DRIVE_LBA_MID_SIGNATURE,    ATA_DRIVE_LBA_HIGH_SIGNATURE, ATA_DRIVE_TYPE_ATA
    check_device_type  ATAPI_DRIVE_LBA_MID_SIGNATURE,  ATAPI_DRIVE_LBA_HIGH_SIGNATURE, ATA_DRIVE_TYPE_ATAPI
    check_device_type   SATA_DRIVE_LBA_MID_SIGNATURE,   SATA_DRIVE_LBA_HIGH_SIGNATURE, ATA_DRIVE_TYPE_SATA
    check_device_type SATAPI_DRIVE_LBA_MID_SIGNATURE, SATAPI_DRIVE_LBA_HIGH_SIGNATURE, ATA_DRIVE_TYPE_SATAPI

    jmp .error ; Drive is not one of the valid drive types

    .valid_device:

    %unmacro check_device_type 3

    .read_data:

    ; Read IDENTIFY data
    mov rcx, ATA_IDENTIFY_DATA_LENGTH / 2 ; Bytes to words
    mov rdi, ata_identify_data

    mov dx, ATA_IO_PORT_DATA
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

ata_read: ; rsi = lba, rdi = buffer, ecx = sector count
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    ; TODO: Split into multiple calls if trying to read too many sectors at once

    ; Check if supported features info is valid
    test [ata_identify_data+ATA_IDENTIFY_SUPPORTED_FEATURES_OFFSET], word ATA_IDENTIFY_SUPPORTED_FEATURES_VALID_BIT_1
    jz   .lba28                                                                                                       ; If not, assume LBA28
    test [ata_identify_data+ATA_IDENTIFY_SUPPORTED_FEATURES_OFFSET], word ATA_IDENTIFY_SUPPORTED_FEATURES_VALID_BIT_2
    jnz  .lba28

    test [ata_identify_data+ATA_IDENTIFY_SUPPORTED_FEATURES_OFFSET], word ATA_IDENTIFY_LBA_BIT ; Check if LBA48 is supported
    jnz  .lba48

    .lba28:
        mov rax, rsi                            ; Send drive select and high bits of LBA
        shr rax, 24
        and rax, 0xF
        or  al,  ATA_IO_PORT_DRIVE_SELECT_VALUE
        mov dx,  ATA_IO_PORT_DRIVE_SELECT
        out dx,  al

        mov rax, rcx                      ; Send sector count
        mov dx,  ATA_IO_PORT_SECTOR_COUNT
        out dx,  al

        mov rax, rsi                  ; Send LBA
        mov dx,  ATA_IO_PORT_LBA_LOW
        out dx,  al
        shr rax, 8
        mov dx,  ATA_IO_PORT_LBA_MID
        out dx,  al
        shr rax, 8
        mov dx,  ATA_IO_PORT_LBA_HIGH
        out dx,  al

        mov al, ATA_COMMAND_READ_SECTORS ; Send READ SECTORS command
        mov dx, ATA_IO_PORT_COMMAND
        out dx, al

        jmp .wait_and_read

    .lba48:
        mov al, ATA_IO_PORT_DRIVE_SELECT_VALUE ; Select drive
        mov dx, ATA_IO_PORT_DRIVE_SELECT
        out dx, al

        mov rax, rcx                      ; Send sector count high bits
        shr rax, 8
        mov dx,  ATA_IO_PORT_SECTOR_COUNT
        out dx,  al

        mov rax, rsi                  ; Send LBA high bits
        shr rax, 24
        mov dx,  ATA_IO_PORT_LBA_LOW
        out dx,  al
        shr rax, 8
        mov dx,  ATA_IO_PORT_LBA_MID
        out dx,  al
        shr rax, 8
        mov dx,  ATA_IO_PORT_LBA_HIGH
        out dx,  al

        mov rax, rcx                      ; Send sector count low bits
        mov dx,  ATA_IO_PORT_SECTOR_COUNT
        out dx,  al

        mov rax, rsi                  ; Send LBA low bits
        mov dx,  ATA_IO_PORT_LBA_LOW
        out dx,  al
        shr rax, 8
        mov dx,  ATA_IO_PORT_LBA_MID
        out dx,  al
        shr rax, 8
        mov dx,  ATA_IO_PORT_LBA_HIGH
        out dx,  al

        mov al, ATA_COMMAND_READ_SECTORS_EXT ; Send READ SECTORS EXT command
        mov dx, ATA_IO_PORT_COMMAND
        out dx, al

    .wait_and_read:
        mov rbx, rcx
        .loop:
            ; mov dx, ATA_IO_PORT_STATUS ; The last value in dx is always the command port which is the same as the status port

            in al, dx ; Wait for drive to be ready (400 ns delay)
            in al, dx
            in al, dx
            in al, dx

            .wait:
                in   al, dx
                test al, ATA_STATUS_ERR | ATA_STATUS_DF
                jnz  .error
                test al, ATA_STATUS_BSY
                jnz  .wait
                test al, ATA_STATUS_DRQ
                jz   .wait

            mov dx, ATA_IO_PORT_DATA

            mov rcx, SECTOR_LENGTH / 2 ; Bytes to words
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
    times ATA_IDENTIFY_DATA_LENGTH / 2 dw 0

%endif
