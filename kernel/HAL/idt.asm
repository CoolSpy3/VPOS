
idt_install:
    pushad

    mov al, 8
    mov cl, 256 
    mul cl

    sub ax, 1
    mov [idt_ptr], ax

    lea ebx, idt_structure
    mov [idt_ptr + 2], ebx

    lidt [idt_ptr]

    popad
    ret

idt_setgate:; cl: index, edx: base, si: selector, ch: flags
    pushad

    mov ebx, idt_structure
    mov al, 8
    mul cl
    add ebx, ax

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

    mov [ebx], 0
    inc ebx

    mov [ebx], ch

    popad
    ret


idt_ptr:
    limit dw 0x00
    base dd 0x00

idt_structure:
    times 512 dd 0x00
        