#!/bin/bash
test_name="test-repo-copy-to-root"

echo -e "\e[91m""git-hist-mv $test_name""\e[0m"

. ../shared/params.sh
. ../shared/upsearch.sh
. ../shared/check.sh
git_hist_mv=$(upsearch "src/git-hist-mv.sh")

if [ ! -z "$_PREPARE" ]; then
  # initializing
  echo -e "\e[34m""initializing""\e[0m"
  rm -rf "$test_name"
  mkdir "$test_name"
  pushd "$test_name"
  git init

  # creating branch
  echo -e "\e[34m""creating branch""\e[0m"

    git checkout --orphan "b1"
    git rm -rf .
    mkdir d1
    touch d1/a.txt
    git add -A
    git commit -a -m "added d1/a.txt"

  sleep 1

    mkdir sd
    touch sd/a2.txt
    git add -A
    git commit -a -m "added sd/a2.txt"

  sleep 1
else
  pushd "$test_name" || exit
fi

# copying subdirectory in history - zip parent timelines with rebase
if [ ! -z "$_EXEC" ]; then
  echo -e "\e[34m""copying subdirectory in history to root of another branch""\e[0m"
    git branch b1s b1
    "$git_hist_mv" "b1s" "d1" "b2" "" --copy
fi

# cleanup
if [ -z "$_KEEP_BRANCHES" ]; then
  echo -e "\e[34m""cleanup""\e[0m"
  git branch -D b1
fi

_RET_CODE=0
if [ ! -z "$_ASSERT" ]; then
  check -e "a.txt" || _RET_CODE=1
  check -ne "d1/a.txt" || _RET_CODE=1
  check -ne "sd/a2.txt" || _RET_CODE=1
fi

popd
[ -z "$_KEEP_FILES" ] && rm -rf "$test_name"
exit $_RET_CODE
