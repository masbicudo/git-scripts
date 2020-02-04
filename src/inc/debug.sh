function debug { echo "[92m$@[0m"; }
declare -fx debug
function debug_file { touch "/tmp/__debug.git-hist-mv.txt"; echo "$@" >> "/tmp/__debug.git-hist-mv.txt"; }
declare -fx debug_file
