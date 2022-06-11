[org 0x1000]
[bits 32]

main:
    mov [0xb8000], byte 'X'

jmp $

times 15*256 dw 0xDADA