%ifndef KERNEL
%define KERNEL

[org 0x1000]
[bits 16]

%include "common/system_constants.asm"

rm_main: ; Unfortunately we have to execute some real mode code here to read the memory map
	mov ah, SET_VIDEO_MODE_COMMAND ; Clear the screen by setting the graphcs mode
	mov al, VIDEO_MODE_TEXT_MODE
	int VIDEO_SERVICES_INTERRUPT

	mov ah, SET_CURSOR_POS_COMMAND ; Disable the cursor
	mov ch, CURSOR_OPTIONS_INVISIBLE
	mov cl, 0
	int VIDEO_SERVICES_INTERRUPT

	call feature_check

	call load_mem_map

    mov ax, GET_EXT_MEM_LEN_COMMAND
    int MISC_SERVICES_INTERRUPT
	jc ext_mem_err ; Function unsupported
	cmp ah, 0x86 ; These magic numbers come from here:https://wiki.osdev.org/Detecting_Memory_(x86)#BIOS_Function:_INT_0x15.2C_AX_.3D_0xE801
	je ext_mem_err ; Function unsupported
	cmp ah, 0x80
	je ext_mem_err ; Invalid command
	cmp ax, cx
	jne ext_mem_err ; assert ax=cx
	cmp bx, dx
	jne ext_mem_err ; assert bx=dx
	ignore_ext_mem_err:
	cmp ax, 0x3C00 ; 15MiB
	jb mem_hole_exists ; The 15MiB hole exists; the code is not built to handle this (Or the BIOS is lying)
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

	cli ; We are about to invalidate the IVT, so interrupts will cause a triple-fault
	    ; Some BIOS interrupts seem to re-set the interrupt flag (see note in disk-load.asm) https://media.tenor.com/t6V-MIkkT8kAAAAd/
	lgdt [gdt_descriptor] ; Load GDT and enable protected mode
	mov eax, cr0
	or eax, PROTECTED_MODE_ENABLE_BIT
	mov cr0, eax

	mov ax, gdt_data_seg ; Set all segment registers (except cs) to the data segment
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov esp, STACK_END

	mov eax, cr4 ; Set PAE (Physical Address Extension) enable bit
	or eax, PAE_ENABLE_BIT
	mov cr4, eax

	%include "kernel/MMU/gen_page_table.asm"

	mov eax, page_table ; Store the address of the page table in CR3
	mov cr3, eax

	mov ecx, IA32_EFER_MSR ; Enable long mode and XD (Execute Disable)
	rdmsr
	or eax, IA32_EFER_LME | IA32_EFER_NXE
	wrmsr

	mov eax, cr0 ; Enable paging
	or eax, PAGING_ENABLE_BIT
	mov cr0, eax

    jmp gdt_code_seg:main ; Jump to long mode

ext_mem_err:
	mov si, MEM_LEN_READ_ERR
	call rm_print
	call rm_dump_regs
	mov si, IGNORE_INFO
	call rm_print
	mov ah, READ_KEY_COMMAND
	int KEYBOARD_SERVICES_INTERRUPT
	jmp ignore_ext_mem_err

mem_hole_exists:
	mov si, MEM_HOLE_ERR
	call rm_print
	call rm_dump_regs
	mov si, IGNORE_INFO
	call rm_print
	mov ah, READ_KEY_COMMAND
	int KEYBOARD_SERVICES_INTERRUPT
	jmp ignore_mem_hole

MEM_LEN_READ_ERR db `Error retrieving length of extended memory!\n\r`, 0
MEM_HOLE_ERR db `Error! The system is not designed to handle the 15MiB memory hole!\n\r`, 0
IGNORE_INFO db `Press any key to ignore...\n\r`, 0

%include "common/rm_print.asm"
%include "kernel/feature_check.asm"
%include "kernel/MMU/gdt.asm"
%include "kernel/MMU/mem_map.asm"

[bits 64]

%include "kernel/util/stackmacros.asm"

main:
    mov rsp, STACK_END
    call kernel_main

jmp $ ; If/when kernel_main returns, we have nothing else to do, so we just loop forever

%include "kernel/kernel_main.asm"

%include "kernel/MMU/stack.asm"

EXT_MEM_LEN dw 0
FREE_MEM dq EXT_MEM_START

%include "kernel/MMU/padding.asm"

KERNEL_END equ $ ; The start of the file system on the disk
KERNEL_LEN equ KERNEL_END - $$ ; The start of the file system on the disk

mem_map equ 0x500 ; Address at which to store the memory map

page_table equ EXT_MEM_START ; Address at which to generate the page tables

EXT_MEM_START equ 0x100000 ; The start of extended memory

%endif
