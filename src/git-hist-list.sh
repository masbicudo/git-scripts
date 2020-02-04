#!/bin/bash
ver=v0.1.0

# argument variables
SHOW_EXT=NO
SHOW_FNAME=NO
SHOW_DIR=NO
NOINFO=NO

#BEGIN_DEBUG
function debug { echo "[92m$@[0m"; }
declare -fx debug
function debug_file { touch "/tmp/__debug.git-hist-mv.txt"; echo "$@" >> "/tmp/__debug.git-hist-mv.txt"; }
declare -fx debug_file
#END_DEBUG

function quote_arg {
  if [[ $# -eq 0 ]]; then return 1; fi
  # if argument 1 contains:
  # - spaces or tabs
  # - new lines
  # - is empty
  # then: needs to be quoted
  if [[ ! "$1" =~ [[:blank:]] ]] && [ "${1//
/}" = "$1" ] && [ ! -z "$1" ]
  then echo "${1//\'/\"\'\"}"; 
  else echo "'${1//\'/\'\"\'\"\'}'"
  fi
  return 0
}

# reading arguments
all_args=
if [ "$*" = "" ]; then
  # if there are no arguments, then show help
  HELP=YES
fi
argc=0
while [[ $# -gt 0 ]]
do
  i="$1"
  all_args="$all_args $(quote_arg "$1")"
  case $i in
    --path|-p)            F_PATH="$2"     ;all_args="$all_args $(quote_arg "$2")";shift;;
    --file-name|-fn)      F_FNAME="$2"    ;all_args="$all_args $(quote_arg "$2")";shift;;
    --dir)                F_DIR="$2"      ;all_args="$all_args $(quote_arg "$2")";shift;;
    --min-size|-nz)       F_MIN_SIZE="$2" ;all_args="$all_args $(quote_arg "$2")";shift;;
    --max-size|-xz)       F_MAX_SIZE="$2" ;all_args="$all_args $(quote_arg "$2")";shift;;
    --show-ext|-sx)       SHOW_EXT=YES    ;;
    --show-name|-sn)      SHOW_FNAME=YES  ;;
    --show-dir|-sp)       SHOW_DIR=YES    ;;
    -s*)
      SHOW=${i##-s}
      if [ -z "$SHOW" ] && [[ ! "$2" =~ ^- ]]; then
        SHOW="$2"
        all_args="$all_args $(quote_arg "$2")"
        shift
      fi
    ;;
    --help|-h)            HELP=YES      ;;
    --noinfo)             NOINFO=YES    ;;
    *)
    ((argc=argc+1))
    eval "arg_$argc='${i//\'/\'\"\'\"\'}'"
    ;;
  esac
  shift
done
[[ "$SHOW" =~ x ]] && SHOW_EXT=YES
[[ "$SHOW" =~ n ]] && SHOW_FNAME=YES
[[ "$SHOW" =~ p ]] && SHOW_DIR=YES

# color variables
dkgray=[90m;red=[91m;green=[92m;yellow=[93m;blue=[94m;magenta=[95m
cyan=[96m;white=[97m;black=[30m;dkred=[31m;dkgreen=[32m;dkyellow=[33m
dkblue=[34m;dkmagenta=[35m;dkcyan=[36m;gray=[37m;cdef=[0m

# display some info
if [ "$NOINFO" = "NO" ]; then
  echo -e "$blue""git-hist-list ""$dkyellow""$ver""$cdef"
  echo $dkgray$0$all_args$cdef
fi

# help screen
#BEGIN_AS_IS
cl_op=$blue
cl_colons=$dkgray
if [ "$HELP" = "YES" ]; then
  echo "$white""# Help""$cdef"
  echo "Usage: "$dkgray"$0 "$cl_op"["$dkyellow"options"$cl_op"]"$cdef""
  echo $cl_op"["$dkyellow"options"$cl_op"]"$cl_colons":"
  echo "  "$yellow"--show-ext "$cl_op"or "$yellow"-sx"$cl_colons":"                          $white"merge timelines"
  echo "  "$yellow"--show-name "$cl_op"or "$yellow"-sn"$cl_colons":"                         $white"merge timelines"
  echo "  "$yellow"--show-dir "$cl_op"or "$yellow"-sp"$cl_colons":"                          $white"merge timelines"
  echo "  "$yellow"--file-name "$cl_op"or "$yellow"-fn"$cl_colons":" $white"filter by filename"
  echo "  "$yellow"--dir"$cl_colons":" $white"filter by dirname"
  echo "  "$yellow"--path "$cl_op"or "$yellow"-p"$cl_colons":" $white"filter by path (directory and file name)"
  echo "    "$dkgreen"Note"$cl_colons": "$cdef
  echo "      "When filtering by a string, you can preceed the string with some options:
  echo "      "- '"r"' to indicate a regex filter 'r"^(some|file)"'
  echo "      "- '"b"' to indicate a list of patterns matching the start of the string
  echo "        "e.g. "'b dir1/ dir2/'"
  echo "      "- '"e"' to indicate a list of patterns matching the end of the string
  echo "        "e.g. "'e .png .jpg'"
  echo "      "- '"c"' to indicate a list of patterns matching anywhere in the string
  echo "        "e.g. "'c foo'"
  echo "      "- '"x"' to indicate a list of patterns matching the whole string
  echo "        "e.g. "'x=exact file name.png'"
  echo "      "Negate a string pattern using "'!'" before or after the option letter:
  echo "        "e.g. "'x!=exact file name.png'"
  echo "        "e.g. "'!e=.png'"
  echo "      "Use "'='" to indicate a single pattern, insetead of many separated by spaces.
  echo "      "Use of "'='" or "'!='" alone imply option "'x'".
  echo "  "$yellow"--min-size "$cl_op"or "$yellow"-nz"$cl_colons":" $white"filter by minimum file size"
  echo "  "$yellow"--max-size "$cl_op"or "$yellow"-xz"$cl_colons":" $white"filter by maximum file size"
  echo "    "$dkgreen"Note"$cl_colons": "$cdef
  echo "      "When filtering by file size, you can append units to the number:
  echo "        "e.g. "100MB"
  echo "        "e.g. "1k"
  echo "      "It is case insensitive, and ignores the final "'B'" or "'b'" if present.
  exit 0
fi
#END_AS_IS

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
    if [ "$_not" = "0" ] && [ "${_fname:0:1}" = "!" ]; then
      _not="1"
      _fname="${_fname:1}"
    fi
    if [ "$_opt" != "r" ]; then
      if [ "${_fname:0:1}" = "=" ]; then
        _single="1"
        _fname="${_fname:1}"
      fi
    fi
    if [ "$_single" = "1" ] && [ -z "$_opt" ]; then
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
      if [ "$_single" = "0" ]; then
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

if [ ! -v "arg_1" ]; then
  debug arg_1 is not defined
  src_branch=
  src_dir=
elif [ ! -v "arg_2" ]; then
  debug arg_2 is not defined
  unset -v src_branch src_dir
  { IFS= read -r src_branch && IFS= read -r src_dir; } <<< `get_branch_and_dir "$arg_1"`

  if [ -z "$src_branch" ]
  then
    >&2 echo -e "\e[91m""Invalid usage, cannot determine the source branch""\e[0m"
    exit 1
  fi
  source_branch_exists=1

else
  debug arg_1 and arg_2 are defined
  src_branch="$(sed 's \\ \/ g' <<< "$arg_1")"
  src_dir="$(sed 's \\ \/ g' <<< "$arg_2")"
fi

print_var () { local cl_name="\e[38;5;146m" cl_value="\e[38;5;186m"; [ -v $1 ] && echo -e "$cl_name"$1"\e[0m"="$cl_value"${!1}"\e[0m"; }
if [ "$NOINFO" = "NO" ]; then
  print_var src_branch
  print_var src_dir
  print_var SHOW_EXT
  print_var SHOW_FNAME
  print_var SHOW_DIR
  print_var NOINFO
  if [ -v F_PATH ]; then
    print_var F_PATH
    print_var F_PATH_NOT
    print_var F_PATH_CI
  fi
  if [ -v F_DIR ]; then
    print_var F_DIR
    print_var F_DIR_NOT
    print_var F_DIR_CI
  fi
  if [ -v F_FNAME ]; then
    print_var F_FNAME
    print_var F_FNAME_NOT
    print_var F_FNAME_CI
  fi
  print_var F_MIN_SIZE
  print_var F_MAX_SIZE
fi

if [ ! -v source_branch_exists ]; then
  if ! git show-ref --verify --quiet refs/heads/$src_branch
  then
    >&2 echo -e "\e[91m""Invalid usage, source branch does not exist""\e[0m"
    exit 1
  fi
fi

# ref: https://stackoverflow.com/questions/543346/list-all-the-files-that-ever-existed-in-a-git-repository
git log --pretty=format: --name-only --diff-filter=A | sed -r 's .*(\..*) \1 p' | sort -u
