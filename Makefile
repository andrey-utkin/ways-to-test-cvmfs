-include *.mk

# Make each subdir, supporting multiple top-level targets.
# https://stackoverflow.com/a/17845120

TOPTARGETS := \
    tests.done \
    tests-extended.done \
    unittests.done \
    clean \
    mrproper \
    debug \
    builder.image.done \
    builder.image.remake \
    build.done \
    pooled.ci.status \
    pooled.ci.clean \
    pooled.ci.done \
    pool-teardown \
    pooled.ci.done-and-torndown \
    pooled.s3_ci.status \
    pooled.s3_ci.teardown \
    pooled.s3_ci.clean \
    pooled.s3_ci.quick.done \
    pooled.s3_ci.quick.done-and-torndown \
    pooled.s3_ci.all.done \
    pooled.s3_ci.all.done-and-torndown \
    git-fetch-reset \
    wipe-build \
    wipe-build-image \
    wipe-build-except-externals \
    s3_test.teardown \
    s3_test.quick.teardown \
    s3_test.all.teardown \
    franken.s3_test.quick.teardown \
    franken.s3_test.all.teardown \
    s3_test.quick.clean \
    s3_test.all.clean \
    franken.s3_test.quick.clean \
    franken.s3_test.all.clean \
    s3_test.quick.done \
    s3_test.all.done \
    rr.done \
    rr.build.done \
    build.update \
    build.update.clean \
    build.update.incremental \
    tests.clean \
    tests.update \
    tests.update.or-rerun \
    build.report \
    report-make \
    report \
    tests.email \
    tests-extended.email \
    tests.teardown \
    tests-extended.teardown \


FLAVOUR ?= testability

# Exclude "ACT" as it's special
SUBDIRS_VANILLA := $(wildcard vanilla/*/[a-z]*/)
SUBDIRS_TESTABILITY := $(wildcard testability/*/[a-z]*/)
SUBDIRS ?= $(wildcard ${FLAVOUR}/*/[a-z]*/)
## Those which don't require x86-64-v3:
#SUBDIRS := $(wildcard upstream/centos_9/*/ upstream/fedora_42/*/)


default: tests.done

$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: $(TOPTARGETS) $(SUBDIRS)

%.act.done: ${FLAVOUR}/podman/ACT
	cd $< && ${MAKE} $@

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

.PHONY: tmux-panes-vanilla
tmux-panes-vanilla:
	make tmux-panes SUBDIRS="${SUBDIRS_VANILLA}"

.PHONY: tmux-panes-testability
tmux-panes-testability:
	make tmux-panes SUBDIRS="${SUBDIRS_TESTABILITY}"

TESTS_MONITOR_LOOP_GOAL ?= tests.update
#TESTS_MONITOR_LOOP_GOAL ?= tests.update.or-rerun

.PHONY: tests.monitor
tests.monitor:
	export SUBDIRS BUILD_UPDATE_POLICY; \
	set -e; \
	while true; do ${MAKE} ${TESTS_MONITOR_LOOP_GOAL}; sleep 5m; done

.PHONY: tests.monitor.vanilla
tests.monitor.vanilla:
	export BUILD_UPDATE_POLICY SUBDIRS="${SUBDIRS_VANILLA}"; \
		${MAKE} tests.monitor

.PHONY: tests.monitor.testability
tests.monitor.testability:
	export BUILD_UPDATE_POLICY SUBDIRS="${SUBDIRS_TESTABILITY}"; \
		${MAKE} tests.monitor

echo-make:
	env | grep -i make
	JOBSERVER_PATH=$$(printf %s "${MAKEFLAGS}" | grep -o '[-]-jobserver-auth=fifo:[/]tmp[/]GMfifo[0-9]\+' | cut -d : -f 2); \
		       echo JOBSERVER_PATH=$${JOBSERVER_PATH}
