#!/bin/bash
# ref: https://github.com/kynan/nbstripout#apply-retroactively
function echo_nbso {
  # ref: https://stackoverflow.com/questions/525872/echo-tab-characters-in-bash-script
  # ref: https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
  for fn in "$@"
  do echo "[93m""${fn##\.\/}""[0m"
  done
  nbstripout "$@"
}
declare -fx echo_nbso
function stripout_commit {
  echo "[91m"
  git clean -fxd
  echo -n "[0m"
  git checkout -- :*.ipynb
  # ref: https://stackoverflow.com/questions/4321456/find-exec-a-shell-function-in-linux
  # ref: http://mywiki.wooledge.org/WordSplitting
  # ref: https://stackoverflow.com/questions/6085156/using-semicolon-vs-plus-with-exec-in-find
  # NOTE: For some reason, the first argument in the
  #   list is not being passed to "echo_nbso" function.
  #   The parameter "x" bellow is just there to have
  #   an additional argument that will be ignored.
  find . -name "*.ipynb" -exec bash -c 'echo_nbso "$@"' x "{}" +
  git add . --ignore-removal
}
declare -fx stripout_commit
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
git filter-branch -f --index-filter 'stripout_commit | indent_prepend'
