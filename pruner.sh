#!/usr/bin/bash
function Pruner {
    echo 'Hello' $1 There are "$#" arguments
    echo "ONE  $1  TWO $2 THREE $3"
    if [ "$#" -eq 1 ]; then
        echo "I saw $# argument."
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


Pruner "$@"
