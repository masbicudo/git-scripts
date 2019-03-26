#!/bin/bash
test_group_name="git-hist-file-apply"

red=[91m;green=[92m;cdef=[0m;white=[97m

echo $white"$test_group_name tests"$cdef

function run() {
  "./$1" >/dev/null 2>&1
  _ERROR=$?
  echo [$([ "$_ERROR" -eq "0" ] && echo $green" OK "$cdef || echo $red"FAIL"$cdef)] "$2"
}

run git-hist-apply-nbstripout.sh 'Applying nbstripout to *.ipynb files'
