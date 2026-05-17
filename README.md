# Ways to test CVMFS

This repository contains tools to build and test CVMFS codbase.
This is being built for a personal need not covered by upstream repo tools:

* run end-to-end tests locally and not through Github Actions;
* use reproducible base systems to run tests (GHA worker images are defined but not distributed, and too big to be useful);
* fast incremental rebuilds and test runs;
* run tests in parallel;
* run end to end tests separately from the rest.

It turned out there are plenty of accidental quirks where tests run OK (or
pretend to run OK) in GHA but fail in a different (but not necessarily faulty)
environment. Many such quirks have been worked around and documented, some
tests have been excluded, but still 3/4 (around 170 out of 230) of end-to-end
tests can be relied upon, which is quite good.

## Setup

It is recommended to use a dedicated virtual machine with at least 2GiB RAM and at least 1 core.

**Privileged containers with systemd on bare metal Linux will mess up your graphical desktop system state.**

A suitable VM can be automatically set up with a script supplied. The script uses Incus hypervisor.

```bash
git clone --bare https://github.com/andrey-utkin/ways-to-test-cvmfs ways-to-test-cvmfs.git
git clone ways-to-test-cvmfs.git ways-to-test-cvmfs
git clone --bare https://github.com/andrey-utkin/cvmfs.git cvmfs.git
cd ways-to-test-cvmfs
./create-vm-archlinux
```

To access the resulting VM, run `incus shell ways-to-test-cvmfs-archlinux`

### Demo

To view how the setup will go, run:

```bash
asciinema play https://autkin.net/tmp/wtt-setup.asciicast
```

(The recording is slightly over 16M so can't be uploaded to asciinema.org)


## Use

```bash
cd /usr/local/src/ways-to-test-cvmfs # base dir
cd testability # "flavour" - the level of hierarchy meant for various builds of any one particular branch
cd podman # "engine" - containerization engine used, docker is another option
cd ubuntu_24.04 # "distro"
make unittests-fast.done # majority subset of unittests with slow ones excluded, ran in parallel, very fast
make unittests-parallel.done # all unittests except excluded, ran in parallel, fast
make pooled.ci.done # launches a pool of containers (by number of cores), run end-to-end tests in them in parallel
make pooled.ci.status # neat summary - size of pool, run duration (so far), count of failed vs passed, list of failed tests
make NPROC=8 pooled.ci.done # override container pool size
make ci.done # run end-to-end tests in disposable containers. NPROC jobs in parallel. Slower than pooled.ci.done
make ci_ubuntu.sh.done # Closely resembles ci_ubuntu.yml GHA job - end-to-end tests ran serially. Slow.
make ci.500-mkrepo.done # Run any end-to-end test in a fresh container.
```

### Demo

```bash
# Inside VM:
 $ cd /usr/local/src/ways-to-test-cvmfs # base dir
 $ ls
ccache
ci.sh
ci_ubuntu.sh
common_makefile
create-vm-archlinux
cvmfs.git
_distros
go_pkg_mod
list-active-e2e-tests
list-active-e2e-tests.ci_ubuntu
list-active-tests.ci_ubuntu
Makefile
one-ci-test.sh
pooled.ci.create-containers
pooled.ci.one-test
testability
test.runner.with-systemd.bash
tests.excludes.list
work.sh
```

```bash
 $ cd /usr/local/src/ways-to-test-cvmfs # base dir
 $ make tests.done # all tests in all distros
```
[![asciicast](https://asciinema.org/a/yCGB9EQ6sRYjjRi1.svg)](https://asciinema.org/a/yCGB9EQ6sRYjjRi1)

(`asciinema play https://autkin.net/tmp/wtt-make-tests.asciicast`)

In the base directory, you create directories for "flavours", which mean a direction of work, most probably a specific branch of codebase, common for all workcopies under it.

You can use either podman or docker, or both at the same time to see how tests work in them.

```bash
 $ cd testability # "flavour" - the level of hierarchy meant for various builds of any one particular branch
 $ ls
podman

 $ cd podman # "engine" - containerization engine used, docker is another option
 $ ls
almalinux_9
centos_9
fedora_43
ubuntu_24.04

 $ cd ubuntu_24.04 # "distro"
 $ ls -l
total 8
-rw-r--r--  1 root root    0 May 17 14:30 build.done
-rw-r--r--  1 root root    0 May 17 14:17 builder.image.done
drwxr-xr-x 23 root root 4096 May 17 14:29 cvmfs
-rw-r--r--  1 root root   40 May 17 13:11 local.mk
lrwxrwxrwx  1 root root   24 May 17 13:11 Makefile -> ../../../common_makefile
```
