#!/bin/bash
# ref: https://stackoverflow.com/questions/44077785/change-the-root-commit-parent-to-point-to-another-commit-connecting-two-indepen
git filter-branch --parent-filter 'test $GIT_COMMIT = $1 && echo "-p $2" || cat' HEAD
