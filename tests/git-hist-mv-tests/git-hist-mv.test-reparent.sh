#!/bin/bash
test_name="test-repo-reparent"

echo -e "\e[91m""git-hist-mv $test_name""\e[0m"

. ../shared/params.sh
. ../shared/upsearch.sh
. ../shared/check.sh
git_hist_mv=$(upsearch "src/git-hist-mv.sh")

add_files () {
  local next_arg
  git rm -rf .
  for arg in "$@"
  do
    echo "$arg"
    [ -v next_arg ] && echo "this is $next_arg" > "$next_arg"
    next_arg="$arg"
  done
  git add -A
  git commit -a -m "$next_arg"
}

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
    add_files a     "Initial commit"
    add_files a b   "Fix"
    add_files a b k "Feature A"

  sleep 1

    git checkout --orphan "b2"
    add_files a c   "Initial commit"
    add_files k     "Garbage commit"
    add_files a b c "Fix"
    add_files a c d "Feature B"

  sleep 1
else
  pushd "$test_name" || exit
fi

# By removing the c file from b2, the commit "Fix" of b2 becomes equal to the
# commit "Fix" of b1. We would like to reparent the commit "Feature B" after
# removing the file c.
if [ ! -z "$_EXEC" ]; then
  echo -e "\e[34m""reparenting commit after removing file""\e[0m"
    git branch b2s "b2"
    "$git_hist_mv" "b2s/c" --del --reparent tm
fi
git checkout b2s

# cleanup
if [ -z "$_KEEP_BRANCHES" ]; then
  echo -e "\e[34m""cleanup""\e[0m"
  git branch -D "b2"
fi

_RET_CODE=0
if [ ! -z "$_ASSERT" ]; then
fi

popd
[ -z "$_KEEP_FILES" ] && rm -rf "$test_name"
exit $_RET_CODE
