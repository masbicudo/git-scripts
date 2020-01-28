#!/bin/bash
test_name="test-repo-del-large"

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

    git checkout --orphan "b1'"
    git rm -rf .
    touch "a0.txt"
    mkdir "d1"
    # ref: https://superuser.com/questions/470949/how-do-i-create-a-1gb-random-file-in-linux
    openssl rand -out "d1/a 1.txt" -base64 $((1024*1000))
    git add -A
    git commit -a -m "added 'a0.txt', 'd1/a 1.txt' (1MB)"

  sleep 1

    mkdir "d2"
    touch "d2/a2.txt"
    git add -A
    git commit -a -m "added 'd2/a2.txt'"

  sleep 1
else
  pushd "$test_name" || exit
fi

# renaming subdirectory in history - zip parent timelines with rebase
if [ ! -z "$_EXEC" ]; then
  echo -e "\e[34m""deleting all files with more than 100KB""\e[0m"
    git branch b1s "b1'"
    "$git_hist_mv" --del "b1s" --min-size 100KB
fi
git checkout "b1s"

# cleanup
if [ -z "$_KEEP_BRANCHES" ]; then
  echo -e "\e[34m""cleanup""\e[0m"
  git branch -D "b1'"
fi

_RET_CODE=0
if [ ! -z "$_ASSERT" ]; then
  check -e  "a0.txt" || _RET_CODE=1
  check -ne "d1/a 1.txt" || _RET_CODE=1
  check -e  "d2/a2.txt" || _RET_CODE=1
fi

popd
[ -z "$_KEEP_FILES" ] && rm -rf "$test_name"
exit $_RET_CODE
