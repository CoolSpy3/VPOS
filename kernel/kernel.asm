[org 0x1000]
[bits 32]

main:
    mov esp, STACK_END
    call kernel_main

jmp $

%include "kernel_main.asm"
%include "HAL/idt.asm"
%include "HAL/pic.asm"
%include "heapflow/constants.asm"
%include "heapflow/function.asm"
%include "heapflow/interpreter.asm"
%include "MMU/malloc.asm"
%include "fs/filestream.asm"
%include "fs/fs.asm"
%include "graphics_drivers/vga_logger.asm"
%include "graphics_drivers/vga_serial_driver.asm"
%include "graphics_drivers/vga_textmode_driver.asm"
%include "util/arraylist.asm"
%include "util/hashmap.asm"
%include "util/panic.asm"
%include "util/string.asm"
%include "util/spinlock.asm"

%include "MMU/stack.asm"
%include "MMU/ram.asm"

%include "MMU/padding.asm"

FS_START equ $
