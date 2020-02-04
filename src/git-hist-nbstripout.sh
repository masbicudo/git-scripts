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
git filter-branch -f --index-filter 'stripout_commit | sed "s/^/\t/"'
