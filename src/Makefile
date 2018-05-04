EXAMPLES = dbuf.prg dbuft.prg sunandmoon samevents
TARGETS = lib c64mt.d64 $(EXAMPLES)

all: $(TARGETS)

c64mt.d64: $(EXAMPLES)
	rm -f c64mt.d65
	c1541 -format diskname,id d64 c64mt.d64 -attach c64mt.d64 \
		-write dbuf.prg dbuf \
		-write dbuft.prg dbuft \
		-write ex1/sunandmoon.prg sunandmoon \
		-write ex2/samevents.prg samevents

dbuf.prg: dbuf.o irq.o tabnar.o ../lib/c64mt.lib
	ld65 -v -Ln dbuf.lbl -C c64mt.cfg -o $@ dbuf.o irq.o tabnar.o ../lib/c64mt.lib c64.lib

dbuft.prg: dbuft.o irq.o ../lib/c64mt.lib
	ld65 -v -Ln dbuft.lbl -C c64mt.cfg -o $@ dbuft.o irq.o ../lib/c64mt.lib c64.lib

lib:
	make -C ../lib

sunandmoon:
	make -C ex1

samevents:
	make -C ex2

%.o: %.s
	ca65 -t c64 -v -g -o $@ $<

clean:
	make -C ex1 clean
	make -C ex2 clean
	make -C ../lib clean
	rm -f *.o *.prg *.lbl *.d64 *.bin *.seq
