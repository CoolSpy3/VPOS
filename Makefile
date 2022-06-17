-include bin/boot_section.d
-include bin/kernel.d

bin:
	mkdir bin

bin/boot_section.bin: bin boot_section/boot_section.asm
	nasm boot_section/boot_section.asm -i boot_section/ -f bin -o bin/boot_section.bin -M -MF bin/boot_section.d
	nasm boot_section/boot_section.asm -i boot_section/ -f bin -o bin/boot_section.bin

bin/kernel.bin: bin kernel/kernel.asm
	nasm kernel/kernel.asm -i kernel/ -f bin -o bin/kernel.bin -M -MF bin/kernel.d
	nasm kernel/kernel.asm -i kernel/ -f bin -o bin/kernel.bin

bin/live-image: bin/boot_section.bin bin/kernel.bin
	cat bin/boot_section.bin bin/kernel.bin > bin/live-image

.PHONY: build rebuild clean run debug

build: bin/live-image

rebuild: | clean build

clean:
	rm -rf bin

run: bin/live-image
	qemu-system-i386 -drive format=raw,file=bin/live-image

debug: bin/live-image
	qemu-system-i386 -D ./log.txt -d guest_errors -drive format=raw,file=bin/live-image
