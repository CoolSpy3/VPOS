boot_section.bin:
	nasm boot_section/boot_section.asm -i boot_section/ -f bin -o boot_section.bin

kernel_entry.o:
	nasm kernel/kernel_entry.asm -i kernel/ -f elf -o kernel_entry.o

kernel.o:
	x86_64-elf-gcc -m32 -ffreestanding -c kernel/kernel.c -o kernel.o

kernel.bin:
	/opt/homebrew/opt/x86_64-elf-binutils/bin/x86_64-elf-ld kernel_entry.o kernel.o -o kernel.bin -m elf_i386 -Ttext 0x1000 -nostdlib --oformat binary

live-image:
	cat boot_section.bin kernel.bin > live-image

clean-up:
	rm kernel_entry.o
	rm kernel.o
	rm boot_section.bin
	rm kernel.bin

all: boot_section.bin kernel_entry.o kernel.o kernel.bin live-image clean-up

