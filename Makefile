ifeq ($(OS),Windows_NT)
-include bin/boot_section.bin.d
-include bin/kernel.d
PYTHON = python
else
PYTHON = python3
endif

-include bin/filesystem.d

bin/boot_section.bin: boot_section/boot_section.asm bin/kernel.bin bin/kernel.size bin/filesystem.size bin/filesystem.bin.fatSize
	mkdir -p $(@D)
	nasm boot_section/boot_section.asm -f bin -o bin/boot_section.bin -MD bin/boot_section.d -MP -werror \
		-dkernel_size=$(shell cat bin/kernel.size) \
		-dfat_size=$(shell cat bin/filesystem.bin.fatSize) \
		-dfilesystem_size=$(shell cat bin/filesystem.size)

bin/kernel.bin bin/kernel.size: kernel/kernel.asm
	mkdir -p $(@D)
	nasm kernel/kernel.asm -f bin -o bin/kernel.bin -MD bin/kernel.d -MP -werror
	wc -c < bin/kernel.bin > bin/kernel.size
	awk '{ print $$1/512 }' bin/kernel.size > bin/kernel.size.tmp
	cat bin/kernel.size.tmp > bin/kernel.size
	rm bin/kernel.size.tmp

bin/live-image.bin: bin/boot_section.bin bin/kernel.bin bin/filesystem.bin
	cat bin/boot_section.bin bin/kernel.bin bin/filesystem.bin > bin/live-image.bin

bin/filesystem.bin bin/filesystem.size bin/filesystem.bin.fatSize: filesystem/build_filesystem.py filesystem/filesystem_builder_utils.py
	mkdir -p bin/dynamicFiles
	$(PYTHON) filesystem/build_filesystem.py filesystem/staticFiles bin/dynamicFiles . bin/filesystem.bin
	wc -c < bin/filesystem.bin > bin/filesystem.size
	awk '{ print $$1/512 }' bin/filesystem.size > bin/filesystem.size.tmp
	cat bin/filesystem.size.tmp > bin/filesystem.size
	rm bin/filesystem.size.tmp

bin/disk.vdi: bin/live-image
	rm -f bin/disk.vdi
	VBoxManage convertfromraw bin/live-image bin/disk.vdi --format VMDK --uuid=a39e995d-b264-448c-b706-55884f79253c

.PHONY: build rebuild clean run debug disk run-vbox

build: bin/live-image.bin

rebuild: | clean build

clean:
	rm -rf bin

run: bin/live-image.bin
	qemu-system-x86_64 -drive format=raw,file=bin/live-image.bin

debug: bin/live-image.bin
	qemu-system-x86_64 -D ./log.txt -d guest_errors -drive format=raw,file=bin/live-image.bin

disk: bin/disk.vdi

run-vbox: bin/disk.vdi
	VBoxManage startvm VPOS

%.mem:
	VBoxManage debugvm VPOS dumpvmcore --filename=$@
