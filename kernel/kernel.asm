[org 0x1000]
[bits 32]
pm_main: ; Unfortunately we have to execute some protected mode code here because the paging datastructures are too large for the first sector
	mov eax, cr4 ; Set PAE (Physical Address Extension) enable bit
	or eax, 0x20
	mov cr4, eax

	jmp gen_page_table ; Jump (instead of call) so nothing gets pushed to the stack

cont_pm: ; Return from gen_page_table
	mov eax, page_table ; Store the address of the page table in CR3
	mov cr3, eax

	mov ecx, 0xC0000080 ; Enable long mode
	rdmsr
	or eax, 0x100
	wrmsr

	mov eax, cr0 ; Enable paging
	or eax, 0x80000000
	mov cr0, eax

    jmp 0x10:main ; Jump to long mode (0x10 is the offset to the gdt code segment) (see boot_section/pm_files/gdt.asm)

%include "MMU/page_table.asm"

[bits 64]

%include "util/stackmacros.asm"

main:
    mov rsp, STACK_END
    call kernel_main

jmp $

%include "kernel_main.asm"
%include "HAL/idt.asm"
%include "HAL/pic.asm"
%include "MMU/malloc.asm"
%include "MMU/malloc_debug_tools.asm"
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

page_table equ 0x100000
