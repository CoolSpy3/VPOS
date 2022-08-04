idt_install:

    lidt [idt_ptr]

    ret

idt_set_ISR: ; cl: index, rdx: base, si: selector, ch: flags
    pushaq

    mov rbx, idt_structure
    mov al, 8
    mul cl
    add rbx, rax

    mov rax, rdx
    and rax, 0xFFFF
    mov [rbx], rax
    add rbx, 6

    mov rax, rdx
    shr rax, 16
    and rax, 0xFFFF
    mov [rbx], rax
    sub rbx, 4

    mov [rbx], si
    add rbx, 2

    mov [rbx], byte 0
    inc rbx

    mov [rbx], ch

    popaq
    ret


I86_IDT_DESC_PRESENT equ 0x80
I86_IDT_DESC_BIT32 equ 0x0e

idt_ptr:
    limit dw 8*256-1
    base dd idt_structure

idt_structure:
    times 512 dd 0x00
