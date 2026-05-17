# Make each subdir, supporting multiple top-level targets.
# https://stackoverflow.com/a/17845120

TOPTARGETS := tests.done clean mrproper debug builder.image.done build.done

# Upstream needs systemd to toggle httpd, and systemd breaks my machine in privileged mode
#SUBDIRS := $(wildcard sth-else/*/*/. upstream/*/*/.)
SUBDIRS := $(wildcard testability/*/*/.)

## Those which don't require x86-64-v3:
#SUBDIRS := $(wildcard upstream/centos_9/*/. upstream/fedora_42/*/. )


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
