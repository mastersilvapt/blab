##
## $ make && sudo make install -> install to /usr/bin/blab, and samples to /usr/share/blab
##

DESTDIR=
PREFIX=/usr
CFLAGS=-Wall -O3
CC=gcc
OFLAGS=-O1
W32GCC=i586-mingw32msvc-gcc # sudo apt-get install mingw32 @ debian squeeze
INSTALL=install
OL=owl-lisp/bin/ol

everything: bin/blab seal-of-quality doc/blab.1.gz

bin/blab: blab.c
	mkdir -p bin
	$(CC) $(CFLAGS) -o bin/blab blab.c

bin/blab.exe: blab.c
	which $(W32GCC)
	$(W32GCC) $(CFLAGS) -o bin/blab.exe blab.c -lwsock32

blab.c: blab.scm
	make get-owl
	echo "(define-library (settings) (import (owl base)) (export default-library-path) (begin (define default-library-path \"$(DESTDIR)$(PREFIX)/share/blab\")))" > settings.scm
	$(OL) $(OFLAGS) -o blab.c blab.scm

blab.fasl: blab.scm
	echo "(define-library (settings) (import (owl base)) (export default-library-path) (begin (define default-library-path \"$(DESTDIR)$(PREFIX)/share/blab\")))" > settings.scm
	$(OL) -o blab.fasl blab.scm

blab.fasl.ok: blab.fasl
	cd tests && ./run.sh ../owl-lisp/bin/vm ../blab.fasl
	touch blab.fasl.ok

bytecode:
	$(OL) -O0 -x c -o - blab.scm | $(CC) -O -x c -o bin/blab -

install: bin/blab doc/blab.1.gz seal-of-quality
	$(INSTALL) -d -m 755 $(DESTDIR)$(PREFIX)/bin
	$(INSTALL) -d -m 755 $(DESTDIR)$(PREFIX)/share/blab
	$(INSTALL) -d -m 755 $(DESTDIR)$(PREFIX)/share/man/man1
	$(INSTALL) -m 755 bin/blab $(DESTDIR)$(PREFIX)/bin
	$(INSTALL) -m 644 lib/*.blab $(DESTDIR)$(PREFIX)/share/blab
	$(INSTALL) -m 644 doc/blab.1.gz $(DESTDIR)$(PREFIX)/share/man/man1

seal-of-quality: bin/blab
	cd tests && ./run.sh ../bin/blab
	touch seal-of-quality

doc/blab.1.gz: doc/blab.1
	cat doc/blab.1 | gzip -9 > doc/blab.1.gz

# run tests against bin/blab
test: seal-of-quality

# run tests against a bytecode image (to avoid the long C-compile part)
testi: blab.fasl
	cd tests && ./run.sh owl-vm ../blab.fasl

clean:
	-rm blab.c bin/* seal-of-quality doc/blab.1.gz settings.scm blab.fasl

uninstall:
	rm $(DESTDIR)$(PREFIX)/bin/blab
	rm -rf $(DESTDIR)$(PREFIX)/share/blab
	rm $(DESTDIR)$(PREFIX)/share/man/man1/blab.1.gz

get-owl:
	# need to install owl to be able to compile blab
	# this may take a moment depending on your machine
	-git clone https://gitlab.com/owl-lisp/owl owl-lisp
	-cd owl-lisp && git pull 
	cd owl-lisp && make

.PHONY: install clean test everything uninstall testi get-owl

