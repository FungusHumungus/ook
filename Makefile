BUILD=ocamlbuild
OCAMLFLAGS=-cflag -annot -use-ocamlfind -pkgs str,ANSITerminal 
ook.native: ook.ml

	$(BUILD) $(OCAMLFLAGS) ook.native
