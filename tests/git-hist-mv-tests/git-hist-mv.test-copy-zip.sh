#!/bin/bash
echo -e "\e[91m""git-hist-mv test-repo-copy-zip""\e[0m"

# initializing
echo -e "\e[34m""initializing""\e[0m"
rm -rf test-repo-copy-zip
mkdir test-repo-copy-zip
pushd test-repo-copy-zip
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

# copying tree with rebase - zip parent timelines
echo -e "\e[34m""copying tree with rebase - zip parent timelines""\e[0m"
  git branch b3r b3
  ../../git-hist-mv.sh --copy "b1"    "b3r/d1" --zip
  ../../git-hist-mv.sh --copy "b2/sd" "b3r/d2" --zip

# cleanup
echo -e "\e[34m""cleanup""\e[0m"
git branch -D b1
git branch -D b2
git branch -D b3

popd