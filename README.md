# Ways to test CVMFS

This repository contains tools to build and test CVMFS codbase.
This is being built for a personal need not covered by upstream repo tools:

* run end-to-end tests locally and not through Github Actions;
* use reproducible base systems to run tests (GHA worker images are defined but not distributed, and too big to be useful);
* fast incremental rebuilds and test runs;
* run end to end tests in parallel;
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

```
git clone --bare https://github.com/andrey-utkin/ways-to-test-cvmfs ways-to-test-cvmfs.git
git clone ways-to-test-cvmfs.git ways-to-test-cvmfs
git clone --bare https://github.com/andrey-utkin/cvmfs.git cvmfs.git
cd ways-to-test-cvmfs
./create-vm-archlinux
```

To access the resulting VM, run `incus shell ways-to-test-cvmfs-archlinux`
