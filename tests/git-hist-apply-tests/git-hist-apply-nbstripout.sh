#!/bin/bash
test_name="test-repo-apply-nbstripout"

echo -e "\e[91m""git-hist-apply $test_name""\e[0m"

. ../shared/params.sh
. ../shared/upsearch.sh
git_hist_apply=$(upsearch "src/git-hist-apply.sh")

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
    cp ../a.ipynb "a.ipynb"
    git add -A
    git commit -a -m "added a.ipynb"

  sleep 1

    cp ../b.ipynb "b.ipynb"
    git add -A
    git commit -a -m "added b.ipynb"

  sleep 1
else
  pushd "$test_name" || exit
fi

# executing nbstripout
if [ ! -z "$_EXEC" ]; then
  echo -e "\e[34m""applying nbstripout""\e[0m"
    git branch b2 b1
    git checkout b2
    "$git_hist_apply" '.ipynb$' nbstripout
fi

# cleanup
if [ -z "$_KEEP_BRANCHES" ]; then
  echo -e "\e[34m""cleanup""\e[0m"
  git branch -D b1
fi

_RET_CODE=0
if [ ! -z "$_ASSERT" ]; then
  test -e "a.ipynb" || (_RET_CODE=1;echo a not found!)
  test -e "b.ipynb" || (_RET_CODE=1;echo a not found!)
  [ "$_RET_CODE" -eq "0" ] && (diff "a.ipynb" "../a.ipynb" >/dev/null 2>&1) && (_RET_CODE=1;echo a unchanged!)
  [ "$_RET_CODE" -eq "0" ] && (diff "b.ipynb" "../b.ipynb" >/dev/null 2>&1) && (_RET_CODE=1;echo a unchanged!)
fi

popd
[ -z "$_KEEP_FILES" ] && rm -rf "$test_name"
exit $_RET_CODE
