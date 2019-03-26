#!/bin/bash
# params
while [[ $# -gt 0 ]]
do
  case "$1" in
    -p|--prepare)        _PREP=TRUE         ;;
    -e|--execute)        _EXEC=TRUE         ;;
    -a|--assert)         _ASSERT=TRUE       ;;
    -kf|--keep-files)    _KEEP_FILES=TRUE   ;;
    -kb|--keep-branches) _KEEP_BRANCHES=TRUE;;
    *)                                      ;;
  esac
  shift
done

if [ -z "$_PREP" ] && [ -z "$_EXEC" ] && [ -z "$_ASSERT" ]; then
  _PREP=TRUE
  _EXEC=TRUE
  _ASSERT=TRUE
fi
