include check.mk
include graph.mk

GET         = curl -s -L -o $@
ASSERT_HEAD = test `git rev-parse $(1)^{}` = `git rev-parse HEAD`
TAR_GZ_MAIN = $(addprefix lua-, $(addsuffix .tar.gz, $(MAIN_VERSIONS)))
TAR_GZ_WORK = $(addprefix lua-, $(addsuffix .tar.gz, $(WORK_VERSIONS)))

export GIT_COMMITTER_NAME = repogen
export GIT_COMMITTER_EMAIL =
export GIT_AUTHOR_NAME = Lua Team
export GIT_AUTHOR_EMAIL = team@lua.org

all: $(TAGS)/5.3.0

$(TAGS)/%: lua-%/
	@if test -z '$(RELEASE_DATE)'; then \
	  echo 'Error: No RELEASE_DATE set for $*' >&2; \
	  exit 1; \
	fi
	@if test '$*' != 1.0; then \
	  cd $(REPO) && $(call ASSERT_HEAD, $(notdir $(word 2, $^))); \
	fi
	rm -rf $(REPO)/*
	cp -rf lua-$*/* $(REPO)
	git -C $(REPO) add .
	git -C $(REPO) commit -m 'Lua $*'
	git -C $(REPO) tag -m 'Lua $*' $*
	test -z '$(EXTRA_TAG)' || git -C $(REPO) tag -m 'Lua $*' $(EXTRA_TAG)
	cd $(REPO) && $(call ASSERT_HEAD, $*)

lua-%/: lua-%.tar.gz
	$(RM) -r $@ TMP
	mkdir TMP
	cp $< TMP
	cd TMP && tar xzf $<
	mv TMP/$(or $(TARDIR),$@) $@
	$(RM) -r TMP
	touch $@

$(TAR_GZ_MAIN): lua-%.tar.gz:
	$(GET) http://www.lua.org/ftp/$@

$(TAR_GZ_WORK): lua-%.tar.gz:
	$(GET) http://www.lua.org/work/old/$@

$(REPO)/:
	git init $@
	git -C $@ remote add github git@github.com:lua/lua.git

fetch: | $(TAR_GZ_MAIN) $(TAR_GZ_WORK)

check: sha1sums.txt | $(TAR_GZ_MAIN) $(TAR_GZ_WORK)
	sha1sum -c $<

clean:
	$(RM) -r $(REPO) lua-*/

clean-all: clean
	$(RM) lua-*.tar.gz


.PHONY: all fetch check clean clean-all
.SECONDARY:
.NOTPARALLEL:
