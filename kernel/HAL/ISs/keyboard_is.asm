%ifndef KERNEL_KEYBOARD_IS
%define KERNEL_KEYBOARD_IS

[bits 64]

%include "kernel/HAL/idt.asm"
%include "kernel/HAL/pic.asm"

keyboard_install_is:
    pushaq

    mov cl, 33
    mov rbx, keyboard_isr
    mov si, 0x8
    mov ch, I86_IDT_DESC_PRESENT
    or ch, I86_IDT_DESC_BIT32
    call idt_set_ISR

    popaq
    ret


keyboard_isr:
    add esp, 12
    pushaq
    cli

    mov dx, keyboard_CTRL_command_reg
    in al, dx
    cmp al, 0
    je .return

    ; cmp keyboard_CTRL_STATS_mask_out_buffer, 0 ; This evaluates to cmp 1, 0 which doesn't make sense, so ima comment this out for now
    je .return

    .return:

    mov cl, 0
    call pic_interupt_done

    sti
    popaq
    iretd

keyboard_enc_input_buffer equ 0x60
keyboard_CTRL_command_reg equ 0x64
keyboard_CTRL_STATS_mask_out_buffer equ 1

%endif
