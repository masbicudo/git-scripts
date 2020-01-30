#!/bin/bash
#F_DIR="(^a)|(^b)"
F_FNAME=ie"*.TXT *.png"
#F_MIN_SIZE=1000KB

git () {
    if [ "$1" == "diff-tree" ]; then
      echo 0000000000000000000000000000000000000000
      echo  "a/some.txt"
      echo  '"a/b b/my file"'
      echo  '"a/b b/c c/other"'
      echo  "n.png"
      echo  "b/other"
      echo  '"with spaces"'
    elif [ "$1" == "cat-file" ] && [ "$2" == "-s" ]; then
      [ "$3" == "0000000000000000000000000000000000000000:a/some.txt" ] && echo 1024
      [ "$3" == '0000000000000000000000000000000000000000:a/b b/my file' ] && echo 10240
      [ "$3" == '0000000000000000000000000000000000000000:a/b b/c c/other' ] && echo 102400
      [ "$3" == "0000000000000000000000000000000000000000:n.png" ] && echo 0
      [ "$3" == "0000000000000000000000000000000000000000:b/other" ] && echo 1024000
      [ "$3" == '0000000000000000000000000000000000000000:with spaces' ] && echo 10240000
    fi
}

function convert_to_bytes {
  # Converts a number of data units into bytes:
  # - Supports K, M, G, T, E
  # - Case insensitive (K is the same as k, M as m, ...)
  # - May be followed by B or b, or nothing (the B character is ignored)
  # Examples:
  #   10kb ->       10240
  #    1M  ->     1024000
  #   10gB -> 10240000000
  __sz="$1"
  if ! [[ "$__sz" =~ ^[0-9]+([KMGTEkmgte])?([Bb])?$ ]]; then return 1; fi
  __un=$(echo $__sz | sed -r 's ^[0-9]+([KMGTE])?B?$ \1 gI')
  __sz=$(echo $__sz | sed -r 's ^([0-9]+)[KMGTE]?B?$ \1 gI')
  if   [ "${__un^^}" = "K" ]; then let "__sz=$__sz*1024";
  elif [ "${__un^^}" = "M" ]; then let "__sz=$__sz*1024000";
  elif [ "${__un^^}" = "G" ]; then let "__sz=$__sz*1024000000";
  elif [ "${__un^^}" = "T" ]; then let "__sz=$__sz*1024000000000";
  elif [ "${__un^^}" = "E" ]; then let "__sz=$__sz*1024000000000000";
  fi
  echo "$__sz"
  return 0
}

# see: kb/norm_fname.sh
function proc_f_fname {
  shopt -s extglob
  local _fname="$1"
  if [ ! -z "$_fname" ]; then
    local _not="0" _opt="" _single="0" _icase="0"
    if [ "${_fname:0:1}" = "i" ]; then
      _icase="1"
      _fname="${_fname:1}"
    fi
    if [ "${_fname:0:1}" = "!" ]; then
      _not="1"
      _fname="${_fname:1}"
    fi
    if [[ "ebcr" =~ "${_fname:0:1}" ]]; then
      _opt="${_fname:0:1}"
      _fname="${_fname:1}"
    fi
    if [ "$_not" == "0" ] && [ "${_fname:0:1}" = "!" ]; then
      _not="1"
      _fname="${_fname:1}"
    fi
    if [ "$_opt" != "r" ]; then
      if [ "${_fname:0:1}" = "=" ]; then
        _single="1"
        _fname="${_fname:1}"
      fi
    fi
    if [ "$_single" == "1" ] && [ -z "$_opt" ]; then
      _opt="x"
    fi
    if [[ "ebcx" =~ "$_opt" ]]; then
      _fname="${_fname//\\/\/}"
      _fname="${_fname//\$/\\\$}"
      _fname="${_fname//\./\\\.}"
      _fname="${_fname//\(/\\\(}"
      _fname="${_fname//\)/\\\)}"
      _fname="${_fname//\[/\\\[}"
      _fname="${_fname//\]/\\\]}"
      _fname="${_fname//\^/\\\^}"
      _fname="${_fname//\//[\\/]}"
      _fname="${_fname//\*\*/\\Q}"
      _fname="${_fname//\*/\([^\\/]\*\)}"
      _fname="${_fname//\\Q/\(\.\*\)}"
      _fname="${_fname/#*([[:blank:]])/\(}"
      _fname="${_fname/%*([[:blank:]])/\)}"
      if [ "$_single" == "0" ]; then
        _fname="${_fname//+([[:blank:]])/\)\|\(}"
      fi
      if [ "$_opt" = "b" ]; then
        _fname="^($_fname)"
      elif [ "$_opt" = "e" ]; then
        _fname="($_fname)$"
      elif [ "$_opt" = "x" ]; then
        _fname="^($_fname)$"
      fi
    elif [ "$_opt" != "r" ]; then
      return 1
    fi
  fi
  echo "$_not" "$_icase" "$_fname"
  return 0
}

# normalizing filters and their options
# TODO: support multiple filters of the same type, doing an 'AND' operation between them
if [ -v F_FNAME ]; then read -r F_FNAME_NOT F_FNAME_CI F_FNAME <<< "$(proc_f_fname "$F_FNAME")"; fi
if [ -v F_DIR ]; then read -r F_DIR_NOT F_DIR_CI F_DIR <<< "$(proc_f_fname "$F_DIR")"; fi
if [ -v F_PATH ]; then read -r F_PATH_NOT F_PATH_CI F_PATH <<< "$(proc_f_fname "$F_PATH")"; fi
if [ -v F_MIN_SIZE ]; then F_MIN_SIZE="$(convert_to_bytes "$F_MIN_SIZE")"; fi
if [ -v F_MAX_SIZE ]; then F_MAX_SIZE="$(convert_to_bytes "$F_MAX_SIZE")"; fi

function debug_file { echo "[92m$@[0m"; }

# ref: https://stackoverflow.com/a/10433783/195417
contains_element () { for e in "${@:2}"; do [[ "$e" = "$1" ]] && return 0; done; return 1; }

function is_file_selected {
  debug_file "      ## is_file_selected"
  debug_file "        F_DIR=$F_DIR F_FNAME=$F_FNAME F_MIN_SIZE=$F_MIN_SIZE F_MAX_SIZE=$F_MAX_SIZE"
  local _path="${1/#\"/}"
  _path="${_path/%\"/}"
  debug_file "        _path=$_path"

  # filtering by path
  if [ -v F_PATH ]; then
    local _fpath="$_path"
    local _ci=""
    if [ "$F_PATH_CI" == "1" ]; then _ci="I"; fi
    if [ "$_fpath" = "." ]; then _fpath=""; fi
    debug_file "        _fpath=$_fpath"
    echo "$_fpath" | sed -r "/$F_PATH/$_ci!{q100}" &>/dev/null
    [ $? -eq 100 ]
    if [ "$?" = "$F_PATH_NOT" ]; then return 1; fi
  fi
  
  # filtering by directory
  if [ -v F_DIR ]; then
    local directory=$(dirname "$_path")
    local _ci=""
    if [ "$F_DIR_CI" == "1" ]; then _ci="I"; fi
    if [ "$directory" = "." ]; then directory=""; fi
    debug_file "        directory=$directory"
    echo "$directory" | sed -r "/$F_DIR/$_ci!{q100}" &>/dev/null
    [ $? -eq 100 ]
    if [ "$?" = "$F_DIR_NOT" ]; then return 1; fi
  fi
  
  # filtering by name
  if [ -v F_FNAME ]; then
    local fname=$(basename "$_path")
    local _ci=""
    if [ "$F_FNAME_CI" == "1" ]; then _ci="I"; fi
    debug_file "        fname=$fname"
    echo "$fname" | sed -r "/$F_FNAME/$_ci!{q100}" &>/dev/null
    [ $? -eq 100 ]
    if [ "$?" = "$F_FNAME_NOT" ]; then return 1; fi
  fi
  
  # filtering by size
  if [ -v F_MIN_SIZE ] || [ -v F_MAX_SIZE ]; then
    local objsize=$(git cat-file -s "$GIT_COMMIT:$_path")
    debug_file "        objsize=$objsize"
    if [ -v F_MIN_SIZE ] && [ $objsize -lt $F_MIN_SIZE ]; then return 1; fi
    if [ -v F_MAX_SIZE ] && [ $objsize -gt $F_MAX_SIZE ]; then return 1; fi
  fi
  
  # displaying result
  return 0
}

function get_filtered_files_for_commit {
  debug_file "    ## get_filtered_files_for_commit"
  local commithash="$1"
  while read path; do
    if is_file_selected "$path"; then
      echo "$path"
    fi
  done <<< "$(git diff-tree -r --name-only --diff-filter=AMT $commithash | tail -n +2)"
}

echo "get_filtered_files_for_commit 0000000000000000000000000000000000000000"
get_filtered_files_for_commit 0000000000000000000000000000000000000000
