#!/bin/bash

function check {
  red=[91m;green=[92m;cdef=[0m;white=[97m
  if [ "$1" == "-e" ]; then
    test -e "$2" && _ERROR=0 || _ERROR=1
    echo [$([ "$_ERROR" == "0" ] && echo $green" OK "$cdef || echo $red"FAIL"$cdef)] check file exists: "'$2'"
  elif [ "$1" == "-ne" ]; then
    test -e "$2" && _ERROR=1 || _ERROR=0
    echo [$([ "$_ERROR" == "0" ] && echo $green" OK "$cdef || echo $red"FAIL"$cdef)] check file does not exist: "'$2'"
  fi
  return $_ERROR
}
