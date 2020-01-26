function quote_arg {
  if [[ $# -eq 0 ]]; then return 1; fi
  # if argument 1 contains:
  # - spaces or tabs
  # - new lines
  # - is empty
  # then: needs to be quoted
  if [[ ! "$1" =~ [[:blank:]] ]] && [ "${1//
/}" == "$1" ] && [ ! -z "$1" ]
  then echo "${1//\'/\"\'\"}"; 
  else echo "'${1//\'/\'\"\'\"\'}'"
  fi
  return 0
}
__tab="$(echo -e "\t")"
echo "arg_1=$(quote_arg xpto)"
echo "arg_2=$(quote_arg '')"
echo "arg_3=$(quote_arg)"
echo "arg_4=$(quote_arg "miguel angelo")"
echo "arg_5=$(quote_arg "a""$__tab""b")"
echo "arg_6=$(quote_arg 'a
b')"
