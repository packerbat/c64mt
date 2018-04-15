EXAMPLES = dbuf.prg bees.prg
TARGETS = lib c64mt.d64 $(EXAMPLES)

all: $(TARGETS)

c64mt.d64: $(EXAMPLES)
	rm -f c64mt.d65
	c1541 -format diskname,id d64 c64mt.d64 -attach c64mt.d64 \
		-write dbuf.prg dbuf \
		-write bees.prg bees

dbuf.prg: dbuf.o ../lib/c64mt.lib
	ld65 -v -Ln dbuf.lbl -C c64mt.cfg -o $@ dbuf.o ../lib/c64mt.lib c64.lib

bees.prg: bees.o ../lib/c64mt.lib
	ld65 -v -Ln bees.lbl -C c64mt.cfg -o $@ bees.o ../lib/c64mt.lib c64.lib

lib:
	make -C ../lib

%.o: %.s
	ca65 -t c64 -v -g -o $@ $<

clean:
	rm -f *.o *.prg *.lbl *.d64 *.bin *.seq
