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

# Necessary only for Archlinux, actually
if [[ -d /etc/httpd/conf/conf.d ]]; then
	sudo -E cvmfs_config setup
	sudo ln -snvf conf/conf.d /etc/httpd/conf.d
	sudo sed -i /etc/httpd/conf/httpd.conf -e '/LoadModule proxy_module modules\/mod_proxy.so/s/^#//g'
	sudo sed -i /etc/httpd/conf/httpd.conf -e '/LoadModule expires_module modules\/mod_expires.so/s/^#//g'
	sudo systemctl restart httpd || true # what if it's called differently...
fi


set +e
#bash -x ./run.sh /dev/stdout -d src/"$1"
#bash -x ./run.sh /var/log/test.log -d src/"$1" # /var/log/test.log: permission denied
#./run.sh /tmp/test.log -o /tmp/cvmfs-s3-test.log.xunit.xml -p s3 -- src/902*
#./run.sh /tmp/test.log -o /tmp/cvmfs-s3-test.log.xunit.xml -p s3 -- src/901* src/902*
./run.sh /tmp/test.log -o /tmp/cvmfs-s3-test.log.xunit.xml -p s3 -- src/5* src/6* src/901* src/902*
#./run.sh /tmp/test.log -o /tmp/cvmfs-s3-test.log.xunit.xml -p s3
RET=$?
set -e
popd

shopt -s nullglob # if glob patterns don't match, they disappear rather than passed literally
killall rsyslogd || true
sudo tar -caf /var/log/tests.logs.tar  /tmp/*test.log /var/log/*.log /var/log/messages* || true
#cat /tmp/test.log || true
exit $RET
