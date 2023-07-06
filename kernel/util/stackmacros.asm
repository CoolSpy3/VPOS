%ifndef UTIL_STACKMACROS
%define UTIL_STACKMACROS
[bits 64]

%macro pushaq 0
push rax
push rbx
push rcx
push rdx
push rsi
push rdi
%endmacro

%macro popaq 0
pop  rdi
pop  rsi
pop  rdx
pop  rcx
pop  rbx
pop  rax
%endmacro

%endif
