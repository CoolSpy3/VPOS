%ifndef KERNEL_STACK
%define KERNEL_STACK

STACK_START equ $

stack: times 2*512 db 0

STACK_END equ $

%endif
