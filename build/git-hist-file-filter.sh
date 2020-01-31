#!/bin/bash
_SIZE=0
dkgray=[90m;red=[91m;green=[92m;yellow=[93m;blue=[94m;magenta=[95m
cyan=[96m;white=[97m;black=[30m;dkred=[31m;dkgreen=[32m;dkyellow=[33m
dkblue=[34m;dkmagenta=[35m;dkcyan=[36m;gray=[37m;cdef=[0m
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
-sl|--single-line) _SL=TRUE;;
-fn|--file-name)   _FNAME=$2;  shift;;
-d|--dir)          _DIR=$2;    shift;;
-sz|--size)        _SIZE=$2;   shift;;
*)                                  ;;
esac
shift
done
if [[ "$_SIZE" =~ ^[0-9]+[KMGTEkmgte][Bb]$ ]]; then
LETTER=$(echo $_SIZE | sed -r 's ^[0-9]+([KMGTE])B$ \1 gI')
_SIZE=$(echo $_SIZE | sed -r 's ^([0-9]+)[KMGTE]B$ \1 gI')
if [ ${LETTER^^} = "K" ]; then let "_SIZE=$_SIZE*1024"; fi
if [ ${LETTER^^} = "M" ]; then let "_SIZE=$_SIZE*1024000"; fi
if [ ${LETTER^^} = "G" ]; then let "_SIZE=$_SIZE*1024000000"; fi
if [ ${LETTER^^} = "T" ]; then let "_SIZE=$_SIZE*1024000000000"; fi
if [ ${LETTER^^} = "E" ]; then let "_SIZE=$_SIZE*1024000000000000"; fi
fi
_FNAME_0="${_FNAME:0:1}"
if [ "$_FNAME_0" = "/" ]; then
_FNAME=$(echo "$_FNAME" | sed -r "s ^/(.*)/$ \1 ")
else
_FNAME=$(echo "$_FNAME" | sed -r "s \*\..*$ \0$ ;s \. \\\\. ;s \* .* ;s \? . ")
fi
if [ ! -z "$_DIR" ]; then
_DIR=$(echo $_DIR|sed -r 's\\/|/(^|$|\\/)g')
fi
function get_filtered_files_for_commit {
commithash="$1"
git diff-tree -r --name-only --diff-filter=AMT $commithash |
tail -n +2 | (_iter=0; while read path; do
directory=$(dirname "$path")
if [ "$directory" = "." ]; then directory=""; fi
if [ ! -z "$_DIR" ]; then
echo "$directory" | sed -r "/$_DIR/I!{q100}" &>/dev/null
retVal=$?
if [ $retVal -eq 100 ]; then
continue
fi
fi
fname=$(basename "$path")
if [ ! -z "$_FNAME" ]; then
echo "$fname" | sed -r "/$_FNAME/I!{q100}" &>/dev/null
retVal=$?
if [ $retVal -eq 100 ]; then
continue
fi
fi
objsize=$(git cat-file -s "$commithash:$path")
[ $objsize -lt $_SIZE ] && continue
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
git log --pretty="%H %aI %s" --topo-order | while read -r commithash date message; do
get_filtered_files_for_commit $commithash
done
