boot_section.bin:
	nasm boot_section/boot_section.asm -i boot_section/ -f bin -o boot_section.bin

kernel_entry.bin:
	nasm kernel/kernel_entry.asm -i boot_section/ -f bin -o kernel_entry.bin

live-image:
	cat boot_section.bin kernel_entry.bin > live-image

clean-up:
	rm boot_section.bin
	rm kernel_entry.bin

all: boot_section.bin kernel_entry.bin live-image clean-up

