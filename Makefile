ifeq ($(OS),Windows_NT)
-include bin/boot_section.d
-include bin/kernel.d
PYTHON = python
else
PYTHON = python3
endif

-include bin/filesystem.d

bin/as_kernel.asm: arsenic/kernel_entry.as
	mkdir -p $(@D)
	$(ARSENIC_EXE) -I arsenic -M bin/as_kernel.d -P -T bin/as_kernel.asm -o bin/as_kernel.asm arsenic/kernel_entry.as

bin/boot_section.bin: boot_section/boot_section.asm bin/kernel.bin bin/filesystem.fatSize
	mkdir -p $(@D)
	nasm boot_section/boot_section.asm -i boot_section/ -i common/ -i fat/ -f bin -o bin/boot_section.bin -MD bin/boot_section.d -MP \
		-dkernel_size=$(shell wc -c < bin/kernel.bin) \
		-dfat_size=$(shell cat bin/filesystem.fatSize)

bin/kernel.bin: kernel/kernel.asm
	mkdir -p $(@D)
	nasm kernel/kernel.asm -i kernel/ -i common/ -f bin -o bin/kernel.bin -MD bin/kernel.d -MP

bin/live-image: bin/boot_section.bin bin/kernel.bin bin/filesystem
	cat bin/boot_section.bin bin/kernel.bin bin/filesystem > bin/live-image

bin/filesystem bin/filesystem.fatSize:
	mkdir -p bin/dynamicFiles
	$(PYTHON) filesystem/build_filesystem.py filesystem/staticFiles bin/dynamicFiles . bin/filesystem

bin/disk.vdi: bin/live-image
	rm -f bin/disk.vdi
	VBoxManage convertfromraw bin/live-image bin/disk.vdi --format VMDK --uuid=a39e995d-b264-448c-b706-55884f79253c

.PHONY: build rebuild clean run debug disk run-vbox

build: bin/live-image

rebuild: | clean build

clean:
	rm -rf bin

run: bin/live-image
	qemu-system-x86_64 -drive format=raw,file=bin/live-image

debug: bin/live-image
	qemu-system-x86_64 -D ./log.txt -d guest_errors -drive format=raw,file=bin/live-image

disk: bin/disk.vdi

run-vbox: bin/disk.vdi
	VBoxManage startvm VPOS

%.mem:
	VBoxManage debugvm VPOS dumpvmcore --filename=$@
