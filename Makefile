ifeq ($(OS),Windows_NT)
-include bin/boot_section.d
-include bin/kernel.d
endif

bin/boot_section.bin: boot_section/boot_section.asm
	mkdir -p $(@D)
	nasm boot_section/boot_section.asm -i boot_section/ -f bin -o bin/boot_section.bin -MD bin/boot_section.d -MP

bin/kernel.bin: kernel/kernel.asm
	mkdir -p $(@D)
	nasm kernel/kernel.asm -i kernel/ -f bin -o bin/kernel.bin -MD bin/kernel.d -MP

bin/live-image: bin/boot_section.bin bin/kernel.bin bin/fs
	cat bin/boot_section.bin bin/kernel.bin > bin/live-image

bin/disk.vdi: bin/live-image
	rm -f bin/disk.vdi
	VBoxManage convertfromraw bin/live-image bin/disk.vdi --format VMDK --uuid=a39e995d-b264-448c-b706-55884f79253c

.PHONY: build rebuild clean run debug disk run-vbox

build: bin/live-image

rebuild: | clean build

clean:
	rm -rf bin

run: bin/live-image
	qemu-system-i386 -drive format=raw,file=bin/live-image

debug: bin/live-image
	qemu-system-i386 -D ./log.txt -d guest_errors -drive format=raw,file=bin/live-image

disk: bin/disk.vdi

run-vbox: bin/disk.vdi
	VBoxManage startvm VPOS

%.mem:
	VBoxManage debugvm VPOS dumpvmcore --filename=$@
