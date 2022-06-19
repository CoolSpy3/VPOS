idt_install:

    lidt [idt_ptr]

    ret

idt_set_ISR: ; cl: index, edx: base, si: selector, ch: flags
    pushad

    mov ebx, idt_structure
    mov al, 8
    mul cl
    add ebx, eax

    mov eax, edx
    and eax, 0xFFFF
    mov [ebx], eax
    add ebx, 6

    mov eax, edx
    shr eax, 16
    and eax, 0xFFFF
    mov [ebx], eax
    sub ebx, 4

    mov [ebx], si
    add ebx, 2

    mov [ebx], byte 0
    inc ebx

    mov [ebx], ch

    popad
    ret


idt_ptr:
    limit dw 8*256-1
    base dd idt_structure

idt_structure:
    times 512 dd 0x00
