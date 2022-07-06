arraylist_test:
    call arraylist_new

    mov ebx, test_string

    mov cl, 0

    .loop:
        call arraylist_add
        inc cl
        cmp cl, 20
        jne .loop


    mov ebx, 15
    call arraylist_get

    ret


test_string db 'test12323', 0
