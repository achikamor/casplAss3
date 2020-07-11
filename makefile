all:ass3

ass3: scheduler.o printer.o drones.o target.o	ass3.o
	gcc -m32    -g  -Wall   -o  ass3  ass3.o	scheduler.o	printer.o	drones.o	target.o	

ass3.o: ass3.s
	nasm    -g  -f  elf32 -w+all  -o  ass3.o   ass3.s

scheduler.o: scheduler.s
	nasm    -g  -f  elf32 -w+all  -o  scheduler.o   scheduler.s

printer.o: printer.s
	nasm    -g  -f  elf32 -w+all  -o  printer.o   printer.s

drones.o: drones.s
	nasm    -g  -f  elf32 -w+all  -o  drones.o   drones.s

target.o: target.s
	nasm    -g  -f  elf32 -w+all  -o  target.o   target.s

.PHONY: clean

clean:
	rm  -f  *.o ass3
