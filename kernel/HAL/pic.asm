
pic_init: ;dl: base0, dh: base1
    pushaq
    mov bl, 0
    
    cli

    and bl, ~I86_PIC_ICW1_MASK_INIT
    or bl, I86_PIC_ICW1_INIT_YES
    and bl, ~I86_PIC_ICW1_MASK_IC4
    or bl, I86_PIC_ICW1_IC4_EXPECT

    mov al, bl
    mov ch, 0
    mov cl, 0
    call pic_send

    mov ch, 1
    mov cl, 0
    call pic_send

    mov al, dl
    mov ch, 0
    mov cl, 1
    call pic_send

    mov al, dh
    mov ch, 1
    mov cl, 1
    call pic_send

    mov al, 0x04
    mov ch, 0
    mov cl, 1
    call pic_send

    mov al, 0x02
    mov ch, 1
    mov cl, 1
    call pic_send

    and bl, ~I86_PIC_ICW4_MASK_UPM
    or bl, I86_PIC_ICW4_UPM_86MODE

    mov al, bl
    mov ch, 0
    mov cl, 1
    call pic_send

    mov ch, 1
    mov cl, 1
    call pic_send

    popaq
    ret

pic_send: ;al: command, ch: pic number, cl: command(not 1) or data(1)
    pushaq

    cmp ch, 1
    jg .return

    cmp ch, 1
    je .setreg1
    jmp .setreg2

    .setreg1:
        cmp cl, 1
        je .setreg1_data

        mov dx, I86_PIC1_REG_COMMAND
        jmp .end

        .setreg1_data:
        mov dx, I86_PIC1_REG_DATA
        jmp .end

    .setreg2:
        cmp cl, 1
        je .setreg2_data

        mov dx, I86_PIC2_REG_COMMAND
        jmp .end

        .setreg2_data:
        mov dx, I86_PIC2_REG_DATA
        jmp .end

    .end:
    out dx, al

    .return:
    popaq
    ret

pic_interupt_done: ;cl: idt index
    pushaq

    cmp cl, 16
    jg .return

    cmp cl, 8
    jnge .end

    mov al, I86_PIC_OCW2_MASK_EOI
    mov ch, 1
    mov cl, 0
    call pic_send

    .end:
    mov al, I86_PIC_OCW2_MASK_EOI
    mov ch, 0
    mov cl, 0
    call pic_send

    .return:
    popaq
    ret


I86_PIC1_REG_COMMAND equ 0x20
I86_PIC1_REG_STATUS	equ 0x20
I86_PIC1_REG_DATA equ 0x21
I86_PIC1_REG_IMR equ 0x21

I86_PIC2_REG_COMMAND equ 0xA0
I86_PIC2_REG_STATUS	equ 0xA0
I86_PIC2_REG_DATA equ 0xA1
I86_PIC2_REG_IMR equ 0xA1

I86_PIC_ICW1_MASK_IC4 equ 0x1
I86_PIC_ICW1_MASK_SNGL equ 0x2
I86_PIC_ICW1_MASK_ADI equ 0x4
I86_PIC_ICW1_MASK_LTIM	equ 0x8
I86_PIC_ICW1_MASK_INIT equ 0x10

I86_PIC_ICW1_IC4_EXPECT equ 1
I86_PIC_ICW1_INIT_YES equ 0x10
I86_PIC_ICW4_MASK_UPM equ 0x1
I86_PIC_ICW4_UPM_86MODE equ 1

I86_PIC_OCW2_MASK_EOI equ 0x20