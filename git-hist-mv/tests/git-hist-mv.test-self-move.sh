#!/bin/bash
echo -e "\e[91m""git-hist-mv test-repo-self-move""\e[0m"

# initializing
echo -e "\e[34m""initializing""\e[0m"
rm -rf test-repo-self-move
mkdir test-repo-self-move
pushd test-repo-self-move
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

# moving self-tree with rebase - zip parent timelines
echo -e "\e[34m""moving self-tree with rebase - zip parent timelines""\e[0m"
  git branch b1s b1
  ../../git-hist-mv.sh "b1s" "b1s/sd2" --zip

# cleanup
echo -e "\e[34m""cleanup""\e[0m"
git branch -D b1

popd