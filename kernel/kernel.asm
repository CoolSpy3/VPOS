[org 0x1000]
[bits 16]
rm_main: ; Unfortunately we have to execute some real mode code here to read the memory map
	mov ah, 0
	int 0x10

	call feature_check

	call load_mem_map

    mov ax, 0xE801 ; Get length of extended memory
    int 0x15
	jc ext_mem_err ; Function unsupported
	cmp ah, 0x86
	je ext_mem_err ; Function unsupported
	cmp ah, 0x80
	je ext_mem_err ; Invalid command
	cmp ax, cx
	jne ext_mem_err ; assert ax=cx
	cmp bx, dx
	jne ext_mem_err ; assert bx=dx
	ignore_ext_mem_err:
	cmp ax, 0x3C00 ; 15MiB
	jb mem_hole_exists ; The 15MiB hole exists; the code is not built to handle this
	ignore_mem_hole:
	shr dx, 4 ; Convert to num of 1MiB blocks
	add dx, 15 ; 15MiB of memory below 16MiB (No memory hole)
	shr dx, 10 ; Convert to num of 1GiB blocks
	cmp dx, 0
	mov ax, 1
	cmove dx, ax ; Ensure that there is at least 1GiB of memory allocated
    mov [EXT_MEM_LEN], dx
	; This will be an under-approximation, but it's only neccessary to establish page tables
	; until we can update them with a more precise memory map from the E820 function

	cli
	lgdt [gdt_descriptor] ; Load GDT and enable protected mode
	mov eax, cr0
	or eax, 1
	mov cr0, eax

	mov ax, gdt_data_seg ; Set all segment registers (except cs) to the data segment
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov esp, STACK_END

	mov eax, cr4 ; Set PAE (Physical Address Extension) enable bit
	or eax, 0x20
	mov cr4, eax

%include "MMU/gen_page_table.asm"

	mov eax, page_table ; Store the address of the page table in CR3
	mov cr3, eax

	mov ecx, 0xC0000080 ; Enable long mode and XD (Execute Disable)
	rdmsr
	or eax, 0x900
	wrmsr

	mov eax, cr0 ; Enable paging
	or eax, 0x80000000
	mov cr0, eax

    jmp gdt_code_seg:main ; Jump to long mode (0x10 is the offset to the gdt code segment) (see boot_section/pm_files/gdt.asm)


ext_mem_err:
	mov si, MEM_LEN_READ_ERR
	call rm_print
	call rm_dump_regs
	mov si, IGNORE_INFO
	call rm_print
	xor ah, ah
	int 0x16
	jmp ignore_ext_mem_err

mem_hole_exists:
	mov si, MEM_HOLE_ERR
	call rm_print
	call rm_dump_regs
	mov si, IGNORE_INFO
	call rm_print
	xor ah, ah
	int 0x16
	jmp ignore_mem_hole

MEM_LEN_READ_ERR db "Error retrieving length of extended memory!", 0xA, 0xD, 0
MEM_HOLE_ERR db "Error! The system is not designed to handle the 15MiB memory hole!", 0xA, 0xD, 0
IGNORE_INFO db "Press any key to ignore...", 0xA, 0xD, 0

%include "feature_check.asm"
%include "rm_print.asm"
%include "MMU/gdt.asm"
%include "MMU/mem_map.asm"

[bits 64]

%include "util/stackmacros.asm"

main:
    mov rsp, STACK_END
    call kernel_main

jmp $

%include "kernel_main.asm"
%include "disk/ata.asm"
%include "HAL/idt.asm"
%include "HAL/pic.asm"
%include "MMU/init.asm"
%include "MMU/kalloc.asm"
%include "MMU/mmu_debug_tools.asm"
%include "graphics_drivers/vga_logger.asm"
%include "graphics_drivers/vga_serial_driver.asm"
%include "graphics_drivers/vga_textmode_driver.asm"
%include "util/panic.asm"
%include "util/spinlock.asm"

%include "MMU/stack.asm"

EXT_MEM_LEN dw 0
FREE_MEM dq page_table

%include "MMU/padding.asm"

FS_START equ $

page_table equ 0x100000
