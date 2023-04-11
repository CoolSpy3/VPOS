%ifndef FAT32_BPB
%define FAT32_BPB

%ifndef IDE_VALIDATOR
    %if ($-$$) != 0x03
        %error "FAT32 header is not at the correct offset"
    %endif
%endif

%include "boot_section/sector_sizes.asm"

fat32_header:
    db "VPOSVPOS" ; OEM Identifier
    dw 512 ; Bytes per sector
    db 1 ; Sectors per cluster
    dw reserved_sectors ; Reserved sectors
    db 1 ; Number of FATs
    dw 0 ; Root directory entries (0 for FAT32)
    dw 0 ; Total sectors (0 for FAT32)
    db 0xF8 ; Media descriptor
    dw 0 ; Sectors per FAT (0 for FAT32)
    dw 0 ; Sectors per track
    dw 0 ; Number of heads
    dd 0 ; Hidden sectors
    dd disk_size ; Total sectors

    ; FAT 32
    dd fat_size ; Sectors per FAT
    dw 0x0 ; Flags
    dw 0x0 ; FAT version
    dd 2 ; Root directory cluster
    dw 1 ; FSInfo sector
    dw 0 ; Backup boot sector
    times 12 db 0 ; Reserved
    db 0x80 ; Drive number
    db 0 ; Reserved
    db 0x29 ; Boot signature
    dd 0 ; Volume ID
    db "NO NAME    " ; Volume label
    db "FAT32   " ; File system type

%if ($-fat32_header) != 0x57
    %error "FAT32 header is not the correct size"
%endif

%endif
