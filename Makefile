ifeq ($(OS),Windows_NT)
-include bin/boot_section.d
-include bin/kernel.d
-include bin/fs.d
endif

bin:
	mkdir bin

bin/boot_section.bin: bin boot_section/boot_section.asm
	nasm boot_section/boot_section.asm -i boot_section/ -f bin -o bin/boot_section.bin -MD bin/boot_section.d

bin/kernel.bin: bin kernel/kernel.asm
	nasm kernel/kernel.asm -i kernel/ -f bin -o bin/kernel.bin -MD bin/kernel.d

bin/fs: bin fs/buildfs.py
	python fs/buildfs.py fs bin/fs

bin/live-image: bin/boot_section.bin bin/kernel.bin bin/fs
	cat bin/boot_section.bin bin/kernel.bin bin/fs > bin/live-image

.PHONY: build rebuild clean run debug

build: bin/live-image

rebuild: | clean build

clean:
	rm -rf bin

run: bin/live-image
	qemu-system-i386 -drive format=raw,file=bin/live-image

debug: bin/live-image
	qemu-system-i386 -D ./log.txt -d guest_errors -drive format=raw,file=bin/live-image
