#!/bin/bash
test_name="test-repo-del"

echo -e "\e[91m""git-hist-mv $test_name""\e[0m"

. ../shared/params.sh || exit 1
. ../shared/upsearch.sh || exit 1
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
    touch a.txt
    git add -A
    git commit -a -m "added a.txt"

  sleep 1

    mkdir sd
    touch sd/a2.txt
    touch sd/a3.txt
    git add -A
    git commit -a -m "added sd/a2.txt and sd/a3.txt"

  sleep 1
else
  pushd "$test_name" || exit
fi

exit 0

# deleting a file from the branch history
if [ ! -z "$_EXEC" ]; then
  echo -e "\e[34m""deleting a file from the branch history""\e[0m"
    git branch b1s b1
    "$git_hist_mv" --del "b1s/sd/a2.txt"
    git checkout b1s
fi

# cleanup
if [ -z "$_KEEP_BRANCHES" ]; then
  echo -e "\e[34m""cleanup""\e[0m"
  git branch -D b1
fi

_RET_CODE=0
if [ ! -z "$_ASSERT" ]; then
  test -e "a.txt" || _RET_CODE=1
  test -e "sd/a2.txt" || _RET_CODE=1
  test -e "sd/a3.txt" && _RET_CODE=1
fi

popd
[ -z "$_KEEP_FILES" ] && rm -rf "$test_name"
exit $_RET_CODE
