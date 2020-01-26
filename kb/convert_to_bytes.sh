function convert_to_bytes {
  __sz="$1"
  if ! [[ "$__sz" =~ ^[0-9]+([KMGTEkmgte])?([Bb])?$ ]]; then return 1; fi
  __un=$(echo $__sz | sed -r 's ^[0-9]+([KMGTE])?B?$ \1 gI')
  __sz=$(echo $__sz | sed -r 's ^([0-9]+)[KMGTE]?B?$ \1 gI')
  if   [ "${__un^^}" = "K" ]; then let "__sz=$__sz*1024";
  elif [ "${__un^^}" = "M" ]; then let "__sz=$__sz*1024000";
  elif [ "${__un^^}" = "G" ]; then let "__sz=$__sz*1024000000";
  elif [ "${__un^^}" = "T" ]; then let "__sz=$__sz*1024000000000";
  elif [ "${__un^^}" = "E" ]; then let "__sz=$__sz*1024000000000000";
  fi
  echo "$__sz"
  return 0
}
convert_to_bytes "$1"