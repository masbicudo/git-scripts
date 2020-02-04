#!/bin/bash
dkgray=[90m;red=[91m;green=[92m;yellow=[93m;blue=[94m;magenta=[95m
cyan=[96m;white=[97m;black=[30m;dkred=[31m;dkgreen=[32m;dkyellow=[33m
dkblue=[34m;dkmagenta=[35m;dkcyan=[36m;gray=[37m;cdef=[0m

echo $yellow"Running all tests"$cdef
function runat() {
  pushd "$1" >/dev/null 2>&1 || exit
  ./run.sh
  popd >/dev/null 2>&1 || exit
}
runat "git-hist-apply-tests"
runat "git-hist-mv-tests"
runat "git-hist-nbstripout-tests"
