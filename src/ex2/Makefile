EXAMPLES = samevents.prg
TARGETS = $(EXAMPLES)
OBJS = samevents.o outhex.o outdec.o irq.o console.o sun.o moon.o town.o

all: $(TARGETS)

samevents.prg: $(OBJS)
	ld65 -v -Ln samevents.lbl -C ../c64mt.cfg -o $@ $(OBJS) ../../lib/c64mt.lib c64.lib

%.o: %.s
	ca65 -t c64 -v -g -o $@ $<

clean:
	rm -f *.o *.prg *.lbl *.d64 *.bin *.seq
