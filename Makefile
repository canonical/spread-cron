# -*- Mode: Makefile; indent-tabs-mode:t; tab-width: 4 -*-

TEMPDIR := $(shell mktemp -d)
GIT_VERSION := 2.17.1


all:

install:
	wget https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz
	mv git-${GIT_VERSION}.tar.gz $(TEMPDIR)/git.tar.gz
	cd $(TEMPDIR) && tar -xf git.tar.gz --no-same-owner
	cd $(TEMPDIR)/git-${GIT_VERSION} && ./configure --prefix=/usr --with-curl=/usr/bin && make && make install
	cp -a $(DESTDIR)/usr/libexec/git-core/git-remote* $(DESTDIR)/usr/libexec/git-core/git-credential* $(DESTDIR)/usr/bin

	mkdir -p $(DESTDIR)/bin
	cp -a cron.sh $(DESTDIR)/bin/cron

	mkdir -p $(DESTDIR)/meta/hooks
	cp -a meta/hooks/* $(DESTDIR)/meta/hooks
