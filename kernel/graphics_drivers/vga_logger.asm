vga_log_space:
    add [vga_log_row], byte 1
    cmp [vga_log_row], byte 25
    jae vga_log_newline
    ret

vga_log_newline:
    add [vga_log_col], byte 12
    mov [vga_log_row], byte 0
    ret

vga_log_eax:
    pusha
    mov cl, [vga_log_col]
    mov ch, [vga_log_row]
    mov dh, 0x5
    call vga_textmode_showhex
    call vga_log_space
    popa
    ret

vga_log_ebx:
    push eax
    mov eax, ebx
    call vga_log_eax
    pop eax
    ret

vga_log_ecx:
    push eax
    mov eax, ecx
    call vga_log_eax
    pop eax
    ret

vga_log_edx:
    push eax
    mov eax, edx
    call vga_log_eax
    pop eax
    ret

vga_log_al:
    push eax
    and eax, 0xFF
    call vga_log_eax
    pop eax
    ret

vga_log_bl:
    push eax
    mov eax, 0
    mov al, bl
    call vga_log_eax
    pop eax
    ret

vga_log_cl:
    push eax
    mov eax, 0
    mov al, cl
    call vga_log_eax
    pop eax
    ret

vga_log_dl:
    push eax
    mov eax, 0
    mov al, dl
    call vga_log_eax
    pop eax
    ret

vga_log_byte_at_eax:
    push eax
    mov al, [eax]
    call vga_log_al
    pop eax
    ret

vga_log_byte_at_ebx:
    push eax
    mov al, [ebx]
    call vga_log_al
    pop eax
    ret

vga_log_byte_at_ecx:
    push eax
    mov al, [ecx]
    call vga_log_al
    pop eax
    ret

vga_log_byte_at_edx:
    push eax
    mov al, [edx]
    call vga_log_al
    pop eax
    ret

vga_log_row: db 0
vga_log_col: db 0
