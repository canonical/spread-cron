# -*- Mode: Makefile; indent-tabs-mode:t; tab-width: 4 -*-

all:

install:
	mkdir -p $(DESTDIR)/bin $(DESTDIR)/meta/hooks
	cp -a cron.sh $(DESTDIR)/bin/cron
	cp -a meta/hooks/* $(DESTDIR)/meta/hooks
	chmod a+x $(DESTDIR)/bin/cron
