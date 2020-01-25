#!/bin/bash
ver=v0.3.4

# argument variables
ZIP=NO
COPY=NO
DEL=NO
SIMULATE=NO
HELP=NO
NOINFO=NO

# reading arguments
all_args=
if [ "$*" == "" ]; then
  # if there are no arguments, then show help
  HELP=YES
fi
argc=0
for i in "$@"
do
  if [ "${i// /}" == "$i" ] && [ ! -z "$i" ]; then
    all_args="$all_args ${i//\'/\"\'\"}"
  else
    all_args="$all_args '${i//\'/\'\"\'\"\'}'"
  fi
  case $i in
    --delete|--del|-d)
    DEL=YES
    shift
    ;;
    --zip|-z)
    ZIP=YES
    shift
    ;;
    --copy|-c)
    COPY=YES
    shift
    ;;
    --simulate|--sim|-s)
    SIMULATE=YES
    shift
    ;;
    --help|-h)
    HELP=YES
    shift
    ;;
    --noinfo)
    NOINFO=YES
    shift
    ;;
    *)
    ((argc=argc+1))
    eval "arg_$argc='${i//\'/\'\"\'\"\'}'"
    shift
    ;;
  esac
done

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
declare newline="
"
declare _git=`which git`
function git {
  unset -v _all_args
  for i in "$@"
  do
    if [ "${i// /}" == "$i" ] && [ "${i//$newline/}" == "$i" ]; then
      _all_args="$_all_args ${i//\'/\"\'\"}"
    else
      _all_args="$_all_args '${i//\'/\'\"\'\"\'}'"
    fi
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

# General logic:
# 1) create a temporary branch based on the source branch
# 2) alter the source branch when moving or deleting files, by deleting the source directory
# 3) alter the temporary branch by moving the source directory to the root, deleting everything else
# 4) alter the temporary branch by moving the root to the destination directory
# 5) merge temporary directory into the destination branch
# 6) zip histories of destination branch

# creating a temporary branch based on the source branch if needed
if [ "$DEL" == "NO" ]; then
  # when not deleting a branch or a subfolder
  # the _temp branch is needed to do manipulations
  git branch _temp $src_branch
fi

# if not copying, delete source files
if [ "$COPY" == "NO" ]; then
  if [ -z "$src_dir" ]; then
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

# moving subdirectory to root with --subdirectory-filter
if [ ! -z "$src_dir" ]; then
  git filter-branch --prune-empty --tag-name-filter cat --subdirectory-filter "$src_dir" -- _temp
  # deleting 'original' branches (git creates these as backups)
  git update-ref -d refs/original/refs/heads/_temp
fi

# moving the files to the target directory
declare __dst_dir="${dst_dir//\'/\'\"\'\"\'}"
__dst_dir="${__dst_dir//\ /\\\ }"
git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
  PATHS=`git ls-files -s | sed "s \t\"* &"'"'""$__dst_dir""'"'"/ "`;
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
