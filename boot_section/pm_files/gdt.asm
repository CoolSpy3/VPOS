gdt_start:

gdt_null:
	dd 0x0
	dd 0x0

gdt_32_code:
	dw 0xffff
	dw 0x0
	db 0x0
	db 10011010b
	db 11011111b
	db 0x0

gdt_64_code:
	dw 0xffff
	dw 0x0
	db 0x0
	db 10011010b
	db 11011111b
	db 0x0

gdt_data:
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

gdt_32_code_seg equ gdt_32_code - gdt_start
gdt_64_code_seg equ gdt_64_code - gdt_start
gdt_data_seg equ gdt_data - gdt_start
