#!/bin/bash

mydir="$(dirname "$(realpath "$BASH_SOURCE")")"
exdir="$HOME/.password-store/.extensions"

for srcpath in "$mydir"/*.bash
do
    fname="$(basename $srcpath)"
    tgtpath="$exdir/$fname"
    if [ ! -f "$tgtpath" ] ; then
        cp "$srcpath" "$tgtpath"
        continue
    fi
    diff $srcpath $tgtpath

done
