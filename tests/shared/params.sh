#!/bin/bash
# params
while [[ $# -gt 0 ]]
do
  case "$1" in
    -p|--prepare)        _PREPARE=TRUE      ;;
    -e|--execute)        _EXEC=TRUE         ;;
    -a|--assert)         _ASSERT=TRUE       ;;
    -kf|--keep-files)    _KEEP_FILES=TRUE   ;;
    -kb|--keep-branches) _KEEP_BRANCHES=TRUE;;
    -kbf|-kfb|-k)        _KEEP_BRANCHES=TRUE; _KEEP_FILES=TRUE;;
    *)                                      ;;
  esac
  shift
done

if [ -z "$_PREPARE" ] && [ -z "$_EXEC" ] && [ -z "$_ASSERT" ]; then
  _PREPARE=TRUE
  _EXEC=TRUE
  _ASSERT=TRUE
fi
