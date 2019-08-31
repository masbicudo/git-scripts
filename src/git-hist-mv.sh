#!/bin/bash
ver=v0.3.0
ZIP=NO
COPY=NO
DEL=NO
SIMULATE=NO
argc=0

dkgray=[90m;red=[91m;green=[92m;yellow=[93m;blue=[94m;magenta=[95m
cyan=[96m;white=[97m;black=[30m;dkred=[31m;dkgreen=[32m;dkyellow=[33m
dkblue=[34m;dkmagenta=[35m;dkcyan=[36m;gray=[37m;cdef=[0m

echo -e "$green""git-hist-mv ""$dkgreen""$ver""$cdef"

echo $dkgray$0 $@$cdef
for i in "$@"
do
case $i in
    --del|-d)
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
    --simulate|-s)
    SIMULATE=YES
    shift
    ;;
    *)
    ((argc=argc+1))
    eval "arg_$argc=$i"
    shift
    ;;
esac
done

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

  inner_path=$(sed 's '"$branch"'/\?  g' <<< "$arg_1")
  echo $inner_path
}

if [ -z "$arg_3" ] && [ -z "$arg_4" ]; then
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

elif [ ! -z "$arg_3" ] && [ -z "$arg_4" ]; then
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

if [ "$SIMULATE" == "YES" ]; then
  echo -e "$red"Exiting simulation!"$cdef"
  exit 2
fi

if [ "$DEL" == "NO" ]; then
  # when not deleting a branch or a subfolder
  # the _temp branch is needed to do manipulations
  git branch _temp $src_branch
fi

# if not copying, delete source files
if [ "$COPY" == "NO" ]; then
  if [ -z "$src_dir" ]; then
    git branch -D $src_branch
    ZIP=
    ####git filter-branch -f --prune-empty --index-filter '
    ####  git rm --cached --ignore-unmatch -r -f '*'
    ####  ' -- $src_branch
  else
    git filter-branch -f --prune-empty --index-filter '
      git rm --cached --ignore-unmatch -r -f '$src_dir'
      ' -- $src_branch
  fi
  # deleting 'original' branches (git creates these as backups)
  git update-ref -d refs/original/refs/heads/$src_branch
  
  # if we are only deleting something, then we are done
  if [ "$DEL" == "YES" ]; then
    exit 0
  fi
fi

# moving subdirectory to root with --subdirectory-filter
if [ ! -z "$src_dir" ]; then
  git filter-branch --prune-empty --subdirectory-filter $src_dir -- _temp
  # deleting 'original' branches (git creates these as backups)
  git update-ref -d refs/original/refs/heads/_temp
fi

git filter-branch -f --prune-empty --index-filter '
  PATHS=`git ls-files -s | sed "s \t\"* &'$dst_dir'/ "`
  echo -n "$PATHS" |
    GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info &&
    mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"' -- _temp
# deleting 'original' branches (git creates these as backups)
git update-ref -d refs/original/refs/heads/_temp

# getting commit hashes and datetimes
if [ "$ZIP" == "YES" ]; then
  local commit1=0 datetime1=0 commit2=0 datetime2=0
  { read commit1 datetime1 ; } < <(
    git log --reverse --max-parents=0 --format="%H %at" $dst_branch | head -1
  )
  { read commit2 datetime2 ; } < <(
    git log --reverse --max-parents=0 --format="%H %at" _temp | head -1
  )
  declare rebase_hash=0
  if [ "$datetime1" -gt "$datetime2" ]; then
    git log --before $datetime1 --format="%H" -n 1 _temp
    rebase_hash=`git log --before $datetime1 --format="%H" -n 1 _temp`
  else
    git log --before $datetime2 --format="%H" -n 1 $dst_branch
    rebase_hash=`git log --before $datetime2 --format="%H" -n 1 $dst_branch`
  fi
fi

# need to checkout because merge may result in conficts
# it is a requirement of the merge command
git checkout $dst_branch 2>/dev/null || {
  git checkout --orphan $dst_branch
  git rm -rf .
}

git merge --allow-unrelated-histories --no-edit -m "Merge branch '$src_branch' into '$dst_branch'" _temp;

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
