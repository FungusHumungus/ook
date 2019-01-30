ook
===

A simple command line snippet manager.

To build assuming ocaml and opam are set up, from the ook folder :

```
> opam install ANSITerminal
> make
```

Then add `ook.native` to your path. Something like

```
> sudo cp ./ook.native /usr/local/bin/ook
```

To get autocompletion in zsh, add this to your .zshrc: 

```
fpath=(~/.ookc $fpath)
autoload -U compinit
compinit
```

copy _ook to ~/.ookc

To create an ook snippet called hoogle that will run the command `stack hoogle -- server --local --port 8888`:


```
> ook -a hoogle "stack hoogle -- server --local --port 8888"
```

Then whenever you want to run your command 

```
> ook hoogle
```

Alternatively edit your ~/.ook file. 

If you need parameters in your command you can use $OOKn where n is a sequential number (starting from 0) to specify a substitution. For example if you want to grep your daily log for errors and the log has a different name every day you can create a snippet like :

```
> ook -a errorlog "grep error \$OOK0.log"
```

(Note you need to escape the $ if adding from the command line.

Then run your snippet like :

```
> ook errorlog 2018-01-01
```

