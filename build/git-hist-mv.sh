#!/bin/bash
ver=v0.3.6"[0m ([32mrefs/heads/master[0m)"
ZIP=NO
COPY=NO
DEL=NO
SIMULATE=NO
HELP=NO
NOINFO=NO
dkgray=[90m;red=[91m;green=[92m;yellow=[93m;blue=[94m;magenta=[95m
cyan=[96m;white=[97m;black=[30m;dkred=[31m;dkgreen=[32m;dkyellow=[33m
dkblue=[34m;dkmagenta=[35m;dkcyan=[36m;gray=[37m;cdef=[0m
if [ "${SHELL%%/bin/bash}" = "$SHELL" ]; then
>&2 echo $red"Only bash is supported at the moment, current is $SHELL"$cdef
exit 11
fi
if [[ "$OSTYPE" == "linux-gnu" ]]; then os_not_supported=1
elif [[ "$OSTYPE" == "darwin"* ]]; then os_not_supported=1
elif [[ "$OSTYPE" == "cygwin" ]]; then os_not_supported=1
elif [[ "$OSTYPE" == "msys" ]]; then os_not_supported=0
elif [[ "$OSTYPE" == "win32" ]]; then os_not_supported=1
elif [[ "$OSTYPE" == "freebsd"* ]]; then os_not_supported=1
else os_not_supported=1
fi
if [ "$os_not_supported" = "1" ]; then
>&2 echo $red"Only msys is supported at the moment, current is $OSTYPE"$cdef
exit 11
fi
function quote_arg {
if [[ $# -eq 0 ]]; then return 1; fi
if [[ ! "$1" =~ [[:blank:]] ]] && [ "${1//
/}" = "$1" ] && [ ! -z "$1" ]
then echo "${1//\'/\"\'\"}"; 
else echo "'${1//\'/\'\"\'\"\'}'"
fi
return 0
}
all_args=
if [ "$*" = "" ]; then
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
if [ "$NOINFO" = "NO" ]; then
echo -e "$blue""git-hist-mv ""$dkyellow""$ver""$cdef"
echo $dkgray$0$all_args$cdef
fi
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
if [ -v __error ]; then exit 11; fi
function convert_to_bytes {
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
if [ -v F_FNAME ]; then read -r F_FNAME_NOT F_FNAME_CI F_FNAME <<< "$(proc_f_fname "$F_FNAME")"; fi
if [ -v F_DIR ]; then read -r F_DIR_NOT F_DIR_CI F_DIR <<< "$(proc_f_fname "$F_DIR")"; fi
if [ -v F_PATH ]; then read -r F_PATH_NOT F_PATH_CI F_PATH <<< "$(proc_f_fname "$F_PATH")"; fi
if [ -v F_MIN_SIZE ]; then F_MIN_SIZE="$(convert_to_bytes "$F_MIN_SIZE")"; fi
if [ -v F_MAX_SIZE ]; then F_MAX_SIZE="$(convert_to_bytes "$F_MAX_SIZE")"; fi
declare -x F_FNAME_NOT F_FNAME_CI F_FNAME
declare -x F_DIR_NOT F_DIR_CI F_DIR
declare -x F_PATH_NOT F_PATH_CI F_PATH
declare -x F_MIN_SIZE F_MAX_SIZE
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
unset -v src_branch src_dir
{ IFS= read -r src_branch && IFS= read -r src_dir; } <<< `get_branch_and_dir "$arg_1"`
unset -v dst_branch dst_dir
{ IFS= read -r dst_branch && IFS= read -r dst_dir; } <<< `get_branch_and_dir "$arg_2"`
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
>&2 echo -e "\e[91m""Invalid usage, must specify 2 or 4 ordinal params""\e[0m"
exit 1
else
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
local _path="${1/#\"/}"
_path="${_path/%\"/}"
if [ -v F_PATH ]; then
local _fpath="$_path"
local _ci=""
if [ "$F_PATH_CI" = "1" ]; then _ci="I"; fi
if [ "$_fpath" = "." ]; then _fpath=""; fi
echo "$_fpath" | sed -r "/$F_PATH/$_ci!{q100}" &>/dev/null
[ $? -eq 100 ]
if [ "$?" = "$F_PATH_NOT" ]; then return 1; fi
fi
if [ -v F_DIR ]; then
local directory=$(dirname "$_path")
local _ci=""
if [ "$F_DIR_CI" = "1" ]; then _ci="I"; fi
if [ "$directory" = "." ]; then directory=""; fi
echo "$directory" | sed -r "/$F_DIR/$_ci!{q100}" &>/dev/null
[ $? -eq 100 ]
if [ "$?" = "$F_DIR_NOT" ]; then return 1; fi
fi
if [ -v F_FNAME ]; then
local fname=$(basename "$_path")
local _ci=""
if [ "$F_FNAME_CI" = "1" ]; then _ci="I"; fi
echo "$fname" | sed -r "/$F_FNAME/$_ci!{q100}" &>/dev/null
[ $? -eq 100 ]
if [ "$?" = "$F_FNAME_NOT" ]; then return 1; fi
fi
if [ -v F_MIN_SIZE ] || [ -v F_MAX_SIZE ]; then
local objsize=$(git cat-file -s "$GIT_COMMIT:$_path")
if [ -v F_MIN_SIZE ] && [ $objsize -lt $F_MIN_SIZE ]; then return 1; fi
if [ -v F_MAX_SIZE ] && [ $objsize -gt $F_MAX_SIZE ]; then return 1; fi
fi
return 0
}
declare -fx is_file_selected
function filter_ls_files {
__rm_files=()
while read mode sha stage path
do
! [ "$1" = "-r" ]; TEST_REMOVE=$?
if [ ! -z "$src_dir" ] && [[ ! "${path}" =~ ^(\")?"$src_dir"(\"|/|$) ]]; then
TEST_SELECTED="0"
elif [ "$_has_filter" = "1" ]; then
! is_file_selected "$path"
TEST_SELECTED=$?
else
TEST_SELECTED="1"
fi
if [ $TEST_REMOVE -ne $TEST_SELECTED ]; then
if [ "$1" = "-m" ] || [ "$1" = "-s" ]; then
if [ "$src_dir" != "$dst_dir" ]; then
if [ -z "$src_dir" ]
then path=`sed -E 's|^("?)|\1'"$dst_dir"'/|g' <<< "$path"`
elif [ -z "$dst_dir" ]
then path=`sed -E 's|^("?)'"${src_dir/\./\\.}"'(/\|("\|$))|\1\3|g' <<< "$path"`
else path=`sed -E 's|^("?)'"${src_dir/\./\\.}"'(/\|"\|$)|\1'"$dst_dir"'\2|g' <<< "$path"`
fi
fi
fi
printf "$mode $sha $stage\t$path\n"
elif [ "$1" != "-s" ]; then
__rm_files+=("$path")
else
printf "$mode $sha $stage\t$path\n"
fi
done <<< "$(git ls-files --stage)"
if [ ${#__rm_files[@]} -gt 0 ]; then
git rm --cached --ignore-unmatch -r -f -- "${__rm_files[@]}" > /dev/null 2>&1
fi
}
declare -fx filter_ls_files
function index_filter {
local _PATHS=`filter_ls_files $1`
if [ -z "$_PATHS" ]; then return; fi
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
if [ "$DEL" = "NO" ]; then
if [ "$src_branch" != "$dst_branch" ] || [ "$COPY" = "YES" ]; then
NEW_UUID="$(cat /dev/urandom | tr -dc '0-9A-F' | fold -w 32 | head -n 1)"
tmp_branch="_temp_$NEW_UUID"
__git branch $tmp_branch $src_branch
fi
fi
if [ "$COPY" = "NO" ]; then
if [ "$DEL" = "NO" ] && [ "$src_branch" = "$dst_branch" ]; then
__git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
index_filter -s | indent_prepend
' -- "$src_branch"
elif [ "$_has_filter" = 1 ]; then
__git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
index_filter -r | indent_prepend
' -- "$src_branch"
elif [ -z "$src_dir" ]; then
__git branch -D "$src_branch"
ZIP=
if [ "$dst_branch" = "$src_branch" ]; then unset -v dst_branch_existed; fi
else
__git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
git rm --cached --ignore-unmatch -r -f '"'""${src_dir//\'/\'\"\'\"\'}""'"' | indent_prepend
' -- "$src_branch"
fi
__git update-ref -d refs/original/refs/heads/"$src_branch"
fi
if [ ! -v tmp_branch ]; then
exit 0
fi
if [ -z "$dst_dir" ] && [ "$_has_filter" = "0" ]; then
if [ ! -z "$src_dir" ]; then
__git filter-branch --prune-empty --tag-name-filter cat --subdirectory-filter "$src_dir" -- "$tmp_branch"
__git update-ref -d refs/original/refs/heads/"$tmp_branch"
fi
else
declare -fx filter_to_move
__git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
index_filter -m | indent_prepend
' -- "$tmp_branch"
fi
__git update-ref -d refs/original/refs/heads/"$tmp_branch"
unset -v rebase_hash
if [ -v dst_branch_existed ]; then
declare commit1=0 datetime1=0 commit2=0 datetime2=0
if [ "$SIMULATE" = "NO" ]; then
{ read commit1 datetime1 ; } <<< "$(git log --reverse --max-parents=0 --format="%H %at" "$dst_branch" | head -1)"
{ read commit2 datetime2 ; } <<< "$(git log --reverse --max-parents=0 --format="%H %at" "$tmp_branch" | head -1)"
fi
rebase_hash="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
if [ "$datetime1" -gt 0 ] && [ "$datetime2" -gt 0 ]; then
if [ "$datetime1" -gt "$datetime2" ]; then
rebase_hash=`git log --before $datetime1 --format="%H" -n 1 "$tmp_branch"`
else
rebase_hash=`git log --before $datetime2 --format="%H" -n 1 "$dst_branch"`
fi
fi
fi
if [ -v dst_branch_existed ]
then
__git checkout "$dst_branch"
declare _cur_branch=
_cur_branch=`git branch --show-current`
echo Current branch is: $_cur_branch
__git merge --allow-unrelated-histories --no-edit -s recursive -X no-renames -X theirs --no-commit "$tmp_branch";
__git commit -m "Merge branch '$src_branch' into '$dst_branch'"
else
if ! __git branch "$dst_branch" "$tmp_branch"
then
exit 1
fi
__git checkout "$dst_branch"
fi
if [ -v rebase_hash ]; then
if [ "$ZIP" = "YES" ]; then
__git -c rebase.autoSquash=false rebase --autostash "$rebase_hash"
elif [ "$ZIP" = "NO" ]; then
echo -e "\e[94mTo zip the timelines you can run a git rebase on"
echo -e "the commit \e[93m$rebase_hash\e[0m"
echo -e "e.g. \e[97mgit -c rebase.autoSquash=false rebase --autostash "$rebase_hash"\e[0m"
fi
fi
__git branch -D "$tmp_branch"
