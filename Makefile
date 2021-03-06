PREFIX ?= /usr/local
CFLAGS ?= -O3 -g -Wall
LDFLAGS ?= -lm

MANDIR = $(PREFIX)/share/man
MAN1DIR = $(MANDIR)/man1

LIN_CFLAGS = $(CFLAGS)
LIN_LDFLAGS = $(LDFLAGS)

PY_CFLAGS = $(LIN_CFLAGS) `pkg-config --cflags python-2.7` -I.
PY_LDFLAGS = $(LIN_LDFLAGS) `pkg-config --libs python-2.7`

ANDROID_DIR = android
ANDROID_SRC = $(ANDROID_DIR)/src/org/pk/
ANDROID_ANT_FILE = $(ANDROID_DIR)/build.xml
ANDROID_RES_FILES = \
	$(ANDROID_DIR)/res/layout/triggercord.xml \
	$(ANDROID_DIR)/res/layout/main.xml \
	$(ANDROID_DIR)/res/layout/settings.xml \
	$(ANDROID_DIR)/res/layout-land-hdpi/triggercord.xml \
	$(ANDROID_DIR)/res/values/strings.xml \
	$(ANDROID_DIR)/res/menu/triggercord.xml
	
APK_FILE = Triggercord-debug.apk
NDK_BUILD = ndk-build

VERSION=0.79.01
# variables for RPM creation
TOPDIR=$(HOME)/rpmbuild
SPECFILE=pktriggercord.spec

# variables for DEB creation
DEBEMAIL="andras.salamon@melda.info"
DEBFULLNAME="Andras Salamon"

# variables for RPM/DEB creation
DESTDIR ?=

LIN_GUI_LDFLAGS=$(shell pkg-config --libs gtk+-2.0 libglade-2.0)
LIN_GUI_CFLAGS=$(CFLAGS) $(shell pkg-config --cflags gtk+-2.0 libglade-2.0)

default: cli pktriggercord
all: srczip rpm win pktriggercord_commandline.html
cli: pktriggercord-cli

MANS = pktriggercord-cli.1 pktriggercord.1
OBJS = pslr.o pslr_enum.o pslr_scsi.o pslr_lens.o pslr_model.o
WIN_DLLS_DIR=win_dlls
SOURCE_PACKAGE_FILES = Makefile Changelog COPYING INSTALL BUGS $(MANS) pentax.rules samsung.rules pslr_enum.h pslr_enum.c pslr_scsi.h pslr_scsi.c pslr_scsi_linux.c pslr_scsi_win.c pslr_model.h pslr_model.c pslr.h pslr.c exiftool_pentax_lens.txt pslr_lens.h pslr_lens.c pktriggercord.c pktriggercord-cli.c pktriggercord.glade $(SPECFILE)
TARDIR = pktriggercord-$(VERSION)
SRCZIP = pkTriggerCord-$(VERSION).src.tar.gz

WINGCC=i586-pc-mingw32-gcc
WINMINGW=/usr/i586-pc-mingw32/sys-root/mingw
WINDIR=$(TARDIR)-win

pslr.o: pslr_enum.o pslr_scsi.o pslr.c pslr.h

pktriggercord-cli: pktriggercord-cli.c $(OBJS)
	$(CC) $(LIN_CFLAGS) $^ -DVERSION='"$(VERSION)"' -o $@ $(LIN_LDFLAGS) -L. 

%.o : %.c %.h
	$(CC) $(LIN_CFLAGS) -fPIC -c $<

pktriggercord: pktriggercord.c $(OBJS)
	$(CC) $(LIN_GUI_CFLAGS) -DVERSION='"$(VERSION)"' -DDATADIR=\"$(PREFIX)/share/pktriggercord\" $? $(LIN_LDFLAGS) -o $@ $(LIN_GUI_LDFLAGS) -L. 

install:
	install -d $(DESTDIR)/$(PREFIX)/bin
	install -s -m 0755 pktriggercord-cli $(DESTDIR)/$(PREFIX)/bin/
	install -d $(DESTDIR)/etc/udev/rules.d
	install -m 0644 pentax.rules $(DESTDIR)/etc/udev/
	install -m 0644 samsung.rules $(DESTDIR)/etc/udev/
	cd $(DESTDIR)/etc/udev/rules.d;\
	ln -sf ../pentax.rules 025_pentax.rules;\
	ln -sf ../samsung.rules 025_samsung.rules
	install -d -m 0755 $(DESTDIR)/$(MAN1DIR)
	install -m 0644 $(MANS) $(DESTDIR)/$(MAN1DIR)
	if [ -e ./pktriggercord ] ; then \
	install -s -m 0755 pktriggercord $(DESTDIR)/$(PREFIX)/bin/; \
	install -d $(DESTDIR)/$(PREFIX)/share/pktriggercord/; \
	install -m 0644 pktriggercord.glade $(DESTDIR)/$(PREFIX)/share/pktriggercord/ ; \
	fi

clean:
	rm -f pktriggercord pktriggercord-cli *.o
	rm -f pktriggercord.exe pktriggercord-cli.exe
	rm -rf python
	rm -rf $(ANDROID_DIR)/bin
	rm -rf $(ANDROID_DIR)/gen
	rm -rf $(ANDROID_DIR)/libs
	rm -rf $(ANDROID_DIR)/obj
	rm -f $(ANDROID_DIR)/jni/pentax_wrap.cpp
	rm -f $(ANDROID_SRC)/Camera.java
	rm -f $(ANDROID_SRC)/pentax*.java
	rm -f $(ANDROID_ANT_FILE)

uninstall:
	rm -f $(PREFIX)/bin/pktriggercord $(PREFIX)/bin/pktriggercord-cli
	rm -rf $(PREFIX)/share/pktriggercord
	rm -f /etc/udev/pentax.rules
	rm -f /etc/udev/rules.d/025_pentax.rules
	rm -f /etc/udev/samsung.rules
	rm -f /etc/udev/rules.d/025_samsung.rules

srczip: clean
	mkdir -p $(TARDIR)
	cp -r $(SOURCE_PACKAGE_FILES) $(TARDIR)/
	mkdir -p $(TARDIR)/$(WIN_DLLS_DIR)
	cp -r $(WIN_DLLS_DIR)/*.dll $(TARDIR)/$(WIN_DLLS_DIR)/
	mkdir -p $(TARDIR)/debian
	cp -r debian/* $(TARDIR)/debian/
	tar cf - $(TARDIR) | gzip > $(SRCZIP)
	rm -rf $(TARDIR)

srcrpm: srczip
	install $(SPECFILE) $(TOPDIR)/SPECS/
	install $(SRCZIP) $(TOPDIR)/SOURCES/
	rpmbuild -bs $(SPECFILE)
	cp $(TOPDIR)/SRPMS/pktriggercord-$(VERSION)-1.src.rpm .

rpm: srcrpm
	rpmbuild -ba $(SPECFILE)
	cp $(TOPDIR)/RPMS/i386/pktriggercord-$(VERSION)-1.i386.rpm .

WIN_CFLAGS=$(CFLAGS) -I$(WINMINGW)/include/gtk-2.0/ -I$(WINMINGW)/lib/gtk-2.0/include/ -I$(WINMINGW)/include/atk-1.0/ -I$(WINMINGW)/include/cairo/ -I$(WINMINGW)/include/gdk-pixbuf-2.0/ -I$(WINMINGW)/include/pango-1.0/ -I$(WINMINGW)/include/libglade-2.0/
WIN_GUI_CFLAGS=$(WIN_CFLAGS) -I$(WINMINGW)/include/glib-2.0 -I$(WINMINGW)/lib/glib-2.0/include 
WIN_LDFLAGS=-lgtk-win32-2.0 -lgdk-win32-2.0 -lgdk_pixbuf-2.0 -lgobject-2.0 -lglib-2.0 -lgio-2.0  -lglade-2.0

deb: srczip
	rm -f pktriggercord*orig.tar.gz
	rm -f pktriggercord*debian.tar.gz
	rm -f pktriggercord*armhf*
	rm -rf pktriggercord-$(VERSION)
	tar xvfz pkTriggerCord-$(VERSION).src.tar.gz
	cd pktriggercord-$(VERSION);\
	echo '' | dh_make --single -f ../pkTriggerCord-$(VERSION).src.tar.gz;\
	cp ../debian/* debian/;\
	find debian/ -size 0 | xargs rm -f;\
	dpkg-buildpackage -us -uc

# converting lens info from exiftool
exiftool_pentax_lens.txt:
	cat /usr/lib/perl5/vendor_perl/5.12.3/Image/ExifTool/Pentax.pm | sed -n '/%pentaxLensTypes\ =/,/%pentaxModelID/p' | sed -e "s/[ ]*'\([0-9]\) \([0-9]\{1,3\}\)' => '\(.*\)',.*/{\1, \2, \"\3\"},/g;tx;d;:x" > $@

pktriggercord_commandline.html: pktriggercord-cli.1
	groff $< -man -Thtml -mwww -P "-lr" > $@

# Windows cross-compile
win: clean pktriggercord_commandline.html
	$(WINGCC) $(WIN_CFLAGS) -c pslr_lens.c
	$(WINGCC) $(WIN_CFLAGS) -c pslr_scsi.c
	$(WINGCC) $(WIN_CFLAGS) -c pslr_enum.c
	$(WINGCC) $(WIN_CFLAGS) -c pslr_model.c
	$(WINGCC) $(WIN_CFLAGS) -c pslr.c
	$(WINGCC) -mms-bitfields -DVERSION='"$(VERSION)"'  pktriggercord-cli.c $(OBJS) -o pktriggercord-cli.exe $(WIN_CFLAGS) $(WIN_LDFLAGS) -L.
	$(WINGCC) -mms-bitfields -DVERSION='"$(VERSION)"' -DDATADIR=\".\" pktriggercord.c $(OBJS) -o pktriggercord.exe $(WIN_GUI_CFLAGS) $(WIN_LDFLAGS) -L.
	mkdir -p $(WINDIR)
	cp pktriggercord.exe pktriggercord-cli.exe pktriggercord.glade Changelog COPYING pktriggercord_commandline.html $(WINDIR)
	cp $(WIN_DLLS_DIR)/*.dll $(WINDIR)
	rm -f $(WINDIR).zip
	zip -rj $(WINDIR).zip $(WINDIR)
	rm -r $(WINDIR)

python-bindings: $(OBJS)
	mkdir -p python
	swig -c++ -python -o python/pentax_wrap.cpp pentax.h
	$(CXX) -fPIC $(OBJS) -DVERSION=\"$(VERSION)\" python/pentax_wrap.cpp pentax.cpp $(PY_CFLAGS) $(PY_LDFLAGS) --shared -o python/_pentax.so

$(ANDROID_DIR)/build.xml:
	android update project --path $(ANDROID_DIR) --target android-12

$(ANDROID_DIR)/bin/$(APK_FILE): \
		pentax.cpp pentax.h *.c $(ANDROID_SRC)/*.java $(ANDROID_DIR)/build.xml $(ANDROID_RES_FILES)
	swig -c++ -java -package org.pk \
		-outdir $(ANDROID_SRC) \
		-o $(ANDROID_DIR)/jni/pentax_wrap.cpp pentax.h
	VERSION=$(VERSION) NDK_PROJECT_PATH=$(ANDROID_DIR) NDK_DEBUG=1 $(NDK_BUILD)
	ant -f $(ANDROID_ANT_FILE) debug

apk: $(ANDROID_DIR)/bin/$(APK_FILE)

apk-debug-install: $(ANDROID_DIR)/bin/$(APK_FILE)
	ant -f $(ANDROID_ANT_FILE) installd

apk-install: $(ANDROID_DIR)/bin/$(APK_FILE)
	ant -f $(ANDROID_ANT_FILE) installr

	

	
