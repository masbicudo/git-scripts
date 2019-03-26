#!/bin/bash
# params
while [[ $# -gt 0 ]]
do
  case "$1" in
    -kf|--keep-files)    _KEEP_FILES=TRUE   ;;
    -kb|--keep-branches) _KEEP_BRANCHES=TRUE;;
    *)                                      ;;
  esac
  shift
done
