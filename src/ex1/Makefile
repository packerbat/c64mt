EXAMPLES = sunandmoon.prg
TARGETS = $(EXAMPLES)
OBJS = sunandmoon.o irq.o sun.o moon.o town.o

all: $(TARGETS)

sunandmoon.prg: $(OBJS)
	ld65 -v -Ln sunandmoon.lbl -C ../c64mt.cfg -o $@ $(OBJS) ../../lib/c64mt.lib c64.lib

%.o: %.s
	ca65 -t c64 -v -g -o $@ $<

clean:
	rm -f *.o *.prg *.lbl *.d64 *.bin *.seq
