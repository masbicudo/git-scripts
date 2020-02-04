#!/bin/bash
test_name="test-repo-apply-nbstripout"

echo -e "\e[91m""git-hist-apply $test_name""\e[0m"

. ../shared/params.sh
. ../shared/upsearch.sh
. ../shared/check.sh
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
    cp ../x.ipynb "a.ipynb"
    git add -A
    git commit -a -m "added a.ipynb"

  sleep 1

    cp ../x.ipynb "b.ipynb"
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
  check -e "a.ipynb" || _RET_CODE=1
  check -e "b.ipynb" || _RET_CODE=1
  check -neq "a.ipynb" "../x.ipynb" || _RET_CODE=1
  check -neq "b.ipynb" "../x.ipynb" || _RET_CODE=1
fi

popd
[ -z "$_KEEP_FILES" ] && rm -rf "$test_name"
exit $_RET_CODE
