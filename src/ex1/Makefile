EXAMPLES = sunandmoon.prg
TARGETS = lib $(EXAMPLES)
OBJS = sunandmoon.o sun.o moon.o town.o

all: $(TARGETS)

sunandmoon.prg: $(OBJS) ../../lib/c64mt.lib
	ld65 -v -Ln sunandmoon.lbl -C ../c64mt.cfg -o $@ $(OBJS) ../../lib/c64mt.lib c64.lib

lib:
	make -C ../../lib

%.o: %.s
	ca65 -t c64 -v -g -o $@ $<

clean:
	rm -f *.o *.prg *.lbl *.d64 *.bin *.seq
