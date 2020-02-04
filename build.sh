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
    --install|-i)         INSTALL_PATH="$2" ;shift;;
    --path|-p)            BUILD_PATH="$2"   ;shift;;
    --save|-s)
      SAVE_SETTINGS="1"
      if [ ! -z "$2" ] && ! [[ "$2" =~ ^- ]]; then SAVE_PATH="$2"; shift;
      else SAVE_PATH="settings.txt"; fi
      ;;
    --load|-l)
      LOAD_SETTINGS="1"
      if [ ! -z "$2" ] && ! [[ "$2" =~ ^- ]]; then LOAD_PATH="$2"; shift;
      else LOAD_PATH="settings.txt"; fi
      ;;
    *)
    ((argc=argc+1))
    eval "arg_$argc='${i//\'/\'\"\'\"\'}'"
    ;;
  esac
  shift
done

if [ -v SAVE_SETTINGS ] && [ -v LOAD_SETTINGS ]; then
  >&2 echo -e "\e[91m""Invalid usage, cannot load and save at the same time""\e[0m"
  exit 1
fi

if [ ! -v has_args ] && [ -f "settings.txt" ]; then
  LOAD_PATH="settings.txt"
fi

if [ ! -z "$SAVE_PATH" ]; then
  truncate -s 0 "$SAVE_PATH"
  if [ -v BUILD_PATH ]; then echo "BUILD_PATH=$BUILD_PATH" >> "$SAVE_PATH" ; fi
  if [ -v INSTALL_PATH ]; then echo "INSTALL_PATH=$INSTALL_PATH" >> "$SAVE_PATH" ; fi
fi
if [ ! -z "$LOAD_PATH" ]; then
  # ref: https://www.cyberciti.biz/faq/unix-howto-read-line-by-line-from-file/
  while IFS=" " read -r var_name var_value
  do
    [ ! -v "$var_name" ] && declare "$var_name"="$var_value"
  done <<< "$(sed -r '
    /^(BUILD_PATH|INSTALL_PATH)=(.*)$/!d;
    s/=/ /;
    ' "$LOAD_PATH")"
fi

if [ ! -v BUILD_PATH ]; then BUILD_PATH="build"; fi

print_var () { local cl_name="\e[38;5;146m" cl_value="\e[38;5;186m"; [ -v $1 ] && echo -e "$cl_name"$1"\e[0m"="$cl_value"${!1}"\e[0m"; }
print_var SAVE_PATH
print_var LOAD_PATH
print_var BUILD_PATH
print_var INSTALL_PATH

[ ! -d "$BUILD_PATH" ] && mkdir "$BUILD_PATH"
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
    s/^ *//
  };
  2,${/^ *#(BEGIN|END)_AS_IS\b.*$/d
  }' "$f" > "$_file"
done

if [ ! -z "$INSTALL_PATH" ]; then
  rm -rf "$INSTALL_PATH"
  [ ! -d "$INSTALL_PATH" ] && mkdir "$INSTALL_PATH"
  for f in ./src/*.sh
  do
    cp -Rf "$BUILD_PATH"/. "$INSTALL_PATH"/
  done
fi
