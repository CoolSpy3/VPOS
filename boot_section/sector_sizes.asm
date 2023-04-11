%ifndef SECTOR_SIZES
%define SECTOR_SIZES

%ifdef IDE_VALIDATOR
    %define kernel_size 2
    %define fat_size 2
    %define filesystem_size 2
    kernel_start_sector equ 2
%else
    kernel_start_sector equ ((kernel_start-$$) / 512) + 1 ; Sector at which the kernel starts
%endif

required_sectors equ kernel_size ; Number of sectors required for the kernel
reserved_sectors equ (kernel_size+2) ; Number of sectors reserved in the FAT
disk_size equ reserved_sectors+filesystem_size ; Total number of sectors on the disk

%endif
