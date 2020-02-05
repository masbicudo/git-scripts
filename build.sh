#!/bin/bash
dkgray=[90m;red=[91m;green=[92m;yellow=[93m;blue=[94m;magenta=[95m
cyan=[96m;white=[97m;black=[30m;dkred=[31m;dkgreen=[32m;dkyellow=[33m
dkblue=[34m;dkmagenta=[35m;dkcyan=[36m;gray=[37m;cdef=[0m

# TODO: concatenate contents of included files using "source" or "."

# reading arguments
argc=0
unset -v has_args
while [[ $# -gt 0 ]]
do
  i="$1"
  has_args=1
  case $i in
    --release|-r)         RELEASE_MSG="$2"  ;shift;;
    --install|-i)         INSTALL_PATH="$2" ;shift;;
    --path|-p)            BUILD_PATH="$2"   ;shift;;
    --save-branch|-sb|--load-branch|-lb)
      if [[ $i =~ --save-branch|-sb ]]
      then USE_SETTINGS="SAVE"; SAVE_SETTINGS="1"
      else USE_SETTINGS="LOAD"; LOAD_SETTINGS="1"
      fi
      if [ ! -z "$2" ] && ! [[ "$2" =~ ^- ]]; then
        SETTINGS_BRANCH="$2"; shift;
      else
        >&2 echo -e "\e[91m""Invalid usage, must specify a branch name""\e[0m"
        exit 1
      fi
      SETTINGS_PATH="settings.txt"
      ;;
    --save|-s)
      SAVE_SETTINGS="1"
      USE_SETTINGS="SAVE"
      if [ ! -z "$2" ] && ! [[ "$2" =~ ^- ]]; then
        if [ ! -z "$3" ] && ! [[ "$3" =~ ^- ]]; then
          SETTINGS_BRANCH="$2";
          SETTINGS_PATH="$3"; shift; shift;
        else
          SETTINGS_PATH="$2"; shift;
        fi
      else SETTINGS_PATH="settings.txt"; fi
      ;;
    --load|-l)
      LOAD_SETTINGS="1"
      USE_SETTINGS="LOAD"
      if [ ! -z "$2" ] && ! [[ "$2" =~ ^- ]]; then
        if [ ! -z "$3" ] && ! [[ "$3" =~ ^- ]]; then
          SETTINGS_BRANCH="$2";
          SETTINGS_PATH="$3"; shift; shift;
        else
          SETTINGS_PATH="$2"; shift;
        fi
      else SETTINGS_PATH="settings.txt"; fi
      LOAD_PATH="$SETTINGS_PATH"
      ;;
    --branch|-b)
      if [ ! -z "$2" ] && ! [[ "$2" =~ ^- ]]; then BRANCH="$2"; shift;
      else BRANCH=""; fi
      ;;
    *)
    ((argc=argc+1))
    eval "arg_$argc='${i//\'/\'\"\'\"\'}'"
    ;;
  esac
  shift
done

if [ -v BRANCH ] && [ -z "$BRANCH" ]; then
  >&2 echo -e "\e[91m""Invalid usage, if branch is specified it must exist""\e[0m"
  exit 1
fi

if [ -v SAVE_SETTINGS ] && [ -v LOAD_SETTINGS ]; then
  >&2 echo -e "\e[91m""Invalid usage, cannot load and save at the same time""\e[0m"
  exit 1
fi

if [ ! -v BUILD_PATH ] && [ ! -v INSTALL_PATH ] && [ -f "settings.txt" ]; then
  SETTINGS_PATH="settings.txt"
  USE_SETTINGS="LOAD"
fi

function move_to_temp {
  # ref: https://code-maven.com/create-temporary-directory-on-linux-using-bash
  tmp_dir="$(mktemp -d -t git-scripts-build-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXXXXXXXX)"
  # moving files that are not in the branch, if branch was specified
  while read fname; do
    mkdir `dirname "$tmp_dir"/"$fname"`
    mv "$fname" "$tmp_dir"/"$fname"
  done > /dev/null 2>&1
  # ref: https://askubuntu.com/questions/474556/hiding-output-of-a-command
  echo "$tmp_dir"
}

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

# git command alternative that intercept the commands and displays them before executing
function __git {
  local _all_args=
  for i in "$@"
  do
    _all_args="$_all_args $(quote_arg "$i")"
  done
  echo $blue"git"$yellow"$_all_args"$cdef
  eval git$_all_args
}

print_var () { local cl_name="\e[38;5;146m" cl_value="\e[38;5;186m"; [ -v $1 ] && echo -e "$cl_name"$1"\e[0m"="$cl_value"${!1}"\e[0m"; }

if [ -v USE_SETTINGS ]; then

  echo "$white"Settings file options:"$cdef"
  print_var USE_SETTINGS
  print_var SETTINGS_BRANCH
  print_var SETTINGS_PATH

  # saving/loading settings file
  if [ -v SETTINGS_BRANCH ]; then
    prev_branch=$(git symbolic-ref HEAD)
    # ref: https://stackoverflow.com/questions/17790123/shell-script-trying-to-validate-if-a-git-tag-exists-in-a-git-repository-in-an
    if [[ `git tag -l $SETTINGS_BRANCH` == "$SETTINGS_BRANCH" ]]
    then target_ref=refs/tags/"$SETTINGS_BRANCH"
    elif [ "$USE_SETTINGS" = "SAVE" ] || __git rev-parse --verify "$SETTINGS_BRANCH" | sed "s/^/  /"
    then target_ref=refs/heads/"$SETTINGS_BRANCH"
    else
      >&2 echo -e "\e[91m""Invalid usage, branch or tag of the settings file does not exist""\e[0m"
      exit 1
    fi
    __git symbolic-ref HEAD "$target_ref" | sed "s/^/  /"
    if [ -f "$SETTINGS_PATH" ]; then tmp_dir="$(echo "$SETTINGS_PATH" | move_to_temp)"; fi
    __git checkout "$target_ref" -- "$SETTINGS_PATH" | sed "s/^/  /"
  fi
  if [ "$USE_SETTINGS" = "SAVE" ]; then
    truncate -s 0 "$SETTINGS_PATH"
    if [ -v BUILD_PATH ]; then echo "BUILD_PATH=$BUILD_PATH" >> "$SETTINGS_PATH" ; fi
    if [ -v INSTALL_PATH ]; then echo "INSTALL_PATH=$INSTALL_PATH" >> "$SETTINGS_PATH" ; fi
    if [ -v SETTINGS_BRANCH ]; then
      __git reset
      __git add -f "$SETTINGS_PATH"
      # ref: https://stackoverflow.com/questions/8123674/how-to-git-commit-nothing-without-an-error
      __git diff-index --quiet HEAD || __git commit -m "$(echo "new settings file"; cat "$SETTINGS_PATH")"
    fi
  fi | sed "s/^/  /"
  if [ "$USE_SETTINGS" = "LOAD" ]; then
    # ref: https://www.cyberciti.biz/faq/unix-howto-read-line-by-line-from-file/
    while IFS=" " read -r var_name var_value
    do
      [ ! -v "$var_name" ] && declare "$var_name"="$var_value"
    done <<< "$(sed -r '
      /^(BUILD_PATH|INSTALL_PATH)=(.*)$/!d;
      s/=/ /;
      ' "$SETTINGS_PATH")"
  fi
  if [ -v tmp_dir ]; then
    mv -f "$tmp_dir"/"$SETTINGS_PATH" ./"$SETTINGS_PATH"
    rm -r "$tmp_dir"
  fi | sed "s/^/  /"
  unset -v tmp_dir
  if [ -v prev_branch ]; then
    __git symbolic-ref HEAD "$prev_branch"
    __git reset
  fi | sed "s/^/  /"
  unset -v prev_branch
fi

if [ ! -v BUILD_PATH ]; then BUILD_PATH="build"; fi

[ -v INSTALL_PATH ] && INSTALL_PATH=`dirname $INSTALL_PATH`/`basename $INSTALL_PATH`

echo "$white"Build options:"$cdef"
print_var BRANCH
print_var BUILD_PATH
print_var INSTALL_PATH
print_var RELEASE_MSG

if [ "$INSTALL_PATH" = "/" ]; then
  >&2 echo -e "\e[91m"Cannot install to the root"$cdef"
  exit 1
fi

# checking out the branch to build
if [ -v BRANCH ]; then
  echo "$white"checking out the branch to build"$cdef"
  prev_branch=$(git symbolic-ref HEAD)
  # ref: https://stackoverflow.com/questions/17790123/shell-script-trying-to-validate-if-a-git-tag-exists-in-a-git-repository-in-an
  if [[ `git tag -l $BRANCH` == "$BRANCH" ]]
  then target_ref=refs/tags/"$BRANCH"
  elif __git rev-parse --verify "$BRANCH" | sed "s/^/  /"
  then target_ref=refs/heads/"$BRANCH"
  else
    >&2 echo -e "\e[91m""Invalid usage, branch or tag to build does not exist""\e[0m"
    exit 1
  fi
  __git symbolic-ref HEAD "$target_ref" | sed "s/^/  /"
  __git reset | sed "s/^/  /"
  # moving files that are not in the branch, if branch was specified
  tmp_dir="$(echo "src/" | move_to_temp)"
  __git checkout HEAD -- ./src
fi

# building the src folder to the output build path
if [ ! -z "$BUILD_PATH" ] && [ "$BUILD_PATH" != "." ] && [ "$BUILD_PATH" != ".." ]; then
  current_branch=$(git symbolic-ref HEAD)
  if [ "$current_branch" != "refs/heads/master" ]
  then ver_append=$cdef' ('$red"$current_branch"$cdef')'
  else ver_append=$cdef' ('$dkgreen"$current_branch"$cdef')'
  fi
  ver_append="${ver_append//\\/\\\\}"
  ver_append="${ver_append//\(/\\\(}"
  ver_append="${ver_append//\//\\\/}"
  echo ver_append="$ver_append"
  echo "$white"building the src folder to the output build path"$cdef"
  rm -rf "$BUILD_PATH"
  [ ! -d "$BUILD_PATH" ] && mkdir "$BUILD_PATH"
  shopt -s nullglob
  for f in ./src/**.sh ./src/**/*.sh
  do
    _file="$BUILD_PATH/${f//\.\/src\//}"
    _dir=`dirname "$_file"`
    [ ! -d "$_dir" ] && mkdir "$_dir"
    echo "$_file"
    # ref: http://www.nongnu.org/bibledit/sed_rules_reference.html#addressesandrangesoftext
    sed -r '
    /#BEGIN_DEBUG/,/#END_DEBUG/d;
    /#BEGIN_AS_IS/,/#END_AS_IS/!{
      2,${/^ *debug/d};
      2,${/^ *#.*$/d};
      /^ *$/d;
      s/^ *//;
      /^ver=/ s/$/"'"$ver_append"'"/
    };
    2,${/^ *#(BEGIN|END)_AS_IS\b.*$/d
    }' "$f" > "$_file"
  done
fi | sed "2,$ s/^/  /"

# moving files back, if branch was specified
if [ -v BRANCH ]; then
  echo "$white"going back to the original branch and file contents"$cdef"
  if [ -v tmp_dir ]; then
    rm -r ./src
    mv "$tmp_dir"/src ./
    rm -r "$tmp_dir"
  fi
  if [ -v prev_branch ]; then
    __git symbolic-ref HEAD "$prev_branch"
    __git reset
  fi
fi | sed "2,$ s/^/  /"
unset -v tmp_dir
unset -v prev_branch

# copying files to install path
if [ ! -z "$INSTALL_PATH" ]; then
  echo "$white"copying files to install path"$cdef"
  rm -rf "$INSTALL_PATH"
  [ ! -d "$INSTALL_PATH" ] && mkdir "$INSTALL_PATH"
  for f in ./src/*.sh
  do
    cp -Rf "$BUILD_PATH"/. "$INSTALL_PATH"/
  done
fi | sed "2,$ s/^/  /"

# creating a release commit with for the current build
if [ -v RELEASE_MSG ]; then
  echo "$white"creating a release commit with for the current build"$cdef"
  prev_branch=$(git symbolic-ref HEAD)
  __git symbolic-ref HEAD refs/heads/release
  __git reset
  __git checkout HEAD -- .gitignore
  __git add ./build
  __git commit -m "$RELEASE_MSG"
  __git symbolic-ref HEAD "$prev_branch"
  __git checkout HEAD -- .gitignore
  __git reset
fi | sed "2,$ s/^/  /"
