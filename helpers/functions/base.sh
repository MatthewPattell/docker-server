#!/usr/bin/env bash

# Get absolute path from the relative
realpath() {
    [[ $1 == /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

# Get index element in array if exist or return -1
indexOf() {
    element=$1 && shift
    array=($@)
    index=$(echo ${array[@]/$element//} | cut -d/ -f1 | wc -w | tr -d ' ')
    lastIndex=$(($(echo ${#array[@]}) - 1))

    if (($index > $lastIndex)); then
        echo -1
    else
        echo $index
    fi
}
