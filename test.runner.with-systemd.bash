#!/bin/bash
set -euo pipefail
set -x
export DEBUG
export CVMFS_TEST_PROXY=DIRECT # essential for tests passing
export CVMFS_TEST_USER=$(id -un) # essential for tests passing
export CVMFS_TEST_GROUP=$(id -gn) # essential for tests passing
export USER=$CVMFS_TEST_USER # shouldn't be needed, but...
#export CVMFS_SERVER_DEBUG=4 # 4=rr, see cvmfs_server_coda.sh
export CVMFS_SERVER_DEBUG=3 # 3 means debug binary, see cvmfs_server_coda.sh
pushd test
set +e
#bash -x ./run.sh /dev/stdout -d src/"$1"
#bash -x ./run.sh /var/log/test.log -d src/"$1" # /var/log/test.log: permission denied
bash -x ./run.sh /tmp/test.log -d src/"$1"
RET=$?
set -e
popd

shopt -s nullglob # if glob patterns don't match, they disappear rather than passed literally
killall rsyslogd || true
sudo tar -caf /var/log/tests.logs.tar  /tmp/*test.log /var/log/*.log /var/log/messages* || true
exit $RET
