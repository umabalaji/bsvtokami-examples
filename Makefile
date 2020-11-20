


all: Makefile.coq kami/Kami/Kami.vo
	make -f Makefile.coq

kami/Kami/Kami.vo:
	cd kami; make

Makefile.coq:
	coq_makefile -R kami/Kami Kami -R bk BK -R src src bk/*.v src/*.v -o Makefile.coq

clean:
	rm -f Makefile.coq */*.vo* */*.aux */*.glob
