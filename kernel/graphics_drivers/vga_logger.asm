%ifndef KERNEL_VGA_LOGGER
%define KERNEL_VGA_LOGGER

[bits 64]

%include "common/system_constants.asm"
%include "kernel/graphics_drivers/vga_textmode_driver.asm"

%define VGA_LOG_COL_SPACING      4+16
%define VGA_LOG_COL_MAX          SCREEN_NUM_COLS-16
%define VGA_LOG_DUMP_NUM_ENTRIES 20
%define VGA_LOG_COLOR            0x5

vga_log_space:
    pushfq
    inc byte [vga_log_row]
    cmp [vga_log_row], byte SCREEN_NUM_ROWS
    jae vga_log_newline.with_flags
    popfq
    ret

vga_log_newline:
    pushfq
    .with_flags:
    add [vga_log_col], byte VGA_LOG_COL_SPACING
    mov [vga_log_row], byte 0
    cmp [vga_log_col], byte VGA_LOG_COL_MAX
    jae vga_log_reset.with_flags
    popfq
    ret

vga_log_reset:
    pushfq
    .with_flags:
    mov  [vga_log_col], byte 0
    mov  [vga_log_row], byte 0
    call clear_textmode_buffer
    popfq
    ret

vga_log_rax:
    pushaq
    pushfq
    mov  cl, [vga_log_col]
    mov  ch, [vga_log_row]
    mov  dh, VGA_LOG_COLOR
    call vga_textmode_showhex
    call vga_log_space
    popfq
    popaq
    ret

vga_log_rbx:
    push rax
    mov  rax, rbx
    call vga_log_rax
    pop  rax
    ret

vga_log_rcx:
    push rax
    mov  rax, rcx
    call vga_log_rax
    pop  rax
    ret

vga_log_rdx:
    push rax
    mov  rax, rdx
    call vga_log_rax
    pop  rax
    ret

vga_log_al:
    push rax
    pushfq
    and  rax, 0xFF
    call vga_log_rax
    popfq
    pop  rax
    ret

vga_log_bl:
    push rax
    mov  rax, 0
    mov  al,  bl
    call vga_log_rax
    pop  rax
    ret

vga_log_cl:
    push rax
    mov  rax, 0
    mov  al,  cl
    call vga_log_rax
    pop  rax
    ret

vga_log_dl:
    push rax
    mov  rax, 0
    mov  al,  dl
    call vga_log_rax
    pop  rax
    ret

vga_log_byte_at_rax:
    push rax
    mov  al, [rax]
    call vga_log_al
    pop  rax
    ret

vga_log_byte_at_rbx:
    push rax
    mov  al, [rbx]
    call vga_log_al
    pop  rax
    ret

vga_log_byte_at_rcx:
    push rax
    mov  al, [rcx]
    call vga_log_al
    pop  rax
    ret

vga_log_byte_at_rdx:
    push rax
    mov  al, [rdx]
    call vga_log_al
    pop  rax
    ret

vga_log_qword_at_rax:
    push rax
    mov  rax, [rax]
    call vga_log_rax
    pop  rax
    ret

vga_log_qword_at_rbx:
    push rax
    mov  rax, [rbx]
    call vga_log_rax
    pop  rax
    ret

vga_log_qword_at_rcx:
    push rax
    mov  rax, [rcx]
    call vga_log_rax
    pop  rax
    ret

vga_log_qword_at_rdx:
    push rax
    mov  rax, [rdx]
    call vga_log_rax
    pop  rax
    ret

vga_dump_mem_at_rax:
    push rax
    push rcx
    pushfq
    mov  rcx, 0

    .loop:
        call vga_log_byte_at_rax
        inc  rax
        inc  rcx
        cmp  rcx, VGA_LOG_DUMP_NUM_ENTRIES
        jb   .loop

    popfq
    pop rcx
    pop rax
    ret

vga_dump_mem_at_rbx:
    push rax
    mov  rax, rbx
    call vga_dump_mem_at_rax
    pop  rax
    ret

vga_dump_mem_at_rcx:
    push rax
    mov  rax, rcx
    call vga_dump_mem_at_rax
    pop  rax
    ret

vga_dump_mem_at_rdx:
    push rax
    mov  rax, rdx
    call vga_dump_mem_at_rax
    pop  rax
    ret

vga_dump_long_mem_at_rax:
    push rax
    push rcx
    pushfq
    mov  rcx, 0

    .loop:
        call vga_log_qword_at_rax
        add  rax, 8
        inc  rcx
        cmp  rcx, VGA_LOG_DUMP_NUM_ENTRIES
        jb   .loop

    popfq
    pop rcx
    pop rax
    ret

vga_dump_long_mem_at_rbx:
    push rax
    mov  rax, rbx
    call vga_dump_long_mem_at_rax
    pop  rax
    ret

vga_dump_long_mem_at_rcx:
    push rax
    mov  rax, rcx
    call vga_dump_long_mem_at_rax
    pop  rax
    ret

vga_dump_long_mem_at_rdx:
    push rax
    mov  rax, rdx
    call vga_dump_long_mem_at_rax
    pop  rax
    ret


vga_log_row: db 0
vga_log_col: db 0

%endif
