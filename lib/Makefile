TARGETS = c64mt.lib
OBJS = irq.o nmi.o coldstart.o startjob.o stopjob.o jobs.o init.o initt.o \
       hgr.o cls.o pot.o line.o swapscr.o setdb.o \
       nrm.o clst.o fillct.o swapscrt.o setdbt.o \
       bitsoff.o bitson.o wait.o mvcrsr.o chrout.o printhex.o scankbd.o
       # volume.o text.o draw.o fill.o \
       #play.o voice.o scroll.o up.o shift.o shape.o sprite.o move.o

all: $(TARGETS)

c64mt.lib: $(OBJS)
	rm -f c64mt.lib
	ar65 r c64mt.lib $(OBJS)

%.o: %.s globals.inc
	ca65 -t c64 -v -g -o $@ $<

clean:
	rm -f *.o *.lib
