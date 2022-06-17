boot_section.bin:
	nasm boot_section/boot_section.asm -i boot_section/ -f bin -o boot_section.bin

kernel_entry.bin:
	nasm kernel/kernel_entry.asm -i boot_section/ -f bin -o kernel_entry.bin

live-image:
	cat boot_section.bin kernel_entry.bin > live-image

clean-up:
	rm boot_section.bin
	rm kernel_entry.bin

clear_old_image:
ifneq (,$(wildcard ./live-image))
	rm live-image
endif

build: clear_old_image boot_section.bin kernel_entry.bin live-image clean-up

run:
	qemu-system-i386 -drive format=raw,file=live-image

debug:
	qemu-system-i386 -D ./log.txt -d guest_errors -drive format=raw,file=live-image
