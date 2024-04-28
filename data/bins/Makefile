C1541=c1541
GZIP=gzip
PERL=perl

OBJS=focalsda.prg tbascsda.prg tpiltsda.prg kimsda.prg

default: $(OBJS) kim2d64.d64.gz

focalsda.prg: 00TEMPLATE focal1.bin focal2.bin
	$(PERL) gensda.pl $< focal*.bin > $@

tbascsda.prg: 00TEMPLATE tbasic1.bin tbasic2.bin
	$(PERL) gensda.pl $< tbasic*.bin > $@

tpiltsda.prg: 00TEMPLATE tpilot1.bin tpilot2.bin tpilote.bin
	$(PERL) gensda.pl $< tpilot*.bin > $@

kimsda.prg:
	$(PERL) -s gensda.pl \
		-exclude=focal1.bin,focal2.bin,tbasic1.bin,tbasic2.bin,tpilot1.bin,tpilot2.bin,tpilote.bin \
		00TEMPLATE *.bin > $@

clean:
	rm -f $(OBJS) kim2d64.d6*

kim2d64.d64.gz: kim2d64.d64
	$(GZIP) -c < $< > $@

kim2d64.d64: ../../kim.prg
	$(C1541) -format "kimplement,cp" d64 kim2d64.d64 \
		-write ../../kim.prg kim \
		`ls -1 *.bin | $(PERL) -ne 'chomp;print "-write $$_ "'`
