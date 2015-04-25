all: utf8filter

OPTS=-principal -safe-string -strict-formats -w +A
SRC=utf8f.mli utf8f.ml utf8filter.ml

utf8filter: $(SRC)
	ocamlopt $(OPTS) -o $@ $(SRC)
	ocamlc -compat-32 $(OPTS) -o $@b $(SRC)
	rm *.cm? *.o

.PHONY: clean
clean:
	rm *.cm? *.o
