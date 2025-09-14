#!/bin/bash

# Access non-password data in an entry.
# This assumes the following lines are of the form:
#
# <key>: <value>
#
# The <key> may have spaces and spaces around the ":" are allowed/optional.
#
# One or more keys can be queried with -k|--key options and the key may be
# literal or a regular expression.
#
# Note, output (without -s|--strip) is essentially YAML.  One can form JSON
# with, eg,
#
# pass data -k key path/to/entry | yq
#
# However, while this script allows repeated keys, YAML does not.


MYTEMP=$(getopt --options 'sk:' --longoptions 'strip,key:' -- "$@")
if [ $? -ne 0 ] ; then
    die "pass data [-s|--strip] [-k|key key ...] path"
fi

eval set -- "$MYTEMP"

declare -a keys
keys=()
strip="no"

while true; do
    case "$1" in
        # remove the matched key prefix, default shows lines as-is
        '-s'|'--strip') strip="yes"; shift ;;

        '-k'|'--key') keys+=( "$2" ) ; shift 2 ;;

        '--') shift; break ;;

        *) die 'Internal error'; exit 1 ;;
    esac
done



# Usage: <input> | get_entries "key1" "key with space" ...
get_entries() {
  awk '
    BEGIN {
      for (i = 1; i < ARGC; i++) keys[ARGV[i]] = 1
      ARGC = 1
    }
    
    # If line starts with non-space, it might be a new key.
    # We must decide if we should be printing or not.
    /^[^[:space:]]/ {
      p = 0 # Default to not printing
      for (k in keys) {
        if ($0 ~ ("^" k "[[:space:]]*:")) {
          p = 1 # It is a key we want, so set print flag
          break
        }
      }
    }
    
    # If the print flag is set (either from this line or a
    # previous key line), print the current line.
    p
  ' "$@"
}
# Usage: <input> | get_values "key1" "key with space" ...
get_values() {
  awk '
    BEGIN {
      for (i = 1; i < ARGC; i++) keys[ARGV[i]] = 1
      ARGC = 1
    }
    
    # Handle potential new key lines
    /^[^[:space:]]/ {
      in_value = 0 # End any previous value block
      for (k in keys) {
        if ($0 ~ ("^" k "[[:space:]]*:")) {
          in_value = 1 # Start a new value block
          sub("^" k "[[:space:]]*:[[:space:]]?", "")
          if (length($0)) print
          break
        }
      }
      # We have fully processed this line, so skip to the next
      next
    }
    
    # This rule only applies to continuation lines (starting with a space).
    # If we are in a value block, strip leading space and print.
    in_value {
      sub(/^[[:space:]]+/, "")
      print
    }
  ' "$@"
}


dispatch () {
    if [ "$strip" = "yes" ] ; then
        get_values "${keys[@]}"
    else
        get_entries "${keys[@]}"
    fi
}

pass "$@" | tail -n +2 | dispatch


