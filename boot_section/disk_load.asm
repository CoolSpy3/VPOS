disk_load: ;code taken from stack overflow user sep roland
    mov [sectors], dh
    mov  ch, 0x00
    mov  dh, 0x00
    mov  cl, kernel_start_sector

    .next_group:
        mov di, 5 ;give 5 chances for the sector to be read properly
                  ;before erroring.

    .again:
        mov ah, 0x02
        mov al, [sectors]
        int 0x13
        jc .retry

        sub [sectors], al ;
        jz .ready

        mov cl, 0x01
        xor dh, 1
        jnz .next_group
        inc ch
        jmp .next_group

    .retry:
        mov ah, 0x00
        int 0x13
        dec di
        jnz .again
        jmp disk_read_error

    .ready:
        ret


disk_read_error:
	mov si, disk_error_msg
	call rm_print

	jmp $

disk_error_msg db 'Disk read error', 0x0D, 0x0A, 0
sectors db 0
