%ifndef BOOT_SECTION
%define BOOT_SECTION

%include "boot_section/sector_sizes.asm"

[org 0x7c00]
[bits 16]
jmp short boot_section ; Jump to boot section (This is here to fit with the FAT32 standard)
nop

%include "fat/fat32_bpb.asm"

%define STACK_SEGMENT      0x07e0
%define STACK_OFFSET       0x1200
%define KERNEL_MEM_ADDRESS 0x1000

boot_section:
    xor ax, ax ; Clear ds and es
    mov ds, ax
    mov es, ax

    cli ; Disable interupts while setting up kernel

    mov ax, STACK_SEGMENT
    mov ss, ax
    mov sp, STACK_OFFSET

    mov [boot_disk], dl ; Save boot disk id

    mov  bx, KERNEL_MEM_ADDRESS
    mov  ch, 0x00                ; Read from cylinder 0
    mov  cl, kernel_start_sector ; Read from the first sector of the kernel
    mov  dh, required_sectors    ; Load required_sectors number of sectors
    call disk_load               ; Load kernel from disk

    mov  si, ss1_boot_msg ; Print boot message
    call rm_print

    in  al,   0x92 ;enable A20 line
    or  al,   0x2
    out 0x92, al

    jmp KERNEL_MEM_ADDRESS ; Jump to kernel

%include "common/rm_print.asm"
%include "boot_section/disk_load.asm"

ss1_boot_msg     db  `Booted into ss1\n\r`, 0
boot_disk        db  0                        ; Boot disk id

times 510-($-$$) db  0                        ; Pad to 510 bytes
dw                   0xaa55                   ; Boot signature

%include "fat/fat32_fsinfo.asm"

kernel_start     equ $                        ; Location of kernel in file

%endif
