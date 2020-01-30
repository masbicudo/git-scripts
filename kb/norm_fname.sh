#!/bin/bash
# ref: https://askubuntu.com/questions/889744/what-is-the-purpose-of-shopt-s-extglob
# ref: https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
# ref: https://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html#Pattern-Matching
# = !=
# r !r r!
# e !e e! e= !e= e!=
# b !b b! b= !b= b!=
# c !c c! c= !c= c!=
# x !x x! x= !x= x!=
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
    if [ -z "$_not" ] && [ "${_fname:0:1}" = "!" ]; then
      _not="1"
      _fname="${_fname:1}"
    fi
    if [ "$_opt" != "r" ]; then
      if [ "${_fname:0:1}" = "=" ]; then
        _single="1"
        _fname="${_fname:1}"
      fi
    fi
    if [ ! -z "$_single" ] && [ -z "$_opt" ]; then
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
      if [ -z "$_single" ]; then
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
_icase=xpto
# proc_f_fname "$1"
read N_FNAME I_FNAME F_FNAME <<< "$(proc_f_fname "$1")"
echo "F_FNAME='${F_FNAME/\'/\'\"\'\"\'}'"
echo "N_FNAME='$N_FNAME'"
echo "I_FNAME='$I_FNAME'"

sed -r "s/$F_FNAME/  \1/g" <<< "a.jpg"
sed -r "s/$F_FNAME/  \1/g" <<< "b.txt"
sed -r "s/$F_FNAME/  \1/g" <<< "c/q.jpg"
sed -r "s/$F_FNAME/  \1/g" <<< "a/a.png"
sed -r "s/$F_FNAME/  \1/g" <<< "a\\a.png"
sed -r "s/$F_FNAME/  \1/g" <<< "f"
sed -r "s/$F_FNAME/  \1/g" <<< "(1)x.txt"
sed -r "s/$F_FNAME/  \1/g" <<< "[2]x.txt"
