%ifndef KERNEL_PADDING
%define KERNEL_PADDING

%include "common/system_constants.asm"

PADDING_START equ $

PADDING_LEN equ SECTOR_LENGTH - ( ( $ - $$ ) % SECTOR_LENGTH )

times PADDING_LEN db 0

%endif
