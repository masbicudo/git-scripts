#!/bin/bash
# ref: https://github.com/kynan/nbstripout#apply-retroactively
function echo_nbso {
  # ref: https://stackoverflow.com/questions/525872/echo-tab-characters-in-bash-script
  # ref: https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
  for fn in "$@"
  do echo -e "[93m\t""$fn""[0m"
  done
  nbstripout "$@"
}
declare -fx echo_nbso
function stripout_commit {
  echo ""
  git checkout -- :*.ipynb
  # ref: https://stackoverflow.com/questions/4321456/find-exec-a-shell-function-in-linux
  # ref: http://mywiki.wooledge.org/WordSplitting
  # ref: https://stackoverflow.com/questions/6085156/using-semicolon-vs-plus-with-exec-in-find
  find . -name "*.ipynb" -exec bash -c 'echo_nbso "$@"' "{}" +
  git add . --ignore-removal
}
declare -fx stripout_commit
git filter-branch -f --index-filter 'stripout_commit'
