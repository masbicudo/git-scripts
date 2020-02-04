#!/bin/bash
# ref: https://stackoverflow.com/a/10433783/195417
contains_element () { for e in "${@:2}"; do [[ "$e" = "$1" ]] && return 0; done; return 1; }

function my_command {
    echo -e 'x\ny'
    echo "miguel angelo"
    echo -e "[x\ty]"
}

readarray -t my_array <<<"$(my_command)"
echo "${my_array[0]}"
echo "${my_array[1]}"
echo "${my_array[2]}"
echo "${my_array[3]}"

__tab=`echo -e "\t"`
contains_element "miguel angelo" "${my_array[@]}" && echo 1 || echo 0
contains_element "miguel" "${my_array[@]}" && echo 1 || echo 0
contains_element "angelo" "${my_array[@]}" && echo 1 || echo 0
contains_element "[x""$__tab""y]" "${my_array[@]}" && echo 1 || echo 0
