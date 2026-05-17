#!/bin/bash
set -euo pipefail
set -x

if ! [[ -d /sys/module/overlay ]]; then
  echo "You should 'modprobe overlay' so that tests works"
  exit 1
fi

[[ -d test/common/container ]]

OUTSIDE_CVMFS_WORKCOPY=$(readlink -f ..)
if ! [[ -v FLAVOUR ]]; then
  FLAVOUR=$(basename "$(readlink -f "$OUTSIDE_CVMFS_WORKCOPY"/../../)")
fi
#CONTAINER_IMAGE_NAME=cvmfs-dev__"$FLAVOUR"
[[ -v CONTAINER_IMAGE_NAME ]]
BUILDER_CONTAINER_NAME=cvmfs-dev__"$FLAVOUR"
WORKER_CONTAINER_NAME_BASE=cvmfs-ci-worker__"$FLAVOUR"-

time podman rm -f $(podman ps -a --format="{{.Names}}" | grep "$WORKER_CONTAINER_NAME_BASE" || true) || true
rm -rf "$OUTSIDE_CVMFS_WORKCOPY"/worker

if ! [[ -v NPROC ]]; then
  NPROC=$(nproc)
fi

#PRIORITIZE=(nice -n19  ionice -c3)
PRIORITIZE=()

for worker_i in $(seq 1 "$NPROC"); do
  mkdir -p "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/orders
  mkdir -p "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/orders/.wip
  mkdir -p "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/log
  mkdir -p "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/tmp
  chmod -R 777 "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i
done

for worker_i in $(seq 1 "$NPROC"); do
  # /var/spool/cvmfs should be a bucket (or perhaps a tmpfs),
  # because with a bind-mount dir from host,
  # some overlay features may be unsupported and tests will fail.
  #podman volume rm var_spool_cvmfs-for-server-tests --force
  #  -v var_spool_cvmfs-for-server-tests:/var/spool/cvmfs \
  #  --tmpfs /var/spool/cvmfs \

  # "--security-opt seccomp=unconfined" is for ptrace, so that cvmfs can log its stacktraces
  "${PRIORITIZE[@]}" podman create --ulimit nice=20 \
    --replace \
    --name "$WORKER_CONTAINER_NAME_BASE"$worker_i \
    --privileged \
    --security-opt seccomp=unconfined \
    -v /sys/fs/cgroup:/sys/fs/cgroup \
    -v "$OUTSIDE_CVMFS_WORKCOPY"/cvmfs:/home/sftnight/cvmfs \
    -v "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/log:/var/log/ci \
    -v "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/tmp:/tmp \
    -v "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/orders:/orders \
    -v "$OUTSIDE_CVMFS_WORKCOPY"/../../../work.sh:/work.sh \
    --tmpfs /var/spool/cvmfs \
    "$CONTAINER_IMAGE_NAME" \
    /sbin/init \
    && "${PRIORITIZE[@]}" podman start "$WORKER_CONTAINER_NAME_BASE"$worker_i \
    && "${PRIORITIZE[@]}" podman exec -u sftnight "$WORKER_CONTAINER_NAME_BASE"$worker_i bash -c \
    "touch /var/log/ci/00-started; while ! (systemctl status && systemctl is-active multi-user.target)&>/dev/null; do sleep 1; done; (sudo cvmfs_config setup && touch /var/log/ci/work.log && touch /var/log/ci/01-booted && nohup taskset --cpu-list $(( RANDOM % "$(nproc)" )) /work.sh &> /var/log/ci/work.log &) || touch /var/log/ci/99-failed" \
    &

done

# CWD shouldn't be important
cd "$OUTSIDE_CVMFS_WORKCOPY"/cvmfs/test/common/container

# inclusions:
# grep -l 'cvmfs_test_suites=.*quick' src/[01567]*/main | sed s:/main::
# exclusions:
# grep 'src/[0-9]\+-' common/container/test.sh | sed -e 's: -x ::' -e 's: ::g' -e 's:[\]::'
TESTS=$(
set -euo pipefail
pushd ../.. &>/dev/null
[[ "$(basename "$PWD")" == test ]]
# # retro:
# comm -23 \
#   <(grep -l 'cvmfs_test_suites=.*quick' src/[01567]*/main | sed s:/main::) \
#   <(grep 'src/[0-9]\+-' common/container/test.sh | sed -e 's: -x ::' -e 's: ::g' -e 's:[\]::')

# ci_ubuntu.yaml:
comm -23 \
  <(grep -l 'cvmfs_test_suites=.*quick' src/[015678]*/main | sed s:/main:: | sort) \
  <(grep 'src/[0-9]\+-' ../.github/workflows/ci_ubuntu.yaml | sed -e 's: -x ::' -e 's: ::g' -e 's:[\]::' | sort) \
| grep -v '059-fallbackproxy\|615-externaldata\|691-metalink\|THEY_USE_example.com_AS_PROXY'

# # FOR TESTING, SOME SERVER TESTS ONLY!
# comm -23 \
#   <(grep -l 'cvmfs_test_suites=.*quick' src/[5]*/main | sed s:/main:: | sort) \
#   <(grep 'src/[0-9]\+-' common/container/test.sh | sed -e 's: -x ::' -e 's: ::g' -e 's:[\]::' | sort)
)

wait_until_found_idle_worker() {
  while true; do
    for worker_i in $(seq 1 "$NPROC"); do
      if ! [[ -f "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/log/01-booted ]]; then
        continue
      else
        touch "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/seen-booted
        if ! [[ -f "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/log/work.log ]]; then
          touch "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/faulty
          podman stop --ignore --time 0 "$WORKER_CONTAINER_NAME_BASE"$worker_i
        fi
      fi
      if [[ -f "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/faulty ]]; then
        continue
      fi
      orders_dir="$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/orders
      if [[ "$(ls "$orders_dir")" == "" ]]; then
        echo "$orders_dir"
        return
      fi
    done
    sleep 0.5
  done
}

wait_workers_drained() {
  while true; do
    if [[ "$(find "$OUTSIDE_CVMFS_WORKCOPY"/worker/*/orders -type f)" == '' ]]; then
      break
    fi
    sleep 0.5
  done
}

for test in $TESTS; do
  idle_worker_orders_dir=$(wait_until_found_idle_worker)
  jobname=${test#src/}
  job_file="$idle_worker_orders_dir"/.wip/"$jobname".job
  cat > "$job_file" <<-EOF
#!/bin/bash
set -euo pipefail
set -x
cd /home/sftnight/cvmfs/test
export CVMFS_TEST_PROXY=DIRECT
./run.sh /var/log/ci/$jobname.test.log -- $test
EOF

  chmod a+rwx "$job_file"
  # reveal:
  mv "$job_file" $idle_worker_orders_dir/
done

wait_workers_drained
touch "$OUTSIDE_CVMFS_WORKCOPY"/worker/all-tests.done
grep 'Testcase failed' "$OUTSIDE_CVMFS_WORKCOPY"/worker/*/log/*.test.log
echo 'Tests passed: '
grep 'Test passed' "$OUTSIDE_CVMFS_WORKCOPY"/worker/*/log/*.test.log | wc -l
# Stats of outcomes (by 3rd line from the end):
for x in "$OUTSIDE_CVMFS_WORKCOPY"/worker/*/log/*.test.log; do tail -n3 $x | head -n1; done | sort | uniq -c
# Stats of outcomes by run.sh exit code:
echo PASSED "$(find "$OUTSIDE_CVMFS_WORKCOPY"/worker/*/log/pass -type f | wc -l)"
echo FAILED "$(find "$OUTSIDE_CVMFS_WORKCOPY"/worker/*/log/fail -type f | wc -l)"

for worker_i in $(seq 1 "$NPROC"); do
  touch "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/orders/non-executable-for-quit
done
for worker_i in $(seq 1 "$NPROC"); do
  while [[ -f "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/orders/non-executable-for-quit ]]; do
    if [[ -f "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/faulty ]]; then
      continue
    fi
    # common failure mode: container listed in podman ps but not running and not inspectable
    if [[ "$(podman inspect "$WORKER_CONTAINER_NAME_BASE"$worker_i | jq --raw-output .[0].State.Running)" != true ]]; then
      break
    fi
    # common failure mode: container listed in podman is running, but no worker process and our log and tmp dir contents are gone, including work.log
    if ! [[ -f "$OUTSIDE_CVMFS_WORKCOPY"/worker/$worker_i/log/work.log ]]; then
      echo "worker $worker_i work.log disappeared, aborting it"
      break
    fi
    sleep 1
  done
  podman stop --ignore --time 0 "$WORKER_CONTAINER_NAME_BASE"$worker_i || true
done

wait

cd "$OUTSIDE_CVMFS_WORKCOPY"
tar -cf - worker/*/log/ worker/*/tmp/cvmfs-test/ | zstd -T0 --ultra -20 > worker.$(date +%F_%T).tar.zst
