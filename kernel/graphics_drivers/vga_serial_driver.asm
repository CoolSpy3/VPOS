%ifndef KERNEL_VGA_SERIAL_DRIVER
%define KERNEL_VGA_SERIAL_DRIVER

[bits 64]

%include "kernel/util/stackmacros.asm"

; dump_state: ; probably unnecessary,
;             ; but if I have a more basic print function
;             ; it might be useful.
;     call read_regs
;     call dump_regs

; dump_regs: ; probably unnecessary,
;            ; but if I have a more basic print function
;            ; it might be useful.
;     ; push cx
;     ; add empty_VGAregister_data_buffer, 1

;     ; semantics(just a ton of reg dump loop calls)
;     ; too lazy to finish it

;     ; pop cx
;     ret

; reg_dump_loop:
;     ; push cx
;     ; mov ch, 0

;     ; reg_loop0:
;     ;     inc ch
;     ;     cmp ch, 8
;     ;     jl reg_loop0_maybe

;     ;     mov ch, 0

;     ;     reg_loop0_maybe:
;     ;     add empty_VGAregister_data_buffer, 8
;     ;     dec cl
;     ;     cmp cl, 0
;     ;     jne reg_loop0


;     ; pop cx
;     ret

; read_regs: ; probably unnecessary,
;            ; but if I have a more basic print function
;            ; it might be useful.
;     ; push ax
;     ; push si
;     ; push di
;     ; push ch

;     ; in ax, VGA_misc_read
;     ; mov [empty_VGAregister_data_buffer], ax

;     ; add empty_VGAregister_data_buffer, 1

;     ; mov si, VGA_seq_index ; VGA_index
;     ; mov di, VGA_seq_data ; VGA_data
;     ; mov ch, 5 ; loop end condition
;     ; call reg_read_loop ; call

;     ; mov si, VGA_crtc_index
;     ; mov di, VGA_crtc_data
;     ; mov ch, 25
;     ; call reg_read_loop

;     ; mov si, VGA_GC_index
;     ; mov di, VGA_GC_data
;     ; mov ch, 9
;     ; call reg_read_loop


;     ; mov si, VGA_AC_index
;     ; mov di, VGA_AC_read
;     ; mov ch, 21
;     ; call reg_read_loop

;     ; in ax, VGA_instat_read
;     ; out VGA_AC_index, 0x20

;     ; pop ax
;     ; pop si
;     ; pop di
;     ; pop ch
;     ret

; reg_read_loop: ;si: VGA_index, di: VGA_data, ch: loop end condition
;     ; push cl ; counter
;     ; mov cl, 0 ; set to 0

;     ; out si, cl
;     ; in ax, di
;     ; mov [empty_VGAregister_data_buffer], ax
;     ; inc cl
;     ; add empty_VGAregister_data_buffer, 1

;     ; cmp cl, ch
;     ; jne reg_read_loop

;     ; pop cl
;     ret

VGA_write_regs:
    pushaq

    mov dx, VGA_misc_write
    mov rbx, VGAregister_data
    mov al, [rbx]
    out dx, al

    inc rbx

    mov si, VGA_seq_index
    mov di, VGA_seq_data
    mov cl, 0
    mov ch, VGA_num_seq_regs
    call .loop

    ; unlock crtc registers
    mov dx, VGA_crtc_index
    mov al, 0x03
    out dx, al
    mov dx, VGA_crtc_data
    in al, dx
    or al, 0x80
    out dx, al

    mov dx, VGA_crtc_index
    mov al, 0x11
    out dx, al

    mov dx, VGA_crtc_data
    in al, dx
    and al, ~0x80
    out dx, al

    mov al, [rbx+0x03]
    or al, 0x80
    mov [rbx+0x03], al

    mov al, [rbx+0x11]
    and al, ~0x80
    mov [rbx+0x11], al

    mov si, VGA_crtc_index
    mov di, VGA_crtc_data
    mov cl, 0
    mov ch, VGA_num_crtc_regs
    call .loop

    mov si, VGA_GC_index
    mov di, VGA_GC_data
    mov cl, 0
    mov ch, VGA_num_GC_regs
    call .loop

    mov si, VGA_AC_index
    mov di, VGA_AC_write
    mov cl, 0
    mov ch, VGA_num_AC_regs
    call .loop2

    mov dx, VGA_instat_read
    in al, dx

    mov dx, VGA_AC_index
    mov al, 0x20
    out dx, al

    popaq
    ret

    .loop: ;si: VGA_index, di: VGA_data, ch: loop end condition, cl: 0, rbx: start of VGAregister_data (will be incremented)
        mov dx, si
        mov al, cl
        out dx, al
        mov dx, di
        mov al, [rbx]
        out dx, al

        inc rbx
        inc cl
        cmp cl, ch
        jl .loop
        ret

    .loop2: ;si: VGA_index, di: VGA_data, ch: loop end condition, cl: 0, rbx: start of VGAregister_data (will be incremented)
        mov dx, VGA_instat_read
        in al, dx

        mov dx, si
        mov al, cl
        out dx, al
        mov dx, di
        mov al, [rbx]
        out dx, al

        inc rbx
        inc cl
        cmp cl, ch
        jl .loop2
        ret

draw_pixel: ; ax: x, bx: y, cl: color
    pushaq

    mov dx, ax

    mov ax, DISPLAY_width
    push dx
    mul bx
    pop dx
    add ax, dx

    mov bx, ax

    call vpoke

    popaq
    ret

vpoke: ; bx: offset, cl: value
    pushaq

    mov dx, VGA_GC_index
    mov al, 6
    out dx, al
    mov dx, VGA_GC_data
    in al, dx

    shr al, 2
    and al, 3

    cmp al, 0
    je .switch0
    cmp al, 1
    je .switch1
    cmp al, 2
    je .switch2
    cmp al, 3
    je .switch3

    .switch0:
    .switch1:
        mov rax, 0xA0000
        jmp .end

    .switch2:
        mov rax, 0xB0000
        jmp .end

    .switch3:
        mov rax, 0xB8000
        jmp .end

    .end:

    call VGA_poke

    popaq
    ret

VGA_poke: ; rax: S, rbx: O, cl: V
    pushaq

    push bx
    mov rbx, 0
    pop bx

    add rbx, rax

    mov [rbx], cl

    popaq
    ret

disable_cursor:
    mov al, 0x0A
    mov dx, VGA_crtc_index
    out dx, al
    mov al, 0x20
    mov dx, VGA_crtc_data
    out dx, al
    ret

VGA_clear_screen:
    push ax
    push bx
    push cx

    mov bx, 0
    mov cl, 0
    .clr_lp_1:
    mov ax, 0
    .clr_lp_2:
    call draw_pixel
    inc ax
    cmp ax, DISPLAY_width
    jl .clr_lp_2
    inc bx
    cmp bx, DISPLAY_height
    jl .clr_lp_1

    pop cx
    pop bx
    pop ax
    ret

VGA_seq_index equ 0x3c4
VGA_seq_data equ 0x3c5
VGA_crtc_index equ 0x3d4
VGA_crtc_data equ 0x3d5
VGA_GC_index equ 0x3ce
VGA_GC_data equ 0x3cf
VGA_AC_index equ 0x3c0

VGA_instat_read equ 0x3da
VGA_AC_read equ 0x3c1
VGA_AC_write equ 0x3c0
VGA_misc_read equ 0x3cc
VGA_misc_write equ 0x3c2

VGA_num_seq_regs equ 5
VGA_num_crtc_regs equ 25
VGA_num_GC_regs	equ 9
VGA_num_AC_regs	equ 21

DISPLAY_width equ 320
DISPLAY_height equ 200

; empty_VGAregister_data_buffer:
;     ;miscellaneous register(1)
;     db 0

;     ;sequence registers(5)
;     times 5 db 0

;     ;crtc registers(25)
;     times 25 db 0

;     ;graphic's controller(GC) registers(9)
;     times 9 db 0

;     ;attribute controller(AC) registers(21)
;     times 21 db 0


VGAregister_data: db 0x63, 0x03, 0x01, 0x0F, 0x00, 0x0E, 0x5F, 0x4F, 0x50, 0x82, 0x54, 0x80, 0xBF, 0x1F, 0x00, 0x41, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x9C, 0x0E, 0x8F, 0x28, 0x40, 0x96, 0xB9, 0xA3, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x05, 0x0F, 0xFF, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x41, 0x00, 0x0F, 0x00, 0x00

%endif
