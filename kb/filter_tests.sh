src_dir=""
#src_dir="a/b b"
dst_dir="d"
_has_filter=0

function get_filtered_files_for_commit {
  echo "a/b b/my file"
  echo "n.txt"
  echo "b/other"
}

# ref: https://stackoverflow.com/a/10433783/195417
contains_element () { for e in "${@:2}"; do [[ "$e" = "$1" ]] && return 0; done; return 1; }

function filter_ls_files {
  if [ "$_has_filter" == 1 ]; then
    readarray -t __files <<<"$(get_filtered_files_for_commit $GIT_COMMIT)"
  fi
  git ls-files --stage | (
    while read mode sha stage path
    do
      # ref: https://git-scm.com/docs/git-update-index#_using_index_info
      # TODO: use printf or echo to output a line for each file
      # - to remove a file write:
      #     0 0000000000000000000000000000000000000000	file_name
      # - to move a file write:
      #     $mode $sha $stage	new_file_name
      # if $1 contains "-r" reverse the logic, remove selected files, and keed unselected files
      # if $1 contains "-m" move files from src_dir to dst_dir (hint: use sed to replace, if pattern not found, remove file)

      # ref: https://stackoverflow.com/questions/56700325/xor-conditional-in-bash
      ! [ "$1" == "-r" ]; TEST_REMOVE=$?

      # see: /kb/path_pattern.sh
      if [ ! -z "$src_dir" ] && [[ ! "${path}" =~ ^(\")?"$src_dir"(\"|/|$) ]]; then
        TEST_SELECTED=0
      elif [ "$_has_filter" == "1" ]; then
        _path="${path/#\"/}"
        _path="${_path/%\"/}"
        ! contains_element "$_path" "${__files[@]}"; TEST_SELECTED=$?
      else
        TEST_SELECTED=1
      fi

      if [ $TEST_REMOVE -ne $TEST_SELECTED ]; then
        if [ "$1" == "-m" ]; then
          # see: /kb/path_pattern.sh
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
      fi
    done
  )
}

git () {
    if [ "$1" == "ls-files" ] && [ "$2" == "--stage" ]; then
        echo  "100644 49b6862d23caefc6182a1f178daf7fed2846dd19 0	a/some.txt"
        echo  '100644 88f27799e84f2dd61218feace1b07529ca0c9f4a 0	"a/b b/my file"'
        echo  '100644 e69de29bb2d1d6434b88feace1b07529ca0c9f4a 0	"a/b b/c c/other"'
        echo  "100644 0ae6e38ff526cdabc0058da1e12d778457d08f7f 0	n.txt"
        echo  "100644 d6bc6a4f48f6dfbe1ae23adb9722782ef74008a5 0	b/other"
        echo  '100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	"with spaces"'
    fi
}

filter_ls_files -r
echo ""
filter_ls_files -m
