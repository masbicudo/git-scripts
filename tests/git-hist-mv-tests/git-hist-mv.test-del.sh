#!/bin/bash
echo -e "\e[91m""git-hist-mv test-repo-del""\e[0m"

# initializing
echo -e "\e[34m""initializing""\e[0m"
rm -rf test-repo-del
mkdir test-repo-del
pushd test-repo-del
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
  git add -A
  git commit -a -m "added sd/a2.txt"


sleep 1

# deleting a folder from the branch history
echo -e "\e[34m""deleting a folder from the branch history""\e[0m"
  git branch b1s b1
  ../../git-hist-mv.sh --del "b1s/sd"
  git checkout b1s

# cleanup
echo -e "\e[34m""cleanup""\e[0m"
git branch -D b1

popd