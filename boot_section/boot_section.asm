[org 0x7c00]
[bits 16]

xor  ax, ax
mov  ds, ax
mov  es, ax


mov  ax, 0x07e0 ;sets up stack
cli
mov  ss, ax
mov  sp, 0x1200
sti

mov [boot_disk], dl
mov bx, 0x1000
mov dh, 15
mov dl, [boot_disk]

call disk_load

mov si, ss1_boot_msg
call rm_print

in al, 0x92 ;enable A20 line
or al, 0x2
out 0x92, al

cli

lgdt [gdt_descriptor] ;switch to protected mode(32 bit)
mov eax, cr0
or eax, 0x1
mov cr0, eax

jmp gdt_code_seg:pm_begin

jmp $

%include "rm_files/rm_print.asm"
%include "rm_files/disk_load.asm"
%include "pm_files/gdt.asm"

ss1_boot_msg db 'Booted into ss1', 0x0D, 0x0A, 0
boot_disk db 0

[bits 32]
pm_begin:
	mov ax, gdt_data_seg
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	jmp 0x1000

	jmp $

times 510-($-$$) db 0
dw 0xaa55