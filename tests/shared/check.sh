#!/bin/bash

function check {
  red=[91m;green=[92m;cdef=[0m;white=[97m;dkgray=[90m
  if [ "$1" == "-e" ]; then
    test -e "$2" && _ERROR=0 || _ERROR=1
    echo [$([ "$_ERROR" == "0" ] && echo $green" OK "$cdef || echo $red"FAIL"$cdef)] check file exists: "'$2'"
  elif [ "$1" == "-ne" ]; then
    test -e "$2" && _ERROR=1 || _ERROR=0
    echo [$([ "$_ERROR" == "0" ] && echo $green" OK "$cdef || echo $red"FAIL"$cdef)] check file does not exist: "'$2'"
  elif [ "$1" == "-eq" ]; then
    if [ ! -e "$2" ]; then _ERROR=2; _MSG="cannot compare, file not found: '$2'"
    elif [ ! -e "$3" ]; then _ERROR=3; _MSG="cannot compare, file not found: '$3'"
    elif diff "$2" "$3" >/dev/null 2>&1
    then _ERROR=0; _MSG="$dkgray""files are equal: '$2' and '$3'"
    else _ERROR=1; _MSG="files are different: '$2' and '$3'"
    fi
    echo [$([ "$_ERROR" == "0" ] && echo $green" OK "$cdef || echo $red"FAIL"$cdef)] "$_MSG"
  elif [ "$1" == "-neq" ]; then
    if [ ! -e "$2" ]; then _ERROR=2; _MSG="cannot compare, file not found: '$2'"
    elif [ ! -e "$3" ]; then _ERROR=3; _MSG="cannot compare, file not found: '$3'"
    elif diff "$2" "$3" >/dev/null 2>&1
    then _ERROR=1; _MSG="$dkgray""files are equal: '$2' and '$3'"
    else _ERROR=0; _MSG="files are different: '$2' and '$3'"
    fi
    echo [$([ "$_ERROR" == "0" ] && echo $green" OK "$cdef || echo $red"FAIL"$cdef)] "$_MSG"
  fi
  return $_ERROR
}
