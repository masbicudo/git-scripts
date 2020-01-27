src_dir="a b/n.n"
src_dir=""
dst_dir="x"
dst_dir=""
echo 's|("?)'"${src_dir/\./\\.}"'(/\|$)|\1'"$dst_dir"'\2|g'

path='"a b/n.n/k.txt"'
[ ! -z "$src_dir" ] && [[ ! "${path}" =~ ^(\")?"$src_dir"(\"|/|$) ]] && echo [fail] || echo [ ok ]
if [ "$src_dir" != "$dst_dir" ]; then
    if [ -z "$src_dir" ]
    then path=`sed -E 's|^("?)|\1'"$dst_dir"'/|g' <<< "$path"`
    elif [ -z "$dst_dir" ]
    then path=`sed -E 's|^("?)'"${src_dir/\./\\.}"'(/\|("\|$))|\1\3|g' <<< "$path"`
    else path=`sed -E 's|^("?)'"${src_dir/\./\\.}"'(/\|"\|$)|\1'"$dst_dir"'\2|g' <<< "$path"`
    fi
fi

echo "$path"

