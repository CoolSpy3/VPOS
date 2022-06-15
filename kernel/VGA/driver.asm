dump_state: ; probably unnecessary,
            ; but if I have a more basic print function
            ; it might be useful.
    call read_regs
    call dump_regs

dump_regs: ; probably unnecessary,
           ; but if I have a more basic print function
           ; it might be useful.
    push cl
    add empty_VGAregister_data_buffer, 8

    ; semantics(just a ton of reg dump loop calls)
    ; to lazy to finish it

    pop cl
    ret

reg_dump_loop:
    push ch
    mov ch, 0

    reg_loop0:
        inc ch
        cmp ch, 8
        jl reg_loop0_maybe

        mov ch, 0

        reg_loop0_maybe:
        add empty_VGAregister_data_buffer, 8
        dec cl
        cmp cl, 0
        jne reg_loop0
        


    pop ch
    ret

read_regs: ; probably unnecessary,
           ; but if I have a more basic print function
           ; it might be useful.
    push ax
    push si
    push di
    push ch

    in ax, VGA_misc_read
    mov [empty_VGAregister_data_buffer], ax

    add empty_VGAregister_data_buffer, 8

    mov si, VGA_seq_index ; VGA_index
    mov di, VGA_seq_data ; VGA_data
    mov ch, 5 ; loop end condition
    call reg_read_loop ; call

    mov si, VGA_crtr_index
    mov di, VGA_crtr_data
    mov ch, 25
    call reg_read_loop

    mov si, VGA_GC_index
    mov di, VGA_GC_data
    mov ch, 9
    call reg_read_loop


    mov si, VGA_AC_index
    mov di, VGA_AC_read
    mov ch, 21
    call reg_read_loop

    in ax, VGA_instat_read
    out VGA_AC_index, 0x20

    pop ax
    pop si
    pop di
    pop ch
    ret

    
reg_read_loop: ;si: VGA_index, di: VGA_data, ch: loop end condition
    push cl ; counter
    mov cl, 0 ; set to 0

    out si, cl
    in ax, di
    mov [empty_VGAregister_data_buffer], ax
    inc cl
    add empty_VGAregister_data_buffer, 8

    cmp cl, ch
    jne reg_read_loop

    pop cl
    ret

write_regs:
    push ax
    push si
    push di
    push ch

    out VGA_misc_write, [VGAregister_data]
    add VGAregister_data, 8

    mov si, VGA_seq_index
    mov di, VGA_seq_data
    mov ch, 5

    ; unlock crtc registers
    out VGA_crtr_index, 0x03
    in ax, VGA_crtr_data
    or ax, 0x80
    out VGA_crtr_data, ax


    out VGA_crtr_index, 0x11
    in ax, VGA_crtr_data

    mov si, 0x80
    not si
    and ax, si

    out VGA_crtr_data, ax
    ;

    sub VGAregister_data, 37
    mov si, 0x80
    not si
    and [VGAregister_data], si

    sub VGAregister_data, 8
    or [VGAregister_data], 0x80
    add VGAregister_data, 45


    mov si, VGA_crtr_index
    mov di, VGA_crtr_data
    mov ch, 25
    call write_reg_loop



    pop ax
    pop si
    pop di
    pop ch
    ret

write_reg_loop: ;si: VGA_index, di: VGA_data, ch: loop end condition
    push cl
    mov cl, 0

    out si, cl
    out di, [VGAregister_data]

    inc cl
    cmp cl, ch
    jne write_reg_loop

    pop cl
    ret

VGA_seq_index db 0x3c4
VGA_seq_data db 0x3c5
VGA_crtr_index db 0x3d4
VGA_crtr_data db 0x3d5
VGA_GC_index db 0x3ce
VGA_GC_data db 0x3cf
VGA_AC_index db 0x3c0

VGA_instat_read db 0x3da
VGA_AC_read db 0x3c1
VGA_misc_read db 0x3cc
VGA_misc_write db 0x3c2

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

