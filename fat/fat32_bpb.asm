%if ($-$$) != 0x03
    %error "FAT32 header is not at the correct offset"
%endif

disk_size equ 0x100000/512
reserved_sectors equ ((kernel_size/512)+2)

fat32_header:
    db "VPOSVPOS" ; OEM Identifier
    dw 512 ; Bytes per sector
    db 1 ; Sectors per cluster
    dw reserved_sectors ; Reserved sectors
    db 1 ; Number of FATs
    dw 0 ; Root directory entries (0 for FAT32)
%if disk_size > 0xFFFF
    dw 0 ; Total sectors
%else
    dw disk_size ; Total sectors
%endif
    db 0 ; Media descriptor
    dw 0 ; Sectors per FAT (0 for FAT32)
    dw 0 ; Sectors per track
    dw 0 ; Number of heads
    dd 0 ; Hidden sectors
%if disk_size > 0xFFFF
    dd disk_size ; Total sectors (if above is 0)
%else
    dd 0 ; Total sectors (if above is 0)
%endif

    ; FAT 32
    dd 0 ; Sectors per FAT
    dw 0 ; Flags
    dw 0 ; FAT version
    dd 0 ; Root directory cluster
    dw 2 ; FSInfo sector
    dw 1 ; Backup boot sector
    times 12 db 0 ; Reserved
    db 0 ; Drive number
    db 0 ; Reserved
    db 0x29 ; Boot signature
    dd 0 ; Volume ID
    db "VPOS Boot  " ; Volume label
    db "FAT32   " ; File system type

%if ($-$$) != 0x05A
    %error "FAT32 header is not the correct size"
%endif
