#!/bin/bash
#export CVMFS_SERVER_DEBUG=3 # 3 means debug binary, see cvmfs_server_coda.sh

cd test

export CVMFS_TESTCASES=$(ls -d src/0* src/1* src/5* src/6* src/7* src/8*)
export CVMFS_TEST_SUITES=quick

CVMFS_TEST_PROXY=DIRECT \
CVMFS_TEST_USER=$(id -un) \
CVMFS_TEST_GROUP=$(id -gn) \
USER=$(id -gn) \
./run.sh /tmp/test.log    \
   -s "${CVMFS_TEST_SUITES}"  \
   -x src/095-fuser   \
      src/004-davinci                              \
      src/005-asetup                               \
      src/007-testjobs                             \
      src/024-reload-during-asetup                 \
      src/056-lowspeedlimit                        \
      src/084-premounted                           \
      src/094-attachmount                          \
      src/104-concurrent_mounts                    \
      src/518-hardlinkstresstest                   \
      src/593-nestedwhiteout                       \
      src/600-securecvmfs                          \
      src/628-pythonwrappedcvmfsserver             \
      src/647-bearercvmfs                          \
      src/672-publish_stats_hardlinks              \
      src/673-acl                                  \
      src/682-enter                                \
      src/684-https_s3                             \
      src/686-azureblob_s3                         \
      src/687-import_s3                            \
      src/692-https_azureblob_s3                   \
      src/702-symlink_caching                      \
      src/803-repository_gateway_large_files       \
      src/811-commit-gateway                       \
      \
      src/059-fallbackproxy \
      src/615-externaldata \
      src/691-metalink \
      \
      src/058-keysdir \
      src/577-garbagecollecthiddenstratum1revision \
      src/580-automaticgarbagecollectionstratum1 \
      src/614-geoservice \
      src/616-blacklistconfigrepo \
      src/618-repometainfo \
      src/621-snapshotallgcall \
      src/627-reflog \
      src/634-reflogchecksum \
      src/638-virtualdir \
      src/685-mkfs_proxy \
      src/699-servermount \
      \
    --                                             \
   "${CVMFS_TESTCASES}"
RET=$?

sudo tar -caf /var/log/tests.logs.tar  /tmp/*test.log /var/log/*.log /var/log/messages* || true
exit $RET
