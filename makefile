#  UTF-8 Filter tool 3 (OCaml 4.02)
#  Harrison Ainsworth / HXA7241 : 2015


EXE=utf8filter
SRC=utf8filter.mli utf8filter.ml utf8filtertool.ml
OPTS=-principal -safe-string -strict-formats -w +A

all: $(EXE)

$(EXE): $(SRC)
	ocamlopt $(OPTS) -o $@ $(SRC)
	ocamlc -compat-32 $(OPTS) -o $@b $(SRC)
	rm *.cm? *.o

.PHONY: clean
clean:
	rm -f *.cm? *.o
	rm -f $(EXE) $(EXE)b
