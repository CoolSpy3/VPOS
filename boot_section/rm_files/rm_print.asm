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
