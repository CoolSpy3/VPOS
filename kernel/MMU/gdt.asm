gdt_start:

gdt_null: ; null descriptor
	dd 0x0
	dd 0x0

gdt_code: ; Long mode code segment, This wil be running for the rest of the program and is mostly just here to disable segmentation
	dw 0x0
	dw 0x0
	db 0x0
	db 10011010b
	db 00100000b
	db 0x0

gdt_data: ; Data segment for both 32 and 64 bit mode
	dw 0xffff
	dw 0x0
	db 0x0
	db 10010010b
	db 11001111b
	db 0x0

gdt_end:

gdt_descriptor:
	dw gdt_end - gdt_start - 1
	dd gdt_start
	dd 0x0 ; This null dword allows the gdt to work in 32 and 64 bit mode

gdt_code_seg equ gdt_code - gdt_start
gdt_data_seg equ gdt_data - gdt_start
