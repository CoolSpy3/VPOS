%ifndef KERNEL_PADDING
%define KERNEL_PADDING

PADDING_START equ $

PADDING_LEN equ 512 - ( ( $ - $$ ) % 512 )

times PADDING_LEN db 0

%endif
