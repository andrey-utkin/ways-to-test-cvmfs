# Make each subdir, supporting multiple top-level targets.
# https://stackoverflow.com/a/17845120

TOPTARGETS := tests.done unittests.done clean mrproper debug builder.image.done builder.image.remake build.done pooled.ci.status pooled.ci.clean pooled.ci.done pool-teardown pooled.ci.done-and-torndown git-fetch-reset wipe-build wipe-build-image wipe-build-except-externals s3_test.teardown rr.done rr.build.done tests.update.incremental tests.update.clean report-build.done report-make report

#SUBDIRS ?= $(wildcard vanilla/*/*/)
SUBDIRS ?= $(wildcard testability/*/*/)

## Those which don't require x86-64-v3:
#SUBDIRS := $(wildcard upstream/centos_9/*/ upstream/fedora_42/*/)


default: tests.done

$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: $(TOPTARGETS) $(SUBDIRS)

.PRECIOUS: iplocation.mmdb
iplocation.mmdb:
	curl -L -sS --connect-timeout 10 --max-time 60 --retry 2 https://geoipdb.openhtc.io/iplocation.mmdb.gz -o iplocation.mmdb.gz
	gunzip iplocation.mmdb.gz

geodb-install-into-container: iplocation.mmdb
	${ENGINE} exec ${CONTAINER_NAME} mkdir -p /var/lib/cvmfs-server/geo
	${ENGINE} cp $< ${CONTAINER_NAME}:/var/lib/cvmfs-server/geo/


# experiment with -k and shell-command
# tmux send-keys -t $${NEW_PANE} "make tests.monitor"
# floating panes: NEW_PANE=$$(tmux new-pane -v -c ${PWD}/$${x} -d);
.PHONY: tmux-panes
tmux-panes:
	exec make --jobs=$(shell nproc) --load-average=$(shell nproc) tmux-panes-with-jobserver

.PHONY: tmux-panes-with-jobserver
tmux-panes-with-jobserver:
	echo $${MAKEFLAGS} | grep jobserver
	export MAKEFLAGS; \
	for x in ${SUBDIRS}; do \
		NEW_PANE=$$(tmux split-window -c ${PWD}/$${x} -d -e MAKEFLAGS="$${MAKEFLAGS}"); \
		tmux select-layout tiled; \
	done
	cat # consume terminal input to avoid commands execution afterwards
	# jobserver lives until this target script terminates

echo-make:
	env | grep -i make
	JOBSERVER_PATH=$$(printf %s "${MAKEFLAGS}" | grep -o '[-]-jobserver-auth=fifo:[/]tmp[/]GMfifo[0-9]\+' | cut -d : -f 2); \
		       echo JOBSERVER_PATH=$${JOBSERVER_PATH}
