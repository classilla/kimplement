BT	= tools/bt
CP	= cp
RM	= rm
XA	= xa
AWK	= awk
PERL	= perl
LINKB	= tools/linkb
PUCRUNCH= pucrunch

kim.prg: kim.arc
	@echo ""
	${PUCRUNCH} -fshort kim.arc kim.prg
	cd data/bins && ${MAKE}
	@echo ""
	${CP} $@ ../prg/ || echo "never mind"

clean:
	${RM} -f *.o *.sym *.tok *.arc *.prg
	cd data/bins && ${MAKE} clean

%.o: %.asm
	${XA} -o $@ -l $*.sym $<

%.sym: %.o

%.tok: %.bas
	$(PERL) ${BT} --ofile=$@ $<

k6o6.o: 6o6.asm 6o6.def k6o6.def kh6o6.def
	${XA} -DHARNESS=49152 -DVMSADDR=32768 -D'HSTUB="kh6o6.def"' \
		-DCONFIGFILE=6o6.def \
		-DHELPINGS=1 -DFAULTLESS=1 \
		-l k6o6.sym \
		-o k6o6.o 6o6.asm
	# 6o6 cannot be larger than 16K, counting starting address
	[ `ls -l k6o6.o | $(AWK) '{print $$5}'` -lt 16386 ] || exit 1

kd6o6.o: dos51.asm
	${XA} -DSA51=51712 -DBASIC51 -l kd6o6.sym -o kd6o6.o dos51.asm

km6o6.o: km6o6.asm 6o6.def k6o6.def

kh6o6.o: kh6o6.asm 6o6.def k6o6.def kh6o6.def

kim.arc: k6o6.o kh6o6.o km6o6.o klt6o6.o kd6o6.o kim.tok data/6530-2.rom data/6530-3.rom data/led.spr data/tron2.mus data/kim.bmp
	@echo ""
	$(PERL) ${LINKB} --ofile=$@ \
		kim.tok \
		data/led.spr \
		data/tron2.mus \
		data/6530-3.rom data/6530-2.rom \
		k6o6.o kh6o6.o km6o6.o klt6o6.o kd6o6.o \
		data/kim.bmp 

