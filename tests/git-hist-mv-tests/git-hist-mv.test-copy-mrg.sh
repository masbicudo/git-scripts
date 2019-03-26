#!/bin/bash
test_name="test-repo-copy-mrg"

echo -e "\e[91m""git-hist-mv $test_name""\e[0m"

. ../shared/params.sh
. ../shared/upsearch.sh
git_hist_mv=$(upsearch "src/git-hist-mv.sh")

if [ ! -z "$_PREPARE" ]; then
  # initializing
  echo -e "\e[34m""initializing""\e[0m"
  rm -rf "$test_name"
  mkdir "$test_name"
  pushd "$test_name"
  git init

  # creating first branch
  echo -e "\e[34m""creating first branch""\e[0m"

    git checkout --orphan "b1"
    git rm -rf .
    touch a.txt
    git add -A
    git commit -a -m "added a.txt"

  sleep 1

    touch a2.txt
    git add -A
    git commit -a -m "added a2.txt"

  sleep 1

  # creating second branch
  echo -e "\e[34m""creating second branch""\e[0m"
    git checkout --orphan "b2"
    git rm -rf .
    touch b1.txt
    mkdir sd
    touch sd/b2.txt
    git add -A
    git commit -a -m "added b1.txt, sd/b2.txt"

  sleep 1

  # creating 3rd branch
  echo -e "\e[34m""creating 3rd branch""\e[0m"
    git checkout --orphan "b3"
    git rm -rf .
    touch c.txt
    git add -A
    git commit -a -m "added c.txt"

  sleep 1
else
  pushd "$test_name" || exit
fi

# copying tree with merges - many parent timelines
if [ ! -z "$_EXEC" ]; then
  echo -e "\e[34m""copying tree with merges - many parent timelines""\e[0m"
    git branch b3m b3
    "$git_hist_mv" --copy "b1"    "b3m/d1"
    "$git_hist_mv" --copy "b2/sd" "b3m/d2"
fi

# cleanup
if [ -z "$_KEEP_BRANCHES" ]; then
  echo -e "\e[34m""cleanup""\e[0m"
  git branch -D b1
  git branch -D b2
  git branch -D b3
fi

if [ ! -z "$_ASSERT" ]; then
  _RET_CODE=0
  test -e "c.txt" || _RET_CODE=1
  test -e "d1/a.txt" || _RET_CODE=1
  test -e "d1/a2.txt" || _RET_CODE=1
  test -e "d2/b2.txt" || _RET_CODE=1
fi

popd
[ -z "$_KEEP_FILES" ] && rm -rf "$test_name"
exit $_RET_CODE
