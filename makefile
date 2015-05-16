#  UTF-8 Filter tool 3 (OCaml 4.02)
#  Harrison Ainsworth / HXA7241 : 2015


EXE=utf8filter
LIB=utf8filter
LIBSRC=utf8filter.mli utf8filter.ml
EXESRC=$(LIBSRC) utf8filtertool.ml
OPTS=-principal -safe-string -strict-formats -w +A


all: exes libs

exes: $(EXE) $(EXE)b
$(EXE): $(EXESRC)
	ocamlopt.opt -o $(EXE) $(OPTS) $(EXESRC)
	rm -f *.cm[xo] *.o utf8filtertool.cmi
$(EXE)b: $(EXESRC)
	ocamlc.opt -o $(EXE)b -compat-32 $(OPTS) $(EXESRC)
	rm -f *.cm[xo] *.o utf8filtertool.cmi

libs: $(LIB).cmi $(LIB).cmxa $(LIB).cma $(LIB).a
$(LIB).cmi $(LIB).cmxa $(LIB).cma: $(LIBSRC)
	ocamlopt.opt -a -o $(LIB).cmxa $(OPTS) $(LIBSRC)
	ocamlc.opt -a -o $(LIB).cma -compat-32 $(OPTS) $(LIBSRC)
	rm -f *.cm[xo] *.[o]


.PHONY: clean
clean:
	rm -f *.cm[ixo] *.[ao]
	rm -f $(EXE) $(EXE)b $(LIB).cmi $(LIB).cmxa $(LIB).cma $(LIB).a
