#!/bin/bash
dkgray=[90m;red=[91m;green=[92m;yellow=[93m;blue=[94m;magenta=[95m
cyan=[96m;white=[97m;black=[30m;dkred=[31m;dkgreen=[32m;dkyellow=[33m
dkblue=[34m;dkmagenta=[35m;dkcyan=[36m;gray=[37m;cdef=[0m

_FNAME="$1"
shift
_EXEC=""
_CMD=""
while [[ $# -gt 0 ]]
do
  [ ! -z "$_EXEC" ] && _EXEC="$_EXEC " || _CMD=$(printf '%q' "$1")
  _EXEC=$_EXEC$(printf '%q' "$1")
  shift
done

_FNAME_0="${_FNAME:0:1}"
if [ "$_FNAME_0" = "/" ]; then
  _FNAME=$(echo "$_FNAME" | sed -r "s ^/(.*)/$ \1 ")
else
  _FNAME=$(echo "$_FNAME" | sed -r "s \*\..*$ \0$ ;s \. \\\\. ;s \* .* ;s \? . ")
fi

if which "$_CMD" >/dev/null 2>&1; then
  (git filter-branch -f --index-filter $'
      git clean -d -x -f
      echo ""
      git ls-files -s | sed "s .*\\t\\"*  " | grep "'$_FNAME$'" | while read line; do
        echo '$yellow$'"\t$line"'$cdef$'
        git checkout -- "$line"
        '$_EXEC$' "./$line"
      done
      git add . --ignore-removal
  ') || exit

  #https://stackoverflow.com/questions/7654822/remove-refs-original-heads-master-from-git-repo-after-filter-branch-tree-filte
  (git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d) || exit
  (git gc --aggressive --prune=now) || exit
else
  echo $red"$_CMD was not found"$cdef
fi
