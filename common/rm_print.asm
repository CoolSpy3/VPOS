rm_print:
	mov ah, 0x0e
	mov al, [si]

	cmp al, 0
	je rm_print_done

	int 0x10
	add si, 1
	jmp rm_print

	rm_print_done:
		ret

rm_dump_regs:
	; Write eax ebx ecx and edx to the screen using int 0x10
	push eax
	call rm_dump_eax
	mov eax, ebx
	call rm_dump_eax
	mov eax, ecx
	call rm_dump_eax
	mov eax, edx
	call rm_dump_eax
	pop eax
	ret

rm_dump_eax:
	push eax

	push ax
	mov ah, 0x0e
	mov al, '0'
	int 0x10
	mov al, 'x'
	int 0x10
	pop ax

	push eax
	shr eax, 16
	call rm_print_ax
	pop eax

	call rm_print_ax

	mov ah, 0x0e
	mov al, 0xA
	int 0x10
	mov al, 0xD
	int 0x10

	pop eax
	ret

rm_print_ax:
	push ax
	shr ax, 12
	call rm_print_al_l
	pop ax

	push ax
	shr ax, 8
	call rm_print_al_l
	pop ax

	push ax
	shr ax, 4
	call rm_print_al_l
	pop ax

	call rm_print_al_l
	ret

rm_print_al_l:
	push ax
	and al, 0xF
	add al, '0'
	cmp al, 0xA+'0'
	jb .print
	add al, 'A'-'0'-0xA
	.print:
	mov ah, 0x0e
	int 0x10
	pop ax
	ret
