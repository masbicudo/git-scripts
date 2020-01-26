#!/bin/bash
ver=v0.3.4

# argument variables
ZIP=NO
COPY=NO
DEL=NO
SIMULATE=NO
HELP=NO
NOINFO=NO

function quote_arg {
  if [[ $# -eq 0 ]]; then return 1; fi
  # if argument 1 contains:
  # - spaces or tabs
  # - new lines
  # - is empty
  # then: needs to be quoted
  if [[ ! "$1" =~ [[:blank:]] ]] && [ "${1//
/}" == "$1" ] && [ ! -z "$1" ]
  then echo "${1//\'/\"\'\"}"; 
  else echo "'${1//\'/\'\"\'\"\'}'"
  fi
  return 0
}

# reading arguments
all_args=
if [ "$*" == "" ]; then
  # if there are no arguments, then show help
  HELP=YES
fi
argc=0
while [[ $# -gt 0 ]]
do
  i="$1"
  all_args="$all_args $(quote_arg "$i")"
  case $i in
    --file-name|-fn)      F_FNAME=$2    ;shift;;
    --dir)                F_DIR=$2      ;shift;;
    --min-size)           F_MIN_SIZE=$2 ;shift;;
    --max-size)           F_MAX_SIZE=$2 ;shift;;
    --delete|--del|-d)    DEL=YES             ;;
    --zip|-z)             ZIP=YES             ;;
    --copy|-c)            COPY=YES            ;;
    --simulate|--sim|-s)  SIMULATE=YES        ;;
    --help|-h)            HELP=YES            ;;
    --noinfo)             NOINFO=YES          ;;
    *)
    ((argc=argc+1))
    eval "arg_$argc='${i//\'/\'\"\'\"\'}'"
    ;;
  esac
  shift
done

_has_filter=0
if [ -v F_FNAME ] || [ -v F_DIR ] || [ -v F_MIN_SIZE ] || [ -v F_MAX_SIZE ]
then
  _has_filter=1
fi

# color variables
dkgray=[90m;red=[91m;green=[92m;yellow=[93m;blue=[94m;magenta=[95m
cyan=[96m;white=[97m;black=[30m;dkred=[31m;dkgreen=[32m;dkyellow=[33m
dkblue=[34m;dkmagenta=[35m;dkcyan=[36m;gray=[37m;cdef=[0m

# display some info
if [ "$NOINFO" == "NO" ]; then
  echo -e "$blue""git-hist-mv ""$dkyellow""$ver""$cdef"
  echo $dkgray$0$all_args$cdef
fi

# help screen
cl_op=$blue
cl_colons=$dkgray
if [ "$HELP" == "YES" ]; then
  echo -e "$white""# Help""$cdef"
  echo "Usage: "$dkgray"$0 "$cl_op"["$dkyellow"source and target"$cl_op"] "$cl_op"["$dkyellow"options"$cl_op"]"$cdef""
  echo $cl_op"["$dkyellow"source and target"$cl_op"]"$cl_colons":"$cdef
  echo "  "Specify the source and target of the operation.
  echo "  "They can be specified in three formats:
  echo "  "$cl_op"- "$dkyellow"Joined format"$cl_colons": "$white"branch/directory/filename"$cdef
  echo "    "$red"Example"$cl_colons": "
  echo "      "$dkgray"$0"$yellow" 'some/branch/filename' 'other-branch/dir/fname.txt'"
  echo "    "$dkgreen"Note"$cl_colons": "$cdef
  echo "      Branch names containing '/' can be recognized if they actually exist."
  echo "      The joined format only supports branches that exist."
  echo "      In the previous example, 'some/branch' and 'other-branch' must both"
  echo "      exist in the local repo."
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
  exit 0
fi

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
  echo $branch

  inner_path=
  if [ ! -z "$branch" ]; then
    inner_path=`sed 's ^'"$branch"'/\?  g' <<< "$arg_1"`
  fi
  echo "$inner_path"
}

if [ ! -v "arg_3" ] && [ ! -v "arg_4" ]; then
  unset -v src_branch src_dir
  { IFS= read -r src_branch && IFS= read -r src_dir; } < <(get_branch_and_dir "$arg_1")
  unset -v dst_branch dst_dir
  { IFS= read -r dst_branch && IFS= read -r dst_dir; } < <(get_branch_and_dir "$arg_2")

  if [ -z "$src_branch" ]
  then
    >&2 echo -e "\e[91m""Invalid usage, cannot determine the source branch""\e[0m"
    exit 1
  fi
  source_branch_exists=TRUE
  if [ -z "$dst_branch" ]
  then
    dst_branch="$(sed 's \\ \/ g; s /.*  g' <<< "$arg_2")"
    dst_dir="$(sed 's \\ \/ g; s ^[^/]*\(/\|$\)  g' <<< "$arg_2")"
  fi

elif [ -v "arg_3" ] && [ ! -v "arg_4" ]; then
  >&2 echo -e "\e[91m""Invalid usage, must specify 2 or 4 ordinal params""\e[0m"
  exit 1
else
  src_branch="$(sed 's \\ \/ g' <<< "$arg_1")"
  src_dir="$(sed 's \\ \/ g' <<< "$arg_2")"
  dst_branch="$(sed 's \\ \/ g' <<< "$arg_3")"
  dst_dir="$(sed 's \\ \/ g' <<< "$arg_4")"
fi

cl_name="\e[38;5;146m"
cl_value="\e[38;5;186m"
if [ "$NOINFO" == "NO" ]; then
  echo -e "$cl_name"src_branch"\e[0m"="$cl_value"$src_branch"\e[0m"
  echo -e "$cl_name"src_dir"\e[0m"="$cl_value"$src_dir"\e[0m"
  echo -e "$cl_name"dst_branch"\e[0m"="$cl_value"$dst_branch"\e[0m"
  echo -e "$cl_name"dst_dir"\e[0m"="$cl_value"$dst_dir"\e[0m"
  echo -e "$cl_name"ZIP"\e[0m"="$cl_value"$ZIP"\e[0m"
  echo -e "$cl_name"COPY"\e[0m"="$cl_value"$COPY"\e[0m"
  echo -e "$cl_name"DEL"\e[0m"="$cl_value"$DEL"\e[0m"
  echo -e "$cl_name"NOINFO"\e[0m"="$cl_value"$NOINFO"\e[0m"
  [ -v F_FNAME ] && echo -e "$cl_name"F_FNAME"\e[0m"="$cl_value"$F_FNAME"\e[0m"
  [ -v F_DIR ] && echo -e "$cl_name"F_DIR"\e[0m"="$cl_value"$F_DIR"\e[0m"
  [ -v F_MIN_SIZE ] && echo -e "$cl_name"F_MIN_SIZE"\e[0m"="$cl_value"$F_MIN_SIZE"\e[0m"
  [ -v F_MAX_SIZE ] && echo -e "$cl_name"F_MAX_SIZE"\e[0m"="$cl_value"$F_MAX_SIZE"\e[0m"
  if [ "$SIMULATE" == "YES" ]; then
    echo -e "$cl_name"SIMULATE"\e[0m"="$cl_value"$SIMULATE"\e[0m"
  fi
fi

if [ -z "$source_branch_exists" ]; then
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

if [ "$DEL" == "NO" ] && [ -z "$dst_branch" ]; then
  >&2 echo -e "\e[91m""Invalid usage, must specify a destination branch, --del or -d""\e[0m"
  exit 1
fi

if [ "$DEL" == "YES" ] && [ "$COPY" == "YES" ]; then
  >&2 echo -e "\e[91m""Invalid usage, --del or -d is not compatible with --copy or -c""\e[0m"
  exit 1
fi

if [ "$DEL" == "YES" ] && [ "$ZIP" == "YES" ]; then
  >&2 echo -e "\e[91m""Invalid usage, --del or -d is not compatible with --zip or -z""\e[0m"
  exit 1
fi

if [ "$DEL" == "YES" ] && [ ! -z "$dst_branch" ]; then
  >&2 echo -e "\e[91m""Invalid usage, destination branch must be empty when using --del or -d""\e[0m"
  exit 1
fi

# replacing git command with a custom function to intercept all git commands
declare _git=`which git`
function git {
  unset -v _all_args
  for i in "$@"
  do
    _all_args="$_all_args $(quote_arg "$i")"
  done
  if [ "$SIMULATE" == "YES" ]
  then
    echo git "$_all_args"
  else
    if [ "$NOINFO" == "NO" ]; then
      echo $blue"git"$yellow"$_all_args"$cdef
    fi
    eval "'$_git'"$_all_args
  fi
}

function get_filtered_files_for_commit {
  commithash="$1"
  git diff-tree -r --name-only --diff-filter=AMT $commithash |
    tail -n +2 | (_iter=0; while read path; do
      
      # filtering by directory
      directory=$(dirname "$path")
      if [ "$directory" = "." ]; then directory=""; fi
      if [ ! -z "$_DIR" ]; then
        echo "$directory" | sed -r "/$_DIR/I!{q100}" &>/dev/null
        retVal=$?
        if [ $retVal -eq 100 ]; then
          continue
        fi
      fi
      
      # filtering by name
      _FNAME=$(basename "$path")
      if [ ! -z "$_FNAME" ]; then
        echo "$_FNAME" | sed -r "/$_FNAME/I!{q100}" &>/dev/null
        retVal=$?
        #echo retVal=$retVal
        if [ $retVal -eq 100 ]; then
          continue
        fi
      fi
      
      # filtering by size
      objsize=$(git cat-file -s "$commithash:$path")
      [ $objsize -lt $_SIZE ] && continue
      
      # displaying result
      if [ -z $_SL ]; then
        [ $_iter -eq 0 ] && echo -e "\n"$blue"$commithash"$cdef"\t"$dkblue$date"\n"$red"$message"$cdef
        [ -z "$directory" ] && __dir_name="" || __dir_name=$dkgray$(dirname "$path")$cdef"/"
        echo $__dir_name$white$(basename "$path")" "$yellow"$objsize"$cdef
      else
        [ $_iter -eq 0 ] && _color="$blue" || _color="$dkgray"
        [ -z "$directory" ] && __dir_name="" || __dir_name=$green$(dirname "$path")$cdef"/"
        echo $_color"$commithash"$cdef"/"$__dir_name$white$(basename "$path")" "$yellow"$objsize"$cdef
      fi
      let "_iter++"
    done)
}

# ref: https://stackoverflow.com/a/10433783/195417
contains_element () { for e in "${@:2}"; do [[ "$e" = "$1" ]] && return 0; done; return 1; }

function filter_ls_files {
  if [ "$_has_filter" == 1 ]; then
    readarray -t __files <<<"$(get_filtered_files_for_commit $GIT_COMMIT)"
  fi
  git ls-files --stage | (
    while read mode sha stage path
    do
      # ref: https://git-scm.com/docs/git-update-index#_using_index_info
      # TODO: use printf or echo to output a line for each file
      # - to remove a file write:
      #     0 0000000000000000000000000000000000000000	file_name
      # - to move a file write:
      #     $mode $sha $stage	new_file_name
      # if $1 contains "-r" reverse the logic, remove selected files, and keed unselected files
      # if $1 contains "-m" move files from src_dir to dst_dir (hint: use sed to replace, if pattern not found, remove file)

      # ref: https://stackoverflow.com/questions/56700325/xor-conditional-in-bash
      ! [ "$1" == "-r" ]; TEST_REMOVE=$?

      # see: /kb/path_pattern.sh
      if [[ ! "$path" =~ ^(\")?"$src_dir"(\"|/|$) ]]; then
        TEST_SELECTED=0
      elif [ "$_has_filter" == 1 ]; then
        ! contains_element "$path" "${__files[@]}"; TEST_SELECTED=$?
      else
        TEST_SELECTED=1
      fi

      if [ $TEST_REMOVE -e $TEST_SELECTED ]; then
        printf "0 0000000000000000000000000000000000000000\t$path\n"
      else
        if [ "$1" == "-m" ]; then
          # see: /kb/path_pattern.sh
          path=`sed -E 's|^("?)'"${src_dir/\./\\.}"'(/\|"\|$)|\1'"$dst_dir"'\2|g' <<< "$path"`
        fi
        printf "$mode $sha $stage\t$path\n"
      fi
    done
  )
}

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
if [ "$DEL" == "NO" ]; then
  # when not deleting a branch or a subfolder
  # the _temp branch is needed to do manipulations
  git branch _temp $src_branch
fi

# if not copying, delete source files
if [ "$COPY" == "NO" ]; then
  if [ "$_has_filter" == 1 ]; then
    # if there are filters, then we need to remove file by file
    git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
      PATHS=`git ls-files -s | filter_ls_files -r`;
      echo -n "$PATHS" |
        GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info &&
        mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"' -- "$src_branch"
  elif [ -z "$src_dir" ]; then
    # removing the branch, since source directory is the root
    git branch -D $src_branch
    ZIP=
  else
    # removing source directory from the source branch
    git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
      git rm --cached --ignore-unmatch -r -f '"'""${src_dir//\'/\'\"\'\"\'}""'"'
      ' -- "$src_branch"
  fi
  # deleting 'original' branches (git creates these as backups)
  git update-ref -d refs/original/refs/heads/"$src_branch"
fi

# if we are only deleting something, then we are done
if [ "$DEL" == "YES" ]; then
  exit 0
fi

# # moving subdirectory to root with --subdirectory-filter
# if [ ! -z "$src_dir" ]; then
#   git filter-branch --prune-empty --tag-name-filter cat --subdirectory-filter "$src_dir" -- _temp
#   # deleting 'original' branches (git creates these as backups)
#   git update-ref -d refs/original/refs/heads/_temp
# fi

# # # # moving the files to the target directory
# # # declare __dst_dir="${dst_dir//\'/\'\"\'\"\'}"
# # # __dst_dir="${__dst_dir//\ /\\\ }"
# using filter-branch with update-index to move files
# - filter-branch iterates each commit
# - update-index changes a file path in a commit
# - ls-files is used to get a list of files in a format supported by update-index
#     example output line:
#       100644 9ff97a979712c881faa31edb5087c0e758ecfc05 0       dir_name/file_name.txt
# - sed does the replacing of old-path with the new path
# TODO: if dst_dir is empty, the following command does nothing
git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
  PATHS=`git ls-files -s | filter_ls_files -m`;
  echo -n "$PATHS" |
    GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info &&
    mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"' -- _temp
# deleting 'original' branches (git creates these as backups)
git update-ref -d refs/original/refs/heads/_temp

# getting commit hashes and datetimes
declare commit1=0 datetime1=0 commit2=0 datetime2=0
if [ "$SIMULATE" == "NO" ]; then
  #cannot simulate these commands
  { read commit1 datetime1 ; } < <(
    git log --reverse --max-parents=0 --format="%H %at" "$dst_branch" | head -1
  )
  { read commit2 datetime2 ; } < <(
    git log --reverse --max-parents=0 --format="%H %at" _temp | head -1
  )
fi
declare rebase_hash="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
if [ "$datetime1" -gt 0 ] && [ "$datetime2" -gt 0 ]; then
  if [ "$datetime1" -gt "$datetime2" ]; then
    git log --before $datetime1 --format="%H" -n 1 _temp
    rebase_hash=`git log --before $datetime1 --format="%H" -n 1 _temp`
  else
    git log --before $datetime2 --format="%H" -n 1 "$dst_branch"
    rebase_hash=`git log --before $datetime2 --format="%H" -n 1 $dst_branch`
  fi
fi

# need to checkout because merge may result in conficts
# it is a requirement of the merge command
if git checkout "$dst_branch" 2>/dev/null
then
  declare _cur_branch=
  _cur_branch=`git branch --show-current`
  echo Current branch is: $_cur_branch
  git merge --allow-unrelated-histories --no-edit -m "Merge branch '$src_branch' into '$dst_branch'" _temp;
else
  #git checkout --orphan "$dst_branch"
  #git rm -r .
  ##git rm -rf .
  git branch "$dst_branch" _temp
  git checkout "$dst_branch"
fi

# zipping timelines:
if [ "$ZIP" == "YES" ]; then
  git -c rebase.autoSquash=false rebase --autostash "$rebase_hash"
elif [ "$ZIP" == "NO" ]; then
  echo -e "\e[94mTo zip the timelines you can run a git rebase on"
  echo -e "the commit \e[93m$rebase_hash\e[0m"
  echo -e "e.g. \e[97mgit -c rebase.autoSquash=false rebase --autostash "$rebase_hash"\e[0m"
fi

# deleting _temp branch
git branch -D _temp
