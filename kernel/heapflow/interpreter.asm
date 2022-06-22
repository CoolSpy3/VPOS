
heapflow_main:
    call parsehf_file_data

parsehf_file_data: ;ebx: file data pointer
    pushad
    .loop:

        .sub_loop:
        



        cmp [ebx], byte 0
        jne .loop


    call malloc

    popad
    