%ifndef SYSTEM_CONSTANTS
%define SYSTEM_CONSTANTS

; BIOS Interrupts (See http://www.ctyme.com/intr/int.htm for more info)
    %define VIDEO_SERVICES_INTERRUPT 0x10
        %define SET_VIDEO_MODE_COMMAND   0x00 ; al=mode ; al=flags
            %define VIDEO_MODE_TEXT_MODE 0x03 ; 80x25, 16 color text mode
        %define SET_CURSOR_POS_COMMAND 0x01 ; ch=start and options, cl=end line
            %define CURSOR_OPTIONS_NORMAL 00000000b
            %define CURSOR_OPTIONS_INVISIBLE 00100000b
            %define CURSOR_OPTIONS_ERATIC 01000000b
            %define CURSOR_OPTIONS_SLOW 01100000b
        %define CHAR_WRITE_COMMAND 0x0E ; al=char, bh=page, bl=color

    %define DISK_SERVICES_INTERRUPT 0x13
        %define RESET_DISK_COMMAND 0x00 ; dl=drive ; ah=status, cf=error
        %define READ_SECTORS_COMMAND 0x02 ; al=sector count, ch=track, cl=sector, dh=head, dl=drive, es:bx=buffer ; ah=status, al=sector count, cf=error

    %define MISC_SERVICES_INTERRUPT 0x15
        %define GET_EXT_MEM_LEN_COMMAND 0xE801 ; ; ax=cx=mem between 1MB and 16MB (in K), bx=dx=mem above 16MB (in 64K), cf=error
        %define GET_MEM_MAP_COMMAND 0xE820 ; ebx=0 or last ebx result, ecx=buffer size, edx='SMAP', es:di=buffer ; eax='SMAP', ebx=next ebx result or 0, ecx=data length, es:di=buffer, cf=error
            %define MEM_MAP_BUF_SIZE 32
                %define MEM_MAP_BASE_OFFSET 0x0
                %define MEM_MAP_LENGTH_OFFSET 0x8
                %define MEM_MAP_TYPE_OFFSET 0x10
                %define MEM_MAP_EXT_FLAGS_OFFSET 0x12
            %define SMAP 0x534D4150 ; SMAP signature (SMAP in ASCII) (Not as a string because the byte order is reversed)

    %define KEYBOARD_SERVICES_INTERRUPT 0x16
    %define READ_KEY_COMMAND 0x00 ; ; ah=scan code, al=ascii char

; Control Registers

    ; CR0
    %define PROTECTED_MODE_ENABLE_BIT 0x1
    %define PAGING_ENABLE_BIT 0x80000000

    ; CR4
    %define PAE_ENABLE_BIT 0x20 ; Physical Address Extension enable bit

    ; EFLAGS
    %define EFLAGS_ID_BIT 0x00200000

    ; IA32_EFER
    %define IA32_EFER_MSR 0xC0000080
    %define IA32_EFER_LME 0x100 ; Long mode enable
    %define IA32_EFER_NXE 0x800 ; Execute disable enable

; CPUID flags
    %define BASIC_CPUID_LEAF 0x0
    %define FEATURE_INFO_CPUID_LEAF 0x1
        %define PSE_SUPPORT_BIT 0x00000008
        %define PAE_SUPPORT_BIT 0x00000040
        %define APIC_SUPPORT_BIT 0x00000200
        %define PAT_SUPPORT_BIT 0x00008000
        %define PSE36_SUPPORT_BIT 0x00010000
        %define X2APIC_SUPPORT_BIT 0x00200000
    %define EXTENDED_INFO_CPUID_LEAF 0x80000000
    %define EXTENDED_FEATURE_INFO_CPUID_LEAF 0x80000001
    %define MSR_SUPPORT_BIT 0x00000020
    %define CMOV_SUPPORT_BIT 0x00008000
    %define HAS_EXECUTE_DISABLE 0x00100000
    %define HAS_LONG_MODE 0x20000000

; GDT
    %define GDT_ENTRY_LEN 8
    %define GDT_MAX_ENTRIES 8192
    %define GDT_MAX_LENGTH GDT_ENTRY_LEN * GDT_MAX_ENTRIES

    %define GDT_ENTRY_TYPE_SYSTEM 10000b
    %define GDT_ENTRY_TYPE_CODE 1000b | GDT_ENTRY_TYPE_SYSTEM
        %define GDT_ENTRY_READABLE 0010b ; Readable bit of type field
        %define GDT_ENTRY_CONFORMING 0100b ; Conforming bit of type field
    %define GDT_ENTRY_TYPE_DATA 0000b | GDT_ENTRY_TYPE_SYSTEM
        %define GDT_ENTRY_WRITEABLE 0010b ; Writeable bit of type field
        %define GDT_ENTRY_EXPAND_DOWN 0100b ; Expand down bit of type field
    %define GDT_ENTRY_ACCESSED 0001b ; Accessed bit of type field

    %define GDT_ENTRY_TYPE_TSS 0001b ; Task segment
    %define GDT_ENTRY_TYPE_LDT 0010b ; Local descriptor table
    %define GDT_ENTRY_TYPE_TSS_BUSY 0011b
    %define GDT_ENTRY_TYPE_CALL_GATE 0100b
    %define GDT_ENTRY_TYPE_TASK_GATE 0101b
    %define GDT_ENTRY_TYPE_INT_GATE 0110b
    %define GDT_ENTRY_TYPE_TRAP_GATE 0111b
    %define GDT_ENTRY_TYPE_32 1000b

    %define GDT_ENTRY_DPL_0 00000000b ; DPL 0
    %define GDT_ENTRY_DPL_1 00100000b ; DPL 1
    %define GDT_ENTRY_DPL_2 01000000b ; DPL 2
    %define GDT_ENTRY_DPL_3 01100000b ; DPL 3

    %define GDT_ENTRY_PRESENT 10000000b ; Present bit
    %define GDT_ENTRY_AVL 00010000b ; Available for use by system software
    %define GDT_ENTRY_64BIT 00100000b ; 64-bit code segment
    %define GDT_ENTRY_DB 01000000b ; Default operation size / Default stack pointer size / Upper bound
    %define GDT_ENTRY_GRANULARITY_4KB 10000000b ; 4KB granularity

    %define RPL_0 00b ; RPL 0
    %define RPL_1 01b ; RPL 1
    %define RPL_2 10b ; RPL 2
    %define RPL_3 11b ; RPL 3

    %define TABLE_GDT 0x0 ; GDT
    %define TABLE_LDT 0x1 ; LDT

; Page Tables
    %define PAGE_TABLE_LENGTH 4096
    %define PAGE_TABLE_ENTRY_LEN 8
    %define PAGE_TABLE_NUM_ENTRIES PAGE_TABLE_LENGTH / PAGE_TABLE_ENTRY_LEN

    %define PTE_P 0x1 ; Present bit
    %define PTE_RW 0x2 ; Read/Write bit
    %define PTE_US 0x4 ; User/Supervisor bit
    %define PTE_PWT 0x8 ; Page-level write-through bit
    %define PTE_PCD 0x10 ; Page-level cache disable bit
    %define PTE_PS 0x80 ; Page size bit
    %define PTE_G 0x100 ; Global bit

; VGA
    %define SCREEN_NUM_ROWS 25
    %define SCREEN_NUM_COLS 80
    %define VRAM_START 0xA0000
    %define VRAM_TEXT_START 0xB8000
    %define VRAM_END 0xC0000

; ATA
    %define ATA_MASTER_DRIVE 0xA0
    %define ATA_SLAVE_DRIVE 0xB0

    %define ATA_IO_PORT_BASE 0x1F0 ; Secondary Port is 0x170
    %define ATA_IO_PORT_DATA ATA_IO_PORT_BASE + 0x0
    %define ATA_IO_PORT_ERROR ATA_IO_PORT_BASE + 0x1 ; Read only
        %define ATA_ERROR_ABRT 0x04 ; Command aborted
    %define ATA_IO_PORT_FEATURES ATA_IO_PORT_BASE + 0x1 ; Write only
    %define ATA_IO_PORT_SECTOR_COUNT ATA_IO_PORT_BASE + 0x2
    %define ATA_IO_PORT_LBA_LOW ATA_IO_PORT_BASE + 0x3 ; Also used for sector number
    %define ATA_IO_PORT_LBA_MID ATA_IO_PORT_BASE + 0x4 ; Also used for Cylinder Low
    %define ATA_IO_PORT_LBA_HIGH ATA_IO_PORT_BASE + 0x5 ; Also used for Cylinder High
    %define ATA_IO_PORT_DRIVE_SELECT ATA_IO_PORT_BASE + 0x6 ; Also used for Drive/Head
        %define ATA_DRIVE_SELECT_DRV 0x10 ; Drive bit (unset=Master, set=Slave)
        %define ATA_DRIVE_SELECT_LBA 0x40 ; LBA enable bit
    %define ATA_IO_PORT_STATUS ATA_IO_PORT_BASE + 0x7 ; Read only
        %define ATA_STATUS_ERR 0x01 ; Error
        %define ATA_STATUS_DRQ 0x08 ; Data Request
        %define ATA_STATUS_DF 0x20 ; Device Fault
        %define ATA_STATUS_BSY 0x80 ; Busy
    %define ATA_IO_PORT_COMMAND ATA_IO_PORT_BASE + 0x7 ; Write only
        %define ATA_COMMAND_READ_SECTORS 0x20
        %define ATA_COMMAND_READ_SECTORS_EXT 0x24
        %define ATA_COMMAND_IDENTIFY 0xEC
            %define ATA_IDENTIFY_DATA_LENGTH 512
            %define ATA_IDENTIFY_SUPPORTED_FEATURES_OFFSET 2*83
                %define ATA_IDENTIFY_LBA_BIT 0x400
                %define ATA_IDENTIFY_SUPPORTED_FEATURES_VALID_BIT_1 0x4000
                %define ATA_IDENTIFY_SUPPORTED_FEATURES_VALID_BIT_2 0x8000

    %define ATA_CONTROL_PORT_BASE 0x3F6 ; Secondary Port is 0x376
    %define ATA_CONTROL_PORT_ALT_STATUS ATA_CONTROL_PORT_BASE + 0x0 ; Read only
    %define ATA_CONTROL_PORT_DEVICE_CONTROL ATA_CONTROL_PORT_BASE + 0x0 ; Write only
    %define ATA_CONTROL_PORT_DRIVE_ADDRESS ATA_CONTROL_PORT_BASE + 0x1 ; Write only

    ; Drive signatures come from page 85 of volume 1 of the ATA/ATAPI-7 spec (https://hddguru.com/documentation/2006.01.27-ATA-ATAPI-7/)
    %define ATA_DRIVE_LBA_MID_SIGNATURE 0x00
    %define ATA_DRIVE_LBA_HIGH_SIGNATURE 0x00
    %define ATAPI_DRIVE_LBA_MID_SIGNATURE 0x14
    %define ATAPI_DRIVE_LBA_HIGH_SIGNATURE 0xEB
    %define SATA_DRIVE_LBA_MID_SIGNATURE 0x3C
    %define SATA_DRIVE_LBA_HIGH_SIGNATURE 0xC3
    %define SATAPI_DRIVE_LBA_MID_SIGNATURE 0x69
    %define SATAPI_DRIVE_LBA_HIGH_SIGNATURE 0x96

    %define SECTOR_LENGTH 512

%endif
