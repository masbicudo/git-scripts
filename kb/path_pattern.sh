src_dir="a b/n.n"
dst_dir="x"
echo 's|("?)'"${src_dir/\./\\.}"'(/\|$)|\1'"$dst_dir"'\2|g'

path='"a b/n.n/k.txt"'
[[ ! "$path" =~ ^(\")?"$src_dir"(\"|/|$) ]] && echo [fail] || echo [ ok ]
path=`sed -E 's|^("?)'"${src_dir/\./\\.}"'(/\|"\|$)|\1'"$dst_dir"'\2|g' <<< "$path"`

echo "$path"

