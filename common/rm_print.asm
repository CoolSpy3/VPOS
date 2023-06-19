%ifndef COMMON_RM_PRINT
%define COMMON_RM_PRINT
[bits 16]

%include "common/system_constants.asm"

rm_print: ; Print a string in si to the screen using int 0x10
	mov ah, CHAR_WRITE_COMMAND ; Set ah to write text

	.next_char:
	mov al, [si] ; Load the next character into al

	cmp al, 0 ; If the character is null, we're done
	je rm_print_done

	int VIDEO_SERVICES_INTERRUPT ; Print the character to the screen
	inc si ; Increment the string pointer
	jmp .next_char ; Print the next character

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

	push ax ; Print the characters '0x'
	mov ah, CHAR_WRITE_COMMAND
	mov al, '0'
	int VIDEO_SERVICES_INTERRUPT
	mov al, 'x'
	int VIDEO_SERVICES_INTERRUPT
	pop ax

	push eax ; Print the first 4 bits of eax
	shr eax, 16
	call rm_print_ax
	pop eax

	call rm_print_ax ; Print the last 4 bits of eax

	mov ah, CHAR_WRITE_COMMAND ; Print a newline
	mov al, `\n`
	int VIDEO_SERVICES_INTERRUPT
	mov al, `\r`
	int VIDEO_SERVICES_INTERRUPT

	pop eax
	ret

rm_print_ax:
	push ax ; Print the first 4 bits of ax
	push dx

	mov dx, ax ; Store ax in dx so we can shift it and not lose it

	shr ax, 12
	call rm_print_al_l

	mov ax, dx ; Print the next 4 bits of ax
	shr ax, 8
	call rm_print_al_l

	mov ax, dx ; Print the next 4 bits of ax
	shr ax, 4
	call rm_print_al_l

	pop dx
	pop ax

	call rm_print_al_l ; Print the last 4 bits of ax
	ret

rm_print_al_l: ; Print the last 4 bits of al
	push ax
	and al, 0xF ; Mask out the first 4 bits of al
	add al, '0' ; Convert al to a character
	cmp al, 0xA+'0' ; If al is greater than or equal to 0xA, we need to convert it to a letter
	jb .print
	add al, 'A'-'0'-0xA ; Convert al to a letter
	.print:
	mov ah, CHAR_WRITE_COMMAND ; Print the character to the screen
	int VIDEO_SERVICES_INTERRUPT
	pop ax
	ret

%endif
