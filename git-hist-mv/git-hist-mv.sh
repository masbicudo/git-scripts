#!/bin/bash
ver=v0.3.0
ZIP=NO
COPY=NO
DEL=NO
argc=0
echo $@
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
    *)
    ((argc=argc+1))
    eval "arg_$argc=$i"
    shift
    ;;
esac
done

echo -e "\e[92m""git-hist-mv ""\e[32m""$ver""\e[0m"

src_branch="$(sed 's \\ \/ g; s /.*  g' <<< "$arg_1")"
src_dir="$(sed 's \\ \/ g; s ^[^/]*\(/\|$\)  g' <<< "$arg_1")"
dst_branch="$(sed 's \\ \/ g; s /.*  g' <<< "$arg_2")"
dst_dir="$(sed 's \\ \/ g; s ^[^/]*\(/\|$\)  g' <<< "$arg_2")"

cl_name="\e[38;5;146m"
cl_value="\e[38;5;186m"
echo -e "$cl_name"src_branch"\e[0m"="$cl_value"$src_branch"\e[0m"
echo -e "$cl_name"src_dir"\e[0m"="$cl_value"$src_dir"\e[0m"
echo -e "$cl_name"dst_branch"\e[0m"="$cl_value"$dst_branch"\e[0m"
echo -e "$cl_name"dst_dir"\e[0m"="$cl_value"$dst_dir"\e[0m"
echo -e "$cl_name"ZIP"\e[0m"="$cl_value"$ZIP"\e[0m"
echo -e "$cl_name"COPY"\e[0m"="$cl_value"$COPY"\e[0m"
echo -e "$cl_name"DEL"\e[0m"="$cl_value"$DEL"\e[0m"

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
