#!/bin/bash
dkgray=[90m;red=[91m;green=[92m;yellow=[93m;blue=[94m;magenta=[95m
cyan=[96m;white=[97m;black=[30m;dkred=[31m;dkgreen=[32m;dkyellow=[33m
dkblue=[34m;dkmagenta=[35m;dkcyan=[36m;gray=[37m;cdef=[0m

mkdir build
for f in ./src/*.sh
do
  # ref: http://www.nongnu.org/bibledit/sed_rules_reference.html#addressesandrangesoftext
  sed -r '
  /#BEGIN_DEBUG/,/#END_DEBUG/d;
  /#BEGIN_AS_IS/,/#END_AS_IS/!{
    2,${/^ *debug/d};
    2,${/^ *#.*$/d};
    /^ *$/d;
    s/^ *//
  };
  2,${/^ *#(BEGIN|END)_AS_IS\b.*$/d
  }' "$f" > "./build/$(basename "$f")"
done
