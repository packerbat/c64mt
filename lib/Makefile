TARGETS = c64mt.lib
OBJS = init.o hgr.o cls.o pot.o line.o swapscr.o setdb.o \
       initt.o nrm.o clst.o swapscrt.o setdbt.o
       # wait.o volume.o text.o line.o draw.o fill.o \
       #play.o voice.o irq.o scroll.o up.o shift.o shape.o sprite.o move.o

all: $(TARGETS)

c64mt.lib: $(OBJS)
	rm -f c64mt.lib
	ar65 r c64mt.lib $(OBJS)

%.o: %.s
	ca65 -t c64 -v -g -o $@ $<

clean:
	rm -f *.o *.lib
