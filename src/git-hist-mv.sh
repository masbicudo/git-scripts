#!/bin/bash
ver=v0.3.6

# argument variables
ZIP=NO
COPY=NO
DEL=NO
SIMULATE=NO
HELP=NO
NOINFO=NO

# color variables
dkgray=[90m;red=[91m;green=[92m;yellow=[93m;blue=[94m;magenta=[95m
cyan=[96m;white=[97m;black=[30m;dkred=[31m;dkgreen=[32m;dkyellow=[33m
dkblue=[34m;dkmagenta=[35m;dkcyan=[36m;gray=[37m;cdef=[0m

# checking terminal
if [ "${SHELL%%/bin/bash}" = "$SHELL" ]; then
  >&2 echo $red"Only bash is supported at the moment, current is $SHELL"$cdef
  exit 11
fi

# check OS
if [[ "$OSTYPE" == "linux-gnu" ]]; then os_not_supported=1
  # Linux
elif [[ "$OSTYPE" == "darwin"* ]]; then os_not_supported=1
  # Mac OSX
elif [[ "$OSTYPE" == "cygwin" ]]; then os_not_supported=1
  # POSIX compatibility layer and Linux environment emulation for Windows
elif [[ "$OSTYPE" == "msys" ]]; then os_not_supported=0
  # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
elif [[ "$OSTYPE" == "win32" ]]; then os_not_supported=1
  # I'm not sure this can happen.
elif [[ "$OSTYPE" == "freebsd"* ]]; then os_not_supported=1
  # FreeBSD
else os_not_supported=1
  # Unknown.
fi

if [ "$os_not_supported" = "1" ]; then
  >&2 echo $red"Only msys is supported at the moment, current is $OSTYPE"$cdef
  exit 11
fi

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

# TODO: optimization - try to replace sed commands with variable replacements
# - convert: sed -e "s ^\"  ;s \"$  "
# - to this: _path="${1/#\"/}"; _path="${_path/%\"/}"
# (NOTE: test to see if it is really faster! on Windows, on Linux and on Mac if possible)

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
    --delete|--del|-d)    DEL=YES       ;;
    --zip|-z)             ZIP=YES       ;;
    --copy|-c)            COPY=YES      ;;
    --simulate|--sim|-s)  SIMULATE=YES  ;;
    --help|-h)            HELP=YES      ;;
    --noinfo)             NOINFO=YES    ;;
    *)
    ((argc=argc+1))
    eval "arg_$argc='${i//\'/\'\"\'\"\'}'"
    ;;
  esac
  shift
done

declare -x _has_filter=0
if [ -v F_FNAME ] || [ -v F_DIR ] || [ -v F_MIN_SIZE ] || [ -v F_MAX_SIZE ]
then
  _has_filter=1
fi

# display some info
if [ "$NOINFO" = "NO" ]; then
  echo -e "$blue""git-hist-mv ""$dkyellow""$ver""$cdef"
  echo $dkgray$0$all_args$cdef
  debug_file "# git-hist-mv $ver $(date --utc +%FT%T.%3NZ)"
  debug_file "  $(pwd)"
  debug_file "  $0$all_args"
fi

# checking git version
if ! which git > /dev/null 2>&1; then
  >&2 echo $red"git is not installed"$cdef
  __error=1
fi
git_ver=$(git --version)
git_ver_SEP=$(echo "$git_ver" | sed 's/[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/_SEPARATOR_/')
git_ver_s=$(echo "$git_ver_SEP" | sed 's/_SEPARATOR_.*$//')
git_ver_e=$(echo "$git_ver_SEP" | sed 's/^.*_SEPARATOR_//')
git_ver=${git_ver#"$git_ver_s"}
git_ver=${git_ver%"$git_ver_e"}
min_supported_git_ver=2.23.0
read min_git_ver <<< $(echo "$min_supported_git_ver
$git_ver" | sort -t '.' -k 1,1 -k 2,2 -k 3,3 -k 4,4)
if [ "$min_git_ver" = "$git_ver" ] && [ "$min_git_ver" != "$min_supported_git_ver" ]; then
  >&2 echo $red"Error: minimum supported git version is $min_supported_git_ver"$cdef
  __error=1
fi

print_var () { local cl_name="\e[38;5;146m" cl_value="\e[38;5;186m"; [ -v $1 ] && echo -e "$cl_name"$1"\e[0m"="$cl_value"${!1}"\e[0m"; }
print_var SHELL
print_var OSTYPE
print_var git_ver

# help screen
#BEGIN_AS_IS
cl_op=$blue
cl_colons=$dkgray
if [ "$HELP" = "YES" ]; then
  echo "$white""# Help""$cdef"
  echo "Usage: "$dkgray"$0 "$cl_op"["$dkyellow"source and target"$cl_op"] "$cl_op"["$dkyellow"options"$cl_op"]"$cdef""
  echo $cl_op"["$dkyellow"source and target"$cl_op"]"$cl_colons":"$cdef
  echo "  "Specify the source and target of the operation.
  echo "  "They can be specified in three formats:
  echo "  "$cl_op"- "$dkyellow"Joined format"$cl_colons": "$white"branch/directory/filename"$cdef
  echo "    "$red"Example"$cl_colons": "
  echo "      "$dkgray"$0"$yellow" 'some/branch/filename' 'other-branch/dir/fname.txt'"
  echo "    "$dkgreen"Note"$cl_colons": "$cdef
  echo "      Branch names containing '/' can be recognized if they actually exist."
  echo "      The joined format tries to match branches that exist first."
  echo "      The source branch must exist, but the destination does not."
  echo "      In this case, the first part of the path is the new-branch name."
  echo "  "$cl_op"- "$dkyellow"Separated format"$cl_colons": "$white"branch first then directory/filename"$cdef
  echo "    "$red"Example"$cl_colons": "
  echo "      "$dkgray"$0"$yellow" 'some/branch' 'filename' 'new-branch' 'dir/fname.txt'"
  echo "    "$dkgreen"Note"$cl_colons": "$cdef
  echo "      Branch names containing '/' can be used even if they don't exist."
  echo "      The separated format supports creating new branches."
  echo "      In the previous example, 'new-branch' can be non-existent."
  echo "  "$dkgreen"Note"$cl_colons": "$cdef
  echo "    "If both source and target are specified, both must be in the same
  echo "    "format, that is, either 2 or 4 path arguments are supported. If 2, then
  echo "    "format is joined, if 4, then format is separated.
  echo $cl_op"["$dkyellow"options"$cl_op"]"$cl_colons":"
  echo "  "$yellow"--zip "$cl_op"or "$yellow"-z"$cl_colons":"                                $white"merge timelines"
  echo "  "$yellow"--copy "$cl_op"or "$yellow"-c"$cl_colons":"                               $white"copy instead of move"
  echo "  "$yellow"--delete "$cl_op"or "$yellow"--del "$cl_op"or "$yellow"-d"$cl_colons":"   $white"delete instead of move"
  echo "  "$yellow"--simulate "$cl_op"or "$yellow"--sim "$cl_op"or "$yellow"-s"$cl_colons":" $white"show all git commands instead of executing them"
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

if [ -v __error ]; then exit 11; fi

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

declare -x F_FNAME_NOT F_FNAME_CI F_FNAME
declare -x F_DIR_NOT F_DIR_CI F_DIR
declare -x F_PATH_NOT F_PATH_CI F_PATH
declare -x F_MIN_SIZE F_MAX_SIZE

# git command alternative that intercept the commands and displays them before executing
function __git {
  local _all_args=
  for i in "$@"
  do
    _all_args="$_all_args $(quote_arg "$i")"
  done
  if [ "$SIMULATE" = "YES" ]
  then
    echo $blue"git"$yellow"$_all_args"$cdef
  else
    if [ "$NOINFO" = "NO" ]; then
      echo $blue"git"$yellow"$_all_args"$cdef
    fi
    eval git$_all_args
  fi
}

function get_branch_and_dir {
  # Separates a "branch/path' specifier into a branch and a path.
  # This will print two lines, the 1st is the branch name, the 2nd is the path.
  # If the branch does not exist in the repository, then branch and path
  # are returned empty.
  arg_1=$(sed 's \\ / g' <<< "$1")

  branch=$(
    git for-each-ref refs/heads --format='%(refname)' | sed 's refs/heads/  g' | while read x
    do
      arg_1=$(sed 's /*$ / g' <<< "$arg_1")
      arg_1_split=$(sed 's ^'"$x"'/  g' <<< "$arg_1")
      if [ "$arg_1" != "$arg_1_split" ]
      then
        echo $x
        break
      fi
    done
  )
  echo "$branch"

  inner_path=
  if [ ! -z "$branch" ]; then
    inner_path=`sed 's ^'"$branch"'/\?  g' <<< "$arg_1"`
  fi
  echo "$inner_path"
}

if [ ! -v "arg_3" ] && [ ! -v "arg_4" ]; then
  debug arg_3 and arg_4 are empty
  unset -v src_branch src_dir
  { IFS= read -r src_branch && IFS= read -r src_dir; } <<< `get_branch_and_dir "$arg_1"`
  unset -v dst_branch dst_dir
  { IFS= read -r dst_branch && IFS= read -r dst_dir; } <<< `get_branch_and_dir "$arg_2"`

  debug dst_branch=$dst_branch

  if [ -z "$src_branch" ]
  then
    >&2 echo -e "\e[91m""Invalid usage, cannot determine the source branch""\e[0m"
    exit 1
  fi
  source_branch_existed=1
  if [ -z "$dst_branch" ]
  then
    dst_branch="$(sed 's \\ \/ g; s /.*  g' <<< "$arg_2")"
    dst_dir="$(sed 's \\ \/ g; s ^[^/]*\(/\|$\)  g' <<< "$arg_2")"
  else
    dst_branch_existed=1
  fi

elif [ -v "arg_3" ] && [ ! -v "arg_4" ]; then
  debug arg_3 is empty
  >&2 echo -e "\e[91m""Invalid usage, must specify 2 or 4 ordinal params""\e[0m"
  exit 1
else
  debug arg_3 and arg_4 are defined
  src_branch="$(sed 's \\ \/ g' <<< "$arg_1")"
  src_dir="$(sed 's \\ \/ g' <<< "$arg_2")"
  dst_branch="$(sed 's \\ \/ g' <<< "$arg_3")"
  dst_dir="$(sed 's \\ \/ g' <<< "$arg_4")"
fi
declare -x src_dir
declare -x dst_dir

if [ "$NOINFO" = "NO" ]; then
  print_var src_branch
  print_var src_dir
  print_var dst_branch
  print_var dst_dir
  print_var ZIP
  print_var COPY
  print_var DEL
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
  if [ "$SIMULATE" = "YES" ]; then
    print_var SIMULATE
  fi
fi

if [ ! -v source_branch_existed ]; then
  if ! git show-ref --verify --quiet refs/heads/$src_branch
  then
    >&2 echo -e "\e[91m""Invalid usage, source branch does not exist""\e[0m"
    exit 1
  fi
fi

if [ -z "$src_branch" ]; then
  >&2 echo -e "\e[91m""Invalid usage, must specify source branch""\e[0m"
  exit 1
fi

if [ ! -z dst_branch ] && [ "${dst_branch//[[:blank:]]/}" != "$dst_branch" ]; then
  >&2 echo -e "\e[91m""Invalid branch name: ""$dst_branch""\e[0m"
  exit 1
fi

if [ "$DEL" = "NO" ] && [ -z "$dst_branch" ]; then
  >&2 echo -e "\e[91m""Invalid usage, must specify a destination branch, --del or -d""\e[0m"
  exit 1
fi

if [ "$DEL" = "YES" ] && [ "$COPY" = "YES" ]; then
  >&2 echo -e "\e[91m""Invalid usage, --del or -d is not compatible with --copy or -c""\e[0m"
  exit 1
fi

if [ "$DEL" = "YES" ] && [ "$ZIP" = "YES" ]; then
  >&2 echo -e "\e[91m""Invalid usage, --del or -d is not compatible with --zip or -z""\e[0m"
  exit 1
fi

if [ "$ZIP" = "YES" ] && [ "$COPY" = "NO" ] && [ "$src_branch" = "$dst_branch" ]; then
  >&2 echo -e "$red""Warning: "$dkyellow"zip does nothing when moving inside a single branch""\e[0m"
fi

if [ "$DEL" = "YES" ] && [ ! -z "$dst_branch" ]; then
  >&2 echo -e "\e[91m""Invalid usage, destination branch must be empty when using --del or -d""\e[0m"
  exit 1
fi

function is_file_selected {
  debug_file "      ## is_file_selected"
  debug_file "        F_DIR=$F_DIR F_FNAME=$F_FNAME F_MIN_SIZE=$F_MIN_SIZE F_MAX_SIZE=$F_MAX_SIZE"
  local _path="${1/#\"/}"
  _path="${_path/%\"/}"

  # filtering by path
  if [ -v F_PATH ]; then
    local _fpath="$_path"
    local _ci=""
    if [ "$F_PATH_CI" = "1" ]; then _ci="I"; fi
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
    if [ "$F_DIR_CI" = "1" ]; then _ci="I"; fi
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
    if [ "$F_FNAME_CI" = "1" ]; then _ci="I"; fi
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
declare -fx is_file_selected

function filter_ls_files {
  debug_file "  ## filter_ls_files $1"
  debug_file "    _has_filter=$_has_filter"
  debug_file "    GIT_COMMIT=$GIT_COMMIT"
  # ref: https://stackoverflow.com/questions/1951506/add-a-new-element-to-an-array-without-specifying-the-index-in-bash
  __rm_files=()

  while read mode sha stage path
  do
    debug_file "    $mode $sha $stage $path"
    # ref: https://git-scm.com/docs/git-update-index#_using_index_info
    # use printf or echo to output a line for each file
    # - to remove a file just skip it, don't write a corresponding line, then git rm that file
    # - to move a file write: $mode $sha $stage	new_file_name
    #     Note: the char before new_file_name is a TAB character (ALT + NumPad 0 0 9)
    # if $1 contains:
    # - "-r": remove selected files, and keed unselected files
    # - "-m": remove unselected files and move selected files from src_dir to dst_dir
    # - "-s": move selected files from src_dir to dst_dir

    # ref: https://stackoverflow.com/questions/56700325/xor-conditional-in-bash
    ! [ "$1" = "-r" ]; TEST_REMOVE=$?

    # see: /kb/path_pattern.sh
    if [ ! -z "$src_dir" ] && [[ ! "${path}" =~ ^(\")?"$src_dir"(\"|/|$) ]]; then
      TEST_SELECTED="0"
    elif [ "$_has_filter" = "1" ]; then
      # remember: 0=OK non-zero=FAIL
      # when negating: 0=FAIL 1=OK
      # TODO: optimization - use an associative array to remember is a file is selected or not by using the $sha hash
      ! is_file_selected "$path"
      TEST_SELECTED=$?
    else
      TEST_SELECTED="1"
    fi

    debug_file "      TEST_REMOVE=$TEST_REMOVE"
    debug_file "      TEST_SELECTED=$TEST_SELECTED"

    if [ $TEST_REMOVE -ne $TEST_SELECTED ]; then
      if [ "$1" = "-m" ] || [ "$1" = "-s" ]; then
        # see: /kb/path_pattern.sh
        if [ "$src_dir" != "$dst_dir" ]; then
          if [ -z "$src_dir" ]
          then path=`sed -E 's|^("?)|\1'"$dst_dir"'/|g' <<< "$path"`
          elif [ -z "$dst_dir" ]
          then path=`sed -E 's|^("?)'"${src_dir/\./\\.}"'(/\|("\|$))|\1\3|g' <<< "$path"`
          else path=`sed -E 's|^("?)'"${src_dir/\./\\.}"'(/\|"\|$)|\1'"$dst_dir"'\2|g' <<< "$path"`
          fi
        fi
      fi
      debug_file "      update-index $mode $sha $stage $path"
      printf "$mode $sha $stage\t$path\n"
    elif [ "$1" != "-s" ]; then
      __rm_files+=("$path")
      debug_file "      __rm_files+=($path)"
    else
      debug_file "      update-index $mode $sha $stage $path"
      printf "$mode $sha $stage\t$path\n"
    fi
  done <<< "$(git ls-files --stage)"

  if [ ${#__rm_files[@]} -gt 0 ]; then
    debug_file "    ${__rm_files[@]}"
    git rm --cached --ignore-unmatch -r -f -- "${__rm_files[@]}" > /dev/null 2>&1
  fi
}
declare -fx filter_ls_files
function index_filter {
  # using filter-branch/index-filter, update-index/index-info and rm/cached to move and delete files
  # - filter-branch/index-filter iterates each commit without checking out each commit
  # - update-index/index-info changes multiple file pathes in a commit
  # - filter_ls_files is used to get a list of files in a format supported by update-index
  #     and it also deletes files that are not returned to the update-index command
  #     example output line:
  #       100644 9ff97a979712c881faa31edb5087c0e758ecfc05 0       dir_name/file_name.txt
  debug ""
  debug _has_filter=$_has_filter
  debug "GIT_INDEX_FILE=$GIT_INDEX_FILE"
  debug "GIT_COMMIT=$GIT_COMMIT"
  debug "src_dir=$src_dir"
  debug "dst_dir=$dst_dir"
  local _PATHS=`filter_ls_files $1`
  debug "$_PATHS"
  if [ -z "$_PATHS" ]; then return; fi
  # ref: https://unix.stackexchange.com/questions/358850/what-are-all-the-ways-to-create-a-subshell-in-bash
  # ref: https://unix.stackexchange.com/questions/153587/environment-variable-assignment-followed-by-command
  echo -n "$_PATHS" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --remove --index-info
  if [ -e "$GIT_INDEX_FILE.new" ]; then mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"; fi
}
declare -fx index_filter

function indent_prepend {
  local tab=$(echo -e '\t') IFS= line= trimmed= nocolors=
  while read line; do
    trimmed=`sed -E 's/[[:blank:]]+//g' <<< "${line}"`
    nocolors=`sed 's/\x1B\[[0-9;]\+[A-Za-z]//g;s/\x0f//g' <<< "${trimmed}"`
    if ! [[ -z "$nocolors" ]]; then break; fi
    echo -n "$trimmed"
  done
  if ! [[ -z "$nocolors" ]]; then
    echo ""
    echo "$tab$line"
  fi
  while read line; do
    echo "$tab$line"
  done
}
declare -fx indent_prepend

# General logic:
# 1) create a temporary branch based on the source branch
# 2) alter the source branch when moving or deleting files, by deleting the source directory
# 3) alter the temporary branch by moving the source directory to the root, deleting everything else
# 4) alter the temporary branch by moving the root to the destination directory
# 5) merge temporary directory into the destination branch
# 6) zip histories of destination branch

# KB: Env vars when doing filter-branch index-filter in Windows:
# GIT_AUTHOR_DATE=@1551747497 -0300
# GIT_AUTHOR_EMAIL=masbicudo@gmail.com
# GIT_AUTHOR_NAME=Miguel Angelo
# GIT_COMMIT=f99ac249f4effb7d58cc27b1d7be13dddaea5731
# GIT_COMMITTER_DATE=@1551750290 -0300
# GIT_COMMITTER_EMAIL=masbicudo@gmail.com
# GIT_COMMITTER_NAME=Miguel Angelo
# GIT_DIR=C:/Projects/git-scripts/.git
# GIT_EXEC_PATH=C:/Program Files/Git/mingw64/libexec/git-core
# GIT_INDEX_FILE=C:/Projects/git-scripts/.git-rewrite/t/../index
# GIT_INTERNAL_GETTEXT_SH_SCHEME=fallthrough
# GIT_WORK_TREE=.

# creating a temporary branch based on the source branch if needed
if [ "$DEL" = "NO" ]; then
  if [ "$src_branch" != "$dst_branch" ] || [ "$COPY" = "YES" ]; then
    # A temporary branch is needed to do manipulations when:
    # - not deleting a branch or files inside a branch
    # - not moving files inside a branch
    NEW_UUID="$(cat /dev/urandom | tr -dc '0-9A-F' | fold -w 32 | head -n 1)"
    tmp_branch="_temp_$NEW_UUID"
    __git branch $tmp_branch $src_branch
  fi
fi

# if moving inside a branch, just do the moving
# if not copying, delete source files
if [ "$COPY" = "NO" ]; then
  if [ "$DEL" = "NO" ] && [ "$src_branch" = "$dst_branch" ]; then
    # if moving inside a single branch, do it at once
    __git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
    index_filter -s | indent_prepend
    ' -- "$src_branch"
  elif [ "$_has_filter" = 1 ]; then
    # if there are filters, then we need to remove file by file
    __git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
    index_filter -r | indent_prepend
    ' -- "$src_branch"
  elif [ -z "$src_dir" ]; then
    # removing the branch, since source directory is the root
    __git branch -D "$src_branch"
    ZIP=
    if [ "$dst_branch" = "$src_branch" ]; then unset -v dst_branch_existed; fi
  else
    # removing source directory from the source branch
    __git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
      git rm --cached --ignore-unmatch -r -f '"'""${src_dir//\'/\'\"\'\"\'}""'"' | indent_prepend
      ' -- "$src_branch"
  fi
  # deleting 'original' branches (git creates these as backups)
  __git update-ref -d refs/original/refs/heads/"$src_branch"
fi

# if we are only deleting something or moving inside a branch, then we are done
if [ ! -v tmp_branch ]; then
  exit 0
fi

if [ -z "$dst_dir" ] && [ "$_has_filter" = "0" ]; then
  # moving subdirectory to root with --subdirectory-filter
  if [ ! -z "$src_dir" ]; then
    __git filter-branch --prune-empty --tag-name-filter cat --subdirectory-filter "$src_dir" -- "$tmp_branch"
    # deleting 'original' branches (git creates these as backups)
    __git update-ref -d refs/original/refs/heads/"$tmp_branch"
  fi
else
  declare -fx filter_to_move
  __git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
    index_filter -m | indent_prepend
    ' -- "$tmp_branch"
fi
# deleting 'original' branches (git creates these as backups)
__git update-ref -d refs/original/refs/heads/"$tmp_branch"

# getting commit hashes and datetimes
unset -v rebase_hash
if [ -v dst_branch_existed ]; then
  declare commit1=0 datetime1=0 commit2=0 datetime2=0
  if [ "$SIMULATE" = "NO" ]; then
    #cannot simulate these commands
    { read commit1 datetime1 ; } <<< "$(git log --reverse --max-parents=0 --format="%H %at" "$dst_branch" | head -1)"
    { read commit2 datetime2 ; } <<< "$(git log --reverse --max-parents=0 --format="%H %at" "$tmp_branch" | head -1)"
  fi
  debug "commit1=$commit1 datetime1=$datetime1"
  debug "commit2=$commit2 datetime2=$datetime2"
  rebase_hash="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  if [ "$datetime1" -gt 0 ] && [ "$datetime2" -gt 0 ]; then
    if [ "$datetime1" -gt "$datetime2" ]; then
      rebase_hash=`git log --before $datetime1 --format="%H" -n 1 "$tmp_branch"`
    else
      rebase_hash=`git log --before $datetime2 --format="%H" -n 1 "$dst_branch"`
    fi
  fi
  debug "rebase_hash=$rebase_hash"
fi

# need to checkout because merge may result in conficts
# it is a requirement of the merge command
if [ -v dst_branch_existed ]
then
  __git checkout "$dst_branch"
  declare _cur_branch=
  _cur_branch=`git branch --show-current`
  echo Current branch is: $_cur_branch
  __git merge --allow-unrelated-histories --no-edit -s recursive -X no-renames -X theirs --no-commit "$tmp_branch";
  # __git reset HEAD
  # __git add --ignore-removal .
  # __git checkout -- .
  # TODO: better commit messages:
  # - when copying, moving or deleting, it should be clear what was the operation
  __git commit -m "Merge branch '$src_branch' into '$dst_branch'"
else
  #git checkout --orphan "$dst_branch"
  #git rm -r .
  ##git rm -rf .
  if ! __git branch "$dst_branch" "$tmp_branch"
  then
    exit 1
  fi
  __git checkout "$dst_branch"
fi

# zipping timelines:
if [ -v rebase_hash ]; then
  if [ "$ZIP" = "YES" ]; then
    __git -c rebase.autoSquash=false rebase --autostash "$rebase_hash"
  elif [ "$ZIP" = "NO" ]; then
    echo -e "\e[94mTo zip the timelines you can run a git rebase on"
    echo -e "the commit \e[93m$rebase_hash\e[0m"
    echo -e "e.g. \e[97mgit -c rebase.autoSquash=false rebase --autostash "$rebase_hash"\e[0m"
  fi
fi

# deleting _temp branch
__git branch -D "$tmp_branch"
