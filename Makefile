# -*- Mode: Makefile; indent-tabs-mode:t; tab-width: 4 -*-

all:

install:
	mkdir -p $(DESTDIR)/bin
	cp -a cron.sh $(DESTDIR)/bin/cron
	chmod a+x $(DESTDIR)/bin/cron
