#!/bin/bash
test_group_name="git-hist-mv"

red=[91m;green=[92m;cdef=[0m;white=[97m

echo $white"$test_group_name tests"$cdef

function run() {
  "./$1" >/dev/null 2>&1
  _ERROR=$?
  echo [$([ "$_ERROR" -eq "0" ] && echo $green" OK "$cdef || echo $red"FAIL"$cdef)] "$2"
}

if [ ! -z "$1" ]; then
  run "$@"
  exit 0
fi

run git-hist-mv.test-self-copy.sh "Copying a directory from/to the same branch history"
run git-hist-mv.test-self-move.sh "Moving a directory from/to the same branch history"
run git-hist-mv.test-self-ren.sh "Renaming a directory from/to the same branch history"
run git-hist-mv.test-del.sh "Deleting a directory from the branch history"
run git-hist-mv.test-del-file.sh "Deleting a file from the branch history"
run git-hist-mv.test-copy-zip.sh "Copying a directory from one branch history to another with rebase"
run git-hist-mv.test-copy-mrg.sh "Copying a directory from one branch history to another with merge"
run git-hist-mv.test-self-ren-spc.sh "Renaming a directory containing spaces"
