#!/bin/sh
#
# Verify every definition in this repository.
#
#   ./check.sh                 verify all of them
#   ./check.sh nasdaq          verify the ones under a directory
#   ./check.sh path/to.3d      verify one
#
# Each definition is given to everparse, which proves the validators it writes: that they read
# no byte outside the buffer, read no byte twice, and accept exactly what the definition
# describes. The C it writes is then compiled (CC, or cc).
#
# EVERPARSE names the everparse.sh of an unpacked release; without it, everparse.sh is looked
# for on the path.
#
# Definitions are tried side by side, as many at once as JOBS says or the machine has
# processors, each in a directory of its own. A large definition can take several gigabytes
# while it is verified, so on a small machine set JOBS lower.
#
# SHARD=i/n verifies one definition in every n, starting from the i-th, so n machines can
# share the work.
#
# LIMIT is the seconds a definition may take, 1800 unless set: one that has not finished by
# then is stopped and reported as failing. Each definition is reported as it finishes, with
# the seconds it took, and a check that is itself stopped names the definitions it was still
# verifying, so a run that ends early still says which definition it ended on.

set -u

target=${1:-.}

if [ -f "$target" ]; then
  definitions=$target
else
  definitions=$(find "$target" -name '*.3d' | sort)
fi

if [ -n "${SHARD:-}" ]; then
  definitions=$(echo "$definitions" | awk -v shard="${SHARD%/*}" -v shards="${SHARD#*/}" 'NR % shards == shard % shards')
fi

if [ -z "$definitions" ]; then
  echo "no definitions under $target"
  exit 1
fi

everparse=${EVERPARSE:-$(command -v everparse.sh)}

if [ -z "$everparse" ]; then
  echo "everparse.sh not found: set EVERPARSE to the everparse.sh of an unpacked release"
  exit 1
fi

failures=$(mktemp -d)
running=$(mktemp -d)
jobs=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}
limit=${LIMIT:-1800}
count=$(echo "$definitions" | wc -l)

export everparse failures running limit

# a check stopped before it finishes (a hosted job out of time, a cancelled run) names the definitions
# it was still verifying and how long each had run, since those are the ones that never answered
stopped() {
  echo "stopped while verifying:"
  now=$(date +%s)
  for marker in "$running"/*; do
    [ -e "$marker" ] || continue
    read -r start definition < "$marker"
    echo "  $definition, $((now - start))s in"
    echo "::error file=$definition::stopped after $((now - start))s while everparse was verifying it"
  done
  exit 143
}

trap stopped TERM INT

echo "verifying $count definitions, $jobs at a time, each for at most ${limit}s"

# one definition: tried in a directory of its own, its result written the moment it is known, and its
# log kept only when it fails. A definition everparse is still verifying after LIMIT seconds is stopped
# and reported as a failure of its own, so one that will not finish cannot hold up the rest
echo "$definitions" | xargs -P "$jobs" -n 1 sh -c '
  definition=$1
  module=$(basename "$definition" .3d)
  work=$(mktemp -d)
  marker="$running/$(echo "$definition" | tr "/" "_")"
  start=$(date +%s)
  passed=0

  echo "$start $definition" > "$marker"
  echo "start $definition"
  mkdir "$work/out"
  cp "$definition" "$work/"

  bounded=""

  if command -v timeout > /dev/null 2>&1; then
    bounded="timeout --kill-after=60 $limit"
  fi

  (cd "$work" && $bounded "$everparse" --odir out "$module.3d") > "$work/log" 2>&1
  status=$?

  if [ "$status" -eq 0 ] \
    && ${CC:-cc} -c -I "$work/out" -o "$work/validators.o" "$work/out/$module.c" >> "$work/log" 2>&1 \
    && ${CC:-cc} -c -I "$work/out" -o "$work/wrapper.o" "$work/out/${module}Wrapper.c" >> "$work/log" 2>&1; then
    passed=1
  fi

  seconds=$(($(date +%s) - start))
  rm -f "$marker"

  if [ "$passed" -eq 1 ]; then
    echo "ok    ${seconds}s $definition"
  else
    case "$status" in
      124|137) why="took longer than ${limit}s" ;;
      0) why="wrote C that does not compile" ;;
      *) why="failed" ;;
    esac

    echo "FAIL  ${seconds}s $definition: $why"
    echo "::error file=$definition::everparse $why (${seconds}s)"

    report="$failures/$(echo "$definition" | tr "/" "_")"
    echo "FAIL $definition: $why (${seconds}s)" > "$report"
    tail -n 40 "$work/log" | sed "s/^/      /" >> "$report"
  fi

  rm -rf "$work"
' check

# the failures again, together and in the order of their names, whatever order they finished in:
# each was written under its own path, so listing them is sorting them
failed=$(find "$failures" -type f | wc -l)

if [ "$failed" -gt 0 ]; then
  cat "$failures"/*
fi

rm -rf "$failures" "$running"

echo "everparse: tried $count definitions, $failed failed"
[ "$failed" -eq 0 ]
