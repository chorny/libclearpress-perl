MAJOR    ?= 473
MINOR    ?= 0
PATCH    ?= 2
CODENAME ?= $(shell lsb_release -cs)
MD5SUM    = md5sum
SEDI      = sed -i

ifeq ($(shell uname), Darwin)
        MD5SUM = md5 -r
        SEDI   = sed -i ""
endif

all:	setup
	./Build

versions:
	find lib bin t -type f -exec perl -i -pe 's/VERSION\s+=\s+q[[\d.]+]/VERSION = q[$(MAJOR).$(MINOR).$(PATCH)]/g' {} \;

setup:
	perl Build.PL

manifest: setup
	./Build manifest

clean:	setup
	./Build clean
	touch tmp
	rm -rf build.tap MYMETA.yml MYMETA.json _build Build rpmbuild spec tmp *rpm *deb *tar.gz test.db MANIFEST.bak

test:	setup
	TEST_AUTHOR=1 ./Build test verbose=1

cover:	setup
	./Build testcover verbose=1

install:	setup
	./Build install

dist:	setup
	./Build dist

deb:	manifest
	make test
	touch tmp
	rm -rf tmp
	mkdir -p tmp/usr/lib/perl5
	cp -pR deb-src/* tmp/
	cp tmp/DEBIAN/control.tt2 tmp/DEBIAN/control
	$(SEDI) "s/MAJOR/$(MAJOR)/g" tmp/DEBIAN/control
	$(SEDI) "s/MINOR/$(MINOR)/g" tmp/DEBIAN/control
	$(SEDI) "s/PATCH/$(PATCH)/g" tmp/DEBIAN/control
	$(SEDI) "s/RELEASE/$(RELEASE)/g" tmp/DEBIAN/control
	$(SEDI) "s/CODENAME/$(CODENAME)/g" tmp/DEBIAN/control
	rsync --exclude .svn --exclude .git -va lib/* tmp/usr/lib/perl5/
	rsync --exclude .svn --exclude .git -va bin/* tmp/usr/bin/
	find tmp -type f ! -regex '.*\(\bDEBIAN\b\|\.\bsvn\b\|\bdeb-src\b\|\.\bgit\b\|\.\bsass-cache\b\|\.\bnetbeans\b\).*'  -exec $(MD5SUM) {} \; | sed 's/tmp\///' > tmp/DEBIAN/md5sums
	(cd tmp; fakeroot dpkg -b . ../libclearpress-perl-$(MAJOR).$(MINOR)-$(PATCH)~$(CODENAME).deb)

cpan:	clean
	make dist
	cpan-upload ClearPress-v$(MAJOR).$(MINOR).$(PATCH).tar.gz
