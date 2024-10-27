all: system
	objcopy -I elf64-x86-64 -S -R ".eh_frame" -R ".comment" -O binary system kernel.bin

system: head.o main.o printK.o entry.o trap.o memory.o
	@echo "----------------Link head.o main.o printK.o entry.o trap.o memory.o"
	ld -b elf64-x86-64 -z muldefs -g -o system head.o entry.o trap.o main.o printK.o memory.o -T Kernel.lds

head.o: head.S
	gcc -E head.S > head.s
	as --64 -o  head.o -g head.s

entry.o: entry.S
	gcc -E  entry.S > entry.s
	as --64 -o entry.o -g entry.s

trap.o: trap.c
	@echo "----------------Compiling trap.c"
	gcc  -mcmodel=large -fno-builtin -m64 -c -g trap.c

memory.o: memory.c
	@echo "----------------Compiling memory.c"
	gcc -mcmodel=large -fno-builtin -m64 -c -g memory.c

main.o: main.c
	@echo "----------------Compiling main.c"
	gcc -mcmodel=large -fno-builtin -m64 -c -g main.c

printK.o: printK.c
	@echo "----------------Compiling printK.c"
	gcc -mcmodel=large -fno-builtin -m64 -c -g printK.c -fno-stack-protector -O3

clean:
	rm -rf *.o *.s~ *.s *.S~ *.c~ *.h~ system  Makefile~ Kernel.lds~ kernel.bin