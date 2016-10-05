# -*- Mode: Makefile; indent-tabs-mode:t; tab-width: 4 -*-

TEMPDIR := $(shell mktemp -d)

all:

install:
	wget https://www.kernel.org/pub/software/scm/git/git-2.9.3.tar.gz -O $(TEMPDIR)/git.tar.gz
	cd $(TEMPDIR) && tar -xf git.tar.gz
	cd $(TEMPDIR)/git-2.9.3 && ./configure --prefix=/usr --with-curl=/usr/bin && make && make install
	cp -a $(DESTDIR)/usr/libexec/git-core/git-remote* $(DESTDIR)/usr/libexec/git-core/git-credential* $(DESTDIR)/usr/bin

	mkdir -p $(DESTDIR)/bin
	cp -a cron.sh $(DESTDIR)/bin/cron

	mkdir -p $(DESTDIR)/meta/hooks
	cp -a meta/hooks/* $(DESTDIR)/meta/hooks
