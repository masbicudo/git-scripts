#!/bin/bash
function upsearch () {
  test / == "$PWD" && echo "" && return
  test -e "$1" && echo "$PWD/$1" && return
  pushd >/dev/null .. && upsearch "$1" && popd >/dev/null
}
