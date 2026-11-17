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
jobs=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}
count=$(echo "$definitions" | wc -l)

export everparse failures

# one definition: tried in a directory of its own, and its log kept only when it fails
echo "$definitions" | xargs -P "$jobs" -n 1 sh -c '
  definition=$1
  module=$(basename "$definition" .3d)
  work=$(mktemp -d)
  passed=0

  mkdir "$work/out"
  cp "$definition" "$work/"

  if (cd "$work" && "$everparse" --odir out "$module.3d") > "$work/log" 2>&1 \
    && ${CC:-cc} -c -I "$work/out" -o "$work/validators.o" "$work/out/$module.c" >> "$work/log" 2>&1 \
    && ${CC:-cc} -c -I "$work/out" -o "$work/wrapper.o" "$work/out/${module}Wrapper.c" >> "$work/log" 2>&1; then
    passed=1
  fi

  if [ "$passed" -ne 1 ]; then
    report="$failures/$(echo "$definition" | tr "/" "_")"
    echo "FAIL $definition" > "$report"
    tail -n 40 "$work/log" | sed "s/^/      /" >> "$report"
  fi

  rm -rf "$work"
' check

# the failures together and in the order of their names, whatever order they finished in:
# each was written under its own path, so listing them is sorting them
failed=$(find "$failures" -type f | wc -l)

if [ "$failed" -gt 0 ]; then
  cat "$failures"/*
fi

rm -rf "$failures"

echo "everparse: tried $count definitions, $failed failed"
[ "$failed" -eq 0 ]
