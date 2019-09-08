#!/usr/bin/env bash
# Copied from https://blog.andrewkeech.com/posts/170718_borg.html
# the envvar $REPONAME is something you should just hardcode
export REPOSITORY="/media/$USER/$REPONAME/borg/" 

# Fill in your password here, borg picks it up automatically
export BORG_PASSPHRASE="" 

# Backup all of /home except a few excluded directories and files
borg create -v --stats --compression lz4                 \
    $REPOSITORY::'{hostname}-{now:%Y-%m-%d %H:%M}' /home \
--exclude '/home/*/.cache'                               \
--exclude '/home/*/.ccache'                              \
--exclude '/home/$USER/.local/include'                   \
--exclude '/home/$USER/.local/installppa.sh'             \
--exclude '/home/$USER/.local/listppa'                   \
--exclude '/home/$USER/Downloads'                        \
--exclude '/home/$USER/VirtualBox\ VMs'                  \
--exclude '/home/$USER/lxd-zfs.img'                      \
--exclude '/home/lost+found'                             \
--exclude '*.img'                                        \
--exclude '*.iso'                                        \

# Route the normal process logging to journalctl
2>&1

# If there is an error backing up, reset password envvar and exit
if [ "$?" = "1" ] ; then
    export BORG_PASSPHRASE=""
    exit 1
fi
 
# Prune the repo of extra backups
borg prune -v $REPOSITORY --prefix '{hostname}-'         \
    --keep-hourly=6                                      \
    --keep-daily=7                                       \
    --keep-weekly=4                                      \
    --keep-monthly=6                                     \
 
# Include the remaining device capacity in the log
df -hl | grep --color=never /dev/sdc
 
borg list $REPOSITORY
 
# Unset the password
export BORG_PASSPHRASE=""
exit 0
