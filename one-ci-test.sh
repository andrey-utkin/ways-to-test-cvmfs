#!/bin/bash
set -euo pipefail
set -x

# one test name is the parameter for now, but this could change
[[ $# == 1 ]]

#export DOCKER_HOST=unix:///run/podman/podman.sock
#PRIORITIZE=(nice -n19  ionice -c3  taskset --cpu-list $(( RANDOM % "$(nproc)" )) )
#PRIORITIZE=(nice -n19  ionice -c3)
PRIORITIZE=()

CONTAINER_ID=$(
	"${PRIORITIZE[@]}" ${ENGINE} run --detach --rm --privileged --network=private --device=/dev/fuse --cap-add=SYS_PTRACE --tmpfs /cvmfs --tmpfs /var/spool/cvmfs -v "${WORKCOPY_IN_HOST}":"${WORKCOPY_IN_CONTAINER}" -v "${LIBDNF5_CACHE_IN_HOST}":/var/cache/libdnf5 "${BUILD_IMAGE_NAME}" /sbin/init
)
cleanup() {
	"${PRIORITIZE[@]}" ${ENGINE} exec "${CONTAINER_ID}" systemctl poweroff || true
	# ${ENGINE} stop "${CONTAINER_ID}" || true
}
trap cleanup HUP INT TERM EXIT
"${PRIORITIZE[@]}" ${ENGINE} exec --workdir "${WORKCOPY_IN_CONTAINER}" "${CONTAINER_ID}" bash -c 'while ! systemctl status &> /dev/null; do echo -n .; sleep 1; done'
"${PRIORITIZE[@]}" ${ENGINE} exec --workdir "${WORKCOPY_IN_CONTAINER}" "${CONTAINER_ID}" bash -x cvmfs_config setup
#${ENGINE} exec --workdir "${WORKCOPY_IN_CONTAINER}" "${CONTAINER_ID}" useradd -m sftnight || true
#${ENGINE} exec --workdir "${WORKCOPY_IN_CONTAINER}" "${CONTAINER_ID}" bash -c 'echo "sftnight ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers'

EXEC_LOG=ci."$1".log
set +e
"${PRIORITIZE[@]}" ${ENGINE} exec --workdir "${WORKCOPY_IN_CONTAINER}" -u sftnight "${CONTAINER_ID}" ./test.runner.with-systemd.bash "$@" &> "$EXEC_LOG"
RC=$?
set -e
logs_filename=$(mktemp --tmpdir=. --suffix=.tar ci."$1".logs.XXXXXXX)
"${PRIORITIZE[@]}" ${ENGINE} cp "${CONTAINER_ID}":/var/log/tests.logs.tar "$logs_filename" || true
trap - HUP INT TERM EXIT
cleanup
if [[ -f "$logs_filename" ]]; then
	"${PRIORITIZE[@]}" zstd --fast --rm --force "$logs_filename" &>/dev/null
fi
if [[ "$RC" == 0 ]] \
then
	echo "$1 PASSED"
	mv "$EXEC_LOG" ci."$1".PASSED
else
	echo "$1 FAILED"
	mv "$EXEC_LOG" ci."$1".FAILED
fi

#exit "$RC"
exit 0
