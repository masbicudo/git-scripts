#!/bin/bash
ver=v0.3.5
ZIP=NO
COPY=NO
DEL=NO
SIMULATE=NO
HELP=NO
NOINFO=NO
function quote_arg {
if [[ $# -eq 0 ]]; then return 1; fi
if [[ ! "$1" =~ [[:blank:]] ]] && [ "${1//
/}" == "$1" ] && [ ! -z "$1" ]
then echo "${1//\'/\"\'\"}"; 
else echo "'${1//\'/\'\"\'\"\'}'"
fi
return 0
}
all_args=
if [ "$*" == "" ]; then
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
--min-size)           F_MIN_SIZE="$2" ;all_args="$all_args $(quote_arg "$2")";shift;;
--max-size)           F_MAX_SIZE="$2" ;all_args="$all_args $(quote_arg "$2")";shift;;
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
dkgray=[90m;red=[91m;green=[92m;yellow=[93m;blue=[94m;magenta=[95m
cyan=[96m;white=[97m;black=[30m;dkred=[31m;dkgreen=[32m;dkyellow=[33m
dkblue=[34m;dkmagenta=[35m;dkcyan=[36m;gray=[37m;cdef=[0m
if [ "$NOINFO" == "NO" ]; then
echo -e "$blue""git-hist-mv ""$dkyellow""$ver""$cdef"
echo $dkgray$0$all_args$cdef
fi
cl_op=$blue
cl_colons=$dkgray
if [ "$HELP" == "YES" ]; then
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
  echo "  "$yellow"--file-name "$cl_op"or "$yellow"--fn"$cl_colons":" $white"filter by filename"
  echo "  "$yellow"--dir"$cl_colons":" $white"filter by dirname"
  echo "  "$yellow"--path "$cl_op"or "$yellow"--p"$cl_colons":" $white"filter by path (directory and file name)"
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
  echo "  "$yellow"--min-size"$cl_colons":" $white"filter by minimum file size"
  echo "  "$yellow"--max-size"$cl_colons":" $white"filter by maximum file size"
  echo "    "$dkgreen"Note"$cl_colons": "$cdef
  echo "      "When filtering by file size, you can append units to the number:
  echo "        "e.g. "100MB"
  echo "        "e.g. "1k"
  echo "      "It is case insensitive, and ignores the final "'B'" or "'b'" if present.
  exit 0
fi
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
if [ "$_not" == "0" ] && [ "${_fname:0:1}" = "!" ]; then
_not="1"
_fname="${_fname:1}"
fi
if [ "$_opt" != "r" ]; then
if [ "${_fname:0:1}" = "=" ]; then
_single="1"
_fname="${_fname:1}"
fi
fi
if [ "$_single" == "1" ] && [ -z "$_opt" ]; then
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
if [ "$_single" == "0" ]; then
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
if [ "$SIMULATE" == "YES" ]
then
echo $blue"git"$yellow"$_all_args"$cdef
else
if [ "$NOINFO" == "NO" ]; then
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
echo $branch
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
declare -x src_dir
declare -x dst_dir
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
if [ -v F_PATH ]; then
echo -e "$cl_name"F_PATH"\e[0m"="$cl_value""$F_PATH\e[0m"
echo -e "$cl_name"F_PATH_NOT"\e[0m"="$cl_value""$F_PATH_NOT\e[0m"
echo -e "$cl_name"F_PATH_CI"\e[0m"="$cl_value""$F_PATH_CI\e[0m"
fi
if [ -v F_DIR ]; then
echo -e "$cl_name"F_DIR"\e[0m"="$cl_value""$F_DIR\e[0m"
echo -e "$cl_name"F_DIR_NOT"\e[0m"="$cl_value""$F_DIR_NOT\e[0m"
echo -e "$cl_name"F_DIR_CI"\e[0m"="$cl_value""$F_DIR_CI\e[0m"
fi
if [ -v F_FNAME ]; then
echo -e "$cl_name"F_FNAME"\e[0m"="$cl_value""$F_FNAME\e[0m"
echo -e "$cl_name"F_FNAME_NOT"\e[0m"="$cl_value""$F_FNAME_NOT\e[0m"
echo -e "$cl_name"F_FNAME_CI"\e[0m"="$cl_value""$F_FNAME_CI\e[0m"
fi
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
function is_file_selected {
local _path="${1/#\"/}"
_path="${_path/%\"/}"
if [ -v F_PATH ]; then
local _fpath="$_path"
local _ci=""
if [ "$F_PATH_CI" == "1" ]; then _ci="I"; fi
if [ "$_fpath" = "." ]; then _fpath=""; fi
echo "$_fpath" | sed -r "/$F_PATH/$_ci!{q100}" &>/dev/null
[ $? -eq 100 ]
if [ "$?" = "$F_PATH_NOT" ]; then return 1; fi
fi
if [ -v F_DIR ]; then
local directory=$(dirname "$_path")
local _ci=""
if [ "$F_DIR_CI" == "1" ]; then _ci="I"; fi
if [ "$directory" = "." ]; then directory=""; fi
echo "$directory" | sed -r "/$F_DIR/$_ci!{q100}" &>/dev/null
[ $? -eq 100 ]
if [ "$?" = "$F_DIR_NOT" ]; then return 1; fi
fi
if [ -v F_FNAME ]; then
local fname=$(basename "$_path")
local _ci=""
if [ "$F_FNAME_CI" == "1" ]; then _ci="I"; fi
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
function contains_element { for e in "${@:2}"; do [[ "$e" = "$1" ]] && return 0; done; return 1; }
declare -fx contains_element
function filter_ls_files {
__rm_files=()
while read mode sha stage path
do
! [ "$1" == "-r" ]; TEST_REMOVE=$?
if [ ! -z "$src_dir" ] && [[ ! "${path}" =~ ^(\")?"$src_dir"(\"|/|$) ]]; then
TEST_SELECTED="0"
elif [ "$_has_filter" == "1" ]; then
! is_file_selected "$path"
TEST_SELECTED=$?
else
TEST_SELECTED="1"
fi
if [ $TEST_REMOVE -ne $TEST_SELECTED ]; then
if [ "$1" == "-m" ]; then
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
else
__rm_files+=("$path")
fi
done <<< "$(git ls-files --stage)"
if [ ${#__rm_files[@]} -gt 0 ]; then
git rm --cached --ignore-unmatch -r -f -- "${__rm_files[@]}" > /dev/null 2>&1
fi
}
declare -fx filter_ls_files
if [ "$DEL" == "NO" ]; then
__git branch _temp $src_branch
fi
if [ "$COPY" == "NO" ]; then
if [ "$_has_filter" == 1 ]; then
__git filter-branch -f --prune-empty --tag-name-filter cat --index-filter 'filter_ls_files -r' -- "$src_branch"
elif [ -z "$src_dir" ]; then
__git branch -D $src_branch
ZIP=
else
__git filter-branch -f --prune-empty --tag-name-filter cat --index-filter '
git rm --cached --ignore-unmatch -r -f '"'""${src_dir//\'/\'\"\'\"\'}""'"'
' -- "$src_branch"
fi
__git update-ref -d refs/original/refs/heads/"$src_branch"
fi
if [ "$DEL" == "YES" ]; then
exit 0
fi
if [ -z "$dst_dir" ] && [ "$_has_filter" == "0" ]; then
if [ ! -z "$src_dir" ]; then
__git filter-branch --prune-empty --tag-name-filter cat --subdirectory-filter "$src_dir" -- _temp
__git update-ref -d refs/original/refs/heads/_temp
fi
else
function filter_to_move {
local _PATHS=`filter_ls_files -m`
if [ -z "$_PATHS" ]; then return; fi
echo -n "$_PATHS" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --remove --index-info
if [ -e "$GIT_INDEX_FILE.new" ]; then mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"; fi
}
declare -fx filter_to_move
__git filter-branch -f --prune-empty --tag-name-filter cat --index-filter 'filter_to_move' -- _temp
fi
__git update-ref -d refs/original/refs/heads/_temp
declare commit1=0 datetime1=0 commit2=0 datetime2=0
if [ "$SIMULATE" == "NO" ]; then
{ read commit1 datetime1 ; } <<< "$(git log --reverse --max-parents=0 --format="%H %at" "$dst_branch" | head -1)"
{ read commit2 datetime2 ; } <<< "$(git log --reverse --max-parents=0 --format="%H %at" _temp | head -1)"
fi
declare rebase_hash="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
if [ "$datetime1" -gt 0 ] && [ "$datetime2" -gt 0 ]; then
if [ "$datetime1" -gt "$datetime2" ]; then
rebase_hash=`git log --before $datetime1 --format="%H" -n 1 _temp`
else
rebase_hash=`git log --before $datetime2 --format="%H" -n 1 $dst_branch`
fi
fi
if __git checkout "$dst_branch" 2>/dev/null
then
declare _cur_branch=
_cur_branch=`git branch --show-current`
echo Current branch is: $_cur_branch
__git merge --allow-unrelated-histories --no-edit -s recursive -X no-renames -X theirs --no-commit _temp;
__git commit -m "Merge branch '$src_branch' into '$dst_branch'"
else
__git branch "$dst_branch" _temp
__git checkout "$dst_branch"
fi
if [ "$ZIP" == "YES" ]; then
__git -c rebase.autoSquash=false rebase --autostash "$rebase_hash"
elif [ "$ZIP" == "NO" ]; then
echo -e "\e[94mTo zip the timelines you can run a git rebase on"
echo -e "the commit \e[93m$rebase_hash\e[0m"
echo -e "e.g. \e[97mgit -c rebase.autoSquash=false rebase --autostash "$rebase_hash"\e[0m"
fi
__git branch -D _temp
