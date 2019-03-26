#!/bin/bash
echo -e "\e[91m""git-hist-mv test-repo-copy-mrg""\e[0m"

# initializing
echo -e "\e[34m""initializing""\e[0m"
rm -rf test-repo-copy-mrg
mkdir test-repo-copy-mrg
pushd test-repo-copy-mrg
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

# copying tree with merges - many parent timelines
echo -e "\e[34m""copying tree with merges - many parent timelines""\e[0m"
  git branch b3m b3
  ../../git-hist-mv.sh --copy "b1"    "b3m/d1"
  ../../git-hist-mv.sh --copy "b2/sd" "b3m/d2"

# cleanup
echo -e "\e[34m""cleanup""\e[0m"
git branch -D b1
git branch -D b2
git branch -D b3

popd