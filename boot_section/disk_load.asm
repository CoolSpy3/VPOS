%ifndef DISK_LOAD
%define DISK_LOAD
[bits 16]

%include "common/rm_print.asm"
%include "common/system_constants.asm"

%define MAX_RETRIES 5

disk_load: ;code taken from stack overflow user sep roland: https://stackoverflow.com/questions/34216893/disk-read-error-while-loading-sectors-into-memory/34382681#34382681
    mov [sectors], dh ; save the number of sectors to read
    mov dh, 0x00 ; Read from head 0

    .next_group:
        mov di, MAX_RETRIES ;number of chances for the sector to be read properly
                            ;before erroring.

    .again:
        mov ah, READ_SECTORS_COMMAND ; Read Sectors
        mov al, [sectors]
        int DISK_SERVICES_INTERRUPT
        jc .retry ; If the read failed, retry

        sub [sectors], al ; Subtract the number of sectors read
        jz .ready ; If we read all the sectors, we're done

        mov cl, 0x01 ; Try to read the first sector on the next drive head
        xor dh, 1 ; Next drive head
        jnz .next_group
        inc ch ; If we just switched back to head 0, increment the cylinder
        jmp .next_group

    .retry:
        mov ah, RESET_DISK_COMMAND ; Reset disk system
        int DISK_SERVICES_INTERRUPT

        dec di ; Decrement the number of retries and try again
        jnz .again

        jmp disk_read_error ; If we've retried 5 times, error out

    .ready:

        cli ; It looks like some of these interrupts re-set the interrupt
            ; flag, so re-clear it here

        ret


disk_read_error:
	mov si, disk_error_msg ; Print error message
	call rm_print

	jmp $ ; Hang forever

disk_error_msg db `Disk read error\n\r`, 0
sectors db 0

%endif
