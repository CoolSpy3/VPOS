%ifndef KERNEL_MMU_GDT
%define KERNEL_MMU_GDT

%include "common/system_constants.asm"

%if ($-$$) % 8 != 0 ; Align to 8 bytes
	times 8 - (($-$$) % 8) db 0x0
%endif

gdt_start:

gdt_null: ; null descriptor
	dq 0x0

; The limit and base are ignored in 64bit mode, but we still need to set them so that the kernel doesn't crash between loading the GDT and entering long-mode

gdt_code: ; Long mode code segment, This wil be running for the rest of the program and is mostly just here to fulfill x86 segmentation requirements
	dw 0xFFFF ; Limit 0-15
	dw 0x0 ; Base 0-15
	db 0x0 ; Base 16-23
	db GDT_ENTRY_PRESENT | GDT_ENTRY_DPL_0 | GDT_ENTRY_TYPE_CODE
	db GDT_ENTRY_GRANULARITY_4KB | GDT_ENTRY_64BIT | 1111b ; Limit 16-19
	db 0x0 ; Base 24-31

gdt_data: ; Data segment for both 32 and 64 bit mode
	dw 0xFFFF ; Limit 0-15
	dw 0x0 ; Base 0-15
	db 0x0 ; Base 16-23
	db GDT_ENTRY_PRESENT | GDT_ENTRY_DPL_0 | GDT_ENTRY_TYPE_DATA | GDT_ENTRY_WRITEABLE
	db GDT_ENTRY_GRANULARITY_4KB | 1111b ; Limit 16-19
	db 0x0 ; Base 24-31

gdt_end:

%if gdt_end - gdt_start > GDT_MAX_LENGTH
	%error "GDT is too large!"
%endif

%if (gdt_end - gdt_start) % 8 != 0
	%error "GDT does not have a whole number of entries!"
%endif

gdt_descriptor:
	dw gdt_end - gdt_start - 1 ; -1 because the limit is the last valid byte
	dq gdt_start

gdt_code_seg equ gdt_code - gdt_start
gdt_data_seg equ gdt_data - gdt_start

%endif
