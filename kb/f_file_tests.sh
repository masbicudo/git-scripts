#!/bin/bash
# F_DIR="(^a)|(^b)"
# F_FNAME="file"
F_MIN_SIZE=1000KB

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

# normalizing filters
if [ -v F_FNAME ]; then
  if [ "${F_FNAME:0:1}" = "r" ]; then
    F_FNAME="${F_FNAME:1}"
  elif [ "${F_FNAME:0:1}" = "#" ] || [ "${F_FNAME:0:1}" = "%" ]; then
    F_FNAME="${F_FNAME:1}"
    F_FNAME="${F_FNAME/# */(}"
    F_FNAME="${F_FNAME/% */)}"
    F_FNAME="${F_FNAME// */)|(}"
    F_FNAME="${F_FNAME//\./\\.}"
  fi
  # elif [ "${F_FNAME:0:1}" = "/" ]; then
  #   F_FNAME=$(sed -r "s ^/(.*)/$ \1 " <<< "$F_FNAME")
  # else
  #   F_FNAME=$(sed -r "s \*\..*$ \0$ ;s \. \\\\. ;s \* .* ;s \? . " <<< "$F_FNAME")
  # fi
fi

if [ -v F_DIR ]; then F_DIR=$(sed -r 's\\/|/(^|$|\\/)g' <<< "$_DIR"); fi

if [ -v F_MIN_SIZE ]; then F_MIN_SIZE="$(convert_to_bytes "$F_MIN_SIZE")"; fi
if [ -v F_MAX_SIZE ]; then F_MAX_SIZE="$(convert_to_bytes "$F_MAX_SIZE")"; fi

function debug_file { echo "[92m$@[0m"; }

# ref: https://stackoverflow.com/a/10433783/195417
contains_element () { for e in "${@:2}"; do [[ "$e" = "$1" ]] && return 0; done; return 1; }

function get_filtered_files_for_commit {
  debug_file "    ## get_filtered_files_for_commit"
  local commithash="$1"
  while read path; do
    local _path="$(sed -e "s ^\"  ;s \"$  " <<< "$path")"
    debug_file "      $path"

    # filtering by directory
    local directory=$(dirname "$_path")
    if [ "$directory" = "." ]; then directory=""; fi
    if [ -v F_DIR ]; then
      echo "$directory" | sed -r "/$F_DIR/I!{q100}" &>/dev/null
      retVal=$?
      if [ $retVal -eq 100 ]; then
        continue
      fi
    fi
    
    # filtering by name
    local fname=$(basename "$_path")
    if [ -v F_FNAME ]; then
      echo "$fname" | sed -r "/$F_FNAME/I!{q100}" &>/dev/null
      local retVal=$?
      #echo retVal=$retVal
      if [ $retVal -eq 100 ]; then
        continue
      fi
    fi
    
    # filtering by size
    local objsize=$(git cat-file -s "$commithash:$_path")
    [ -v F_MIN_SIZE ] && [ $objsize -lt $F_MIN_SIZE ] && continue
    [ -v F_MAX_SIZE ] && [ $objsize -gt $F_MAX_SIZE ] && continue
    
    # displaying result
    echo "$path"
  done <<< "$(git diff-tree -r --name-only --diff-filter=AMT $commithash | tail -n +2)"
}

git () {
    if [ "$1" == "diff-tree" ]; then
      echo  "a/some.txt"
      echo  '"a/b b/my file"'
      echo  '"a/b b/c c/other"'
      echo  "n.txt"
      echo  "b/other"
      echo  '"with spaces"'
    elif [ "$1" == "cat-file" ] && [ "$2" == "-s" ]; then
      [ "$3" == "0000000000000000000000000000000000000000:a/some.txt" ] && echo 1024
      [ "$3" == '0000000000000000000000000000000000000000:a/b b/my file' ] && echo 10240
      [ "$3" == '0000000000000000000000000000000000000000:a/b b/c c/other' ] && echo 102400
      [ "$3" == "0000000000000000000000000000000000000000:n.txt" ] && echo 0
      [ "$3" == "0000000000000000000000000000000000000000:b/other" ] && echo 1024000
      [ "$3" == '0000000000000000000000000000000000000000:with spaces' ] && echo 10240000
    fi
}

echo "get_filtered_files_for_commit 0000000000000000000000000000000000000000"
get_filtered_files_for_commit 0000000000000000000000000000000000000000
