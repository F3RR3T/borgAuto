#!/usr/bin/bash
# 8 Sept 2019 SJ Pratt
# Copied from https://blog.andrewkeech.com/posts/170718_borg.html
# the envvar $REPONAME is something you should just hardcode
export REPOSITORY="/mnt/bak/st33vHome" 

# Fill in your password here, borg picks it up automatically
#export BORG_PASSPHRASE="" 

# Backup all of /home except a few excluded directories and files
borg create -v --stats -e none --compression lz4                 \
    $REPOSITORY::'{hostname}-{now:%Y-%m-%dT%H:%M}' /home/st33v \
--exclude '/home/*/.cache'                               \
--exclude '/home/$USER/cargo'                        \
--exclude '/home/lost+found'                             \
--exclude '*.img'                                        \
--exclude '*.iso'                                        \

# Route the normal process logging to journalctl
2>&1

 
# Prune the repo of extra backups
borg prune -v $REPOSITORY --prefix '{hostname}-'         \
    --keep-hourly=6                                      \
    --keep-daily=7                                       \
    --keep-weekly=4                                      \
    --keep-monthly=6                                     \
 
# Include the remaining device capacity in the log
df -hl | grep --color=never /mnt/bak
 
borg list $REPOSITORY
 
exit 0
