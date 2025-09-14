#!/bin/bash

mydir="$(dirname "$(realpath "$BASH_SOURCE")")"
exdir="$HOME/.password-store/.extensions"

mkdir -p "$exdir"

for srcpath in "$mydir"/*.bash
do
    fname="$(basename $srcpath)"
    tgtpath="$exdir/$fname"
    if [ ! -f "$tgtpath" ] ; then
        cp "$srcpath" "$tgtpath"
        continue
    fi
    if ! diff -u $srcpath $tgtpath  ; then
        if [ "$1" = "force" ] ; then
            cp "$srcpath" "$tgtpath"
        fi
    fi

done
