#!/usr/bin/bash
function Pruner {
    echo 'Hello' $1 There are $# arguments
    if [ $# -eq 1 ]; then
        borg prune                  \
            --prefix $1             \
            --list                  \
            --dry-run               \
            --keep-within   1d      \
            --keep-daily    2      \
            --keep-weekly   8       \
            --keep-monthly  12      \
            --keep-yearly   -1      \
            ::    
    else
      #  sds
      echo Pruner went wrong.
    fi
}


Pruner $1
