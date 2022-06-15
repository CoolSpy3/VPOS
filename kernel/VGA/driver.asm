dump_state: ; probably unnecessary,
            ; but if I have a more basic print function
            ; it might be useful.
    call read_regs
    call dump_regs

dump_regs: ; probably unnecessary,
           ; but if I have a more basic print function
           ; it might be useful.
    ; push cx
    ; add empty_VGAregister_data_buffer, 1

    ; semantics(just a ton of reg dump loop calls)
    ; too lazy to finish it

    ; pop cx
    ret

reg_dump_loop:
    ; push cx
    ; mov ch, 0

    ; reg_loop0:
    ;     inc ch
    ;     cmp ch, 8
    ;     jl reg_loop0_maybe

    ;     mov ch, 0

    ;     reg_loop0_maybe:
    ;     add empty_VGAregister_data_buffer, 8
    ;     dec cl
    ;     cmp cl, 0
    ;     jne reg_loop0


    ; pop cx
    ret

read_regs: ; probably unnecessary,
           ; but if I have a more basic print function
           ; it might be useful.
    ; push ax
    ; push si
    ; push di
    ; push ch

    ; in ax, VGA_misc_read
    ; mov [empty_VGAregister_data_buffer], ax

    ; add empty_VGAregister_data_buffer, 1

    ; mov si, VGA_seq_index ; VGA_index
    ; mov di, VGA_seq_data ; VGA_data
    ; mov ch, 5 ; loop end condition
    ; call reg_read_loop ; call

    ; mov si, VGA_crtc_index
    ; mov di, VGA_crtc_data
    ; mov ch, 25
    ; call reg_read_loop

    ; mov si, VGA_GC_index
    ; mov di, VGA_GC_data
    ; mov ch, 9
    ; call reg_read_loop


    ; mov si, VGA_AC_index
    ; mov di, VGA_AC_read
    ; mov ch, 21
    ; call reg_read_loop

    ; in ax, VGA_instat_read
    ; out VGA_AC_index, 0x20

    ; pop ax
    ; pop si
    ; pop di
    ; pop ch
    ret

reg_read_loop: ;si: VGA_index, di: VGA_data, ch: loop end condition
    ; push cl ; counter
    ; mov cl, 0 ; set to 0

    ; out si, cl
    ; in ax, di
    ; mov [empty_VGAregister_data_buffer], ax
    ; inc cl
    ; add empty_VGAregister_data_buffer, 1

    ; cmp cl, ch
    ; jne reg_read_loop

    ; pop cl
    ret

write_regs:
    pushad

    mov dx, VGA_misc_write
    mov ebx, VGAregister_data
    mov al, [ebx]
    out dx, al

    inc ebx

    mov si, VGA_seq_index
    mov di, VGA_seq_data
    mov cl, 0
    mov ch, VGA_num_seq_regs
    call write_reg_loop

    ; unlock crtc registers
    mov dx, VGA_crtc_index
    mov al, 0x03
    out dx, al
    mov dx, VGA_crtc_data
    in al, dx
    or al, 0x80
    mov dx, VGA_crtc_data
    out dx, al

    mov dx, VGA_crtc_index
    mov al, 0x11
    out dx, al

    mov dx, VGA_crtc_data
    in al, dx
    and al, ~0x80
    out dx, al

    mov al, [VGAregister_data+0x03]
    or al, 0x80
    mov [VGAregister_data+0x03], al

    mov al, [VGAregister_data+0x11]
    and al, ~0x80
    mov [VGAregister_data+0x11], al

    mov si, VGA_crtc_index
    mov di, VGA_crtc_data
    mov cl, 0
    mov ch, VGA_num_crtc_regs
    call write_reg_loop

    mov si, VGA_GC_index
    mov di, VGA_GC_data
    mov cl, 0
    mov ch, VGA_num_GC_regs
    call write_reg_loop

    mov si, VGA_AC_index
    mov di, VGA_AC_write
    mov cl, 0
    mov ch, VGA_num_AC_regs
    call write_reg_loop

    popad
    ret

write_reg_loop: ;si: VGA_index, di: VGA_data, ch: loop end condition, cl: 0, ebx: start of VGAregister_data (will be incremented)
    mov dx, si
    mov al, cl
    out dx, al
    mov dx, di
    mov al, [ebx]
    out dx, al

    inc ebx
    inc cl
    cmp cl, ch
    jl write_reg_loop
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

empty_VGAregister_data_buffer:
    ;miscellaneous register(1)
    db 0
    ;

    ;sequence registers(5)
    db 0
    db 0
    db 0
    db 0
    db 0
    ;

    ;crtc registers(25)
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    ;

    ;graphic's controller(GC) registers(9)
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    ;

    ;attribute controller(AC) registers(21)
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    db 0
    ;


VGAregister_data:
    ;miscellaneous register(1)
    db 0x63
    ;

    ;sequence registers(5)
    db 0x03
    db 0x01
    db 0x0f
    db 0x00
    db 0x0e
    ;

    ;crtc registers(25)
    db 0x05f
    db 0x4f
    db 0x50
    db 0x82
    db 0x54
    db 0x80
    db 0xbf
    db 0x1f

    db 0x00
    db 0x41
    db 0x00
    db 0x00
    db 0x00
    db 0x00
    db 0x00
    db 0x00

    db 0x9c
    db 0x0e
    db 0x8f
    db 0x28
    db 0x40
    db 0x96
    db 0xb9
    db 0xa3
    ;

    ;graphic's controller(GC) registers(9)
    db 0x00
    db 0x00
    db 0x00
    db 0x00
    db 0x00
    db 0x40
    db 0x05
    db 0x0f

    db 0xff
    ;

    ;attribute controller(AC) registers(21)
    db 0x00
    db 0x01
    db 0x02
    db 0x03
    db 0x04
    db 0x05
    db 0x06
    db 0x07

    db 0x08
    db 0x09
    db 0x0a
    db 0x0b
    db 0x0c
    db 0x0d
    db 0x0f
    
    db 0x41
    db 0x00
    db 0x0f
    db 0x00
    db 0x00
    ;
