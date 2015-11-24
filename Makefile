PROGNAME=guess_the_number
ASSEMBLE=nasm -f elf64
LD=ld

.PHONY: all clean cleanall

all: $(PROGNAME).executable

cleanall: clean
	rm -f $(PROGNAME)

clean:
	rm -f *.o

%.executable: %.o
	$(LD) $< -o $*

%.o: %.asm
	$(ASSEMBLE) $< -o $@
