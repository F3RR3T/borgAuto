#!/usr/bin/bash
# 8 Sept 2019 SJ Pratt
# Copied from https://blog.andrewkeech.com/posts/170718_borg.html
# the envvar $REPONAME is something you should just hardcode
 export BORG_REPO="/mnt/bak/borg"  # (now set in ~/.bashrc)

MAXFILES=20     #Max number of file changes to log

# Route the normal process logging to journalctl
2>&1

# DIFF function
# List changes between this archive and the previous one
function Differ {
    newArchive=$(borg list :: -P $1 --last 2 --format {name}{NL})
    diffTmpFile=`mktemp /tmp/borgAutoXXXXX`        #  in /tmp dir
    borg diff ::$newArchive > $diffTmpFile
    addFiles=$(grep  '^added' ${diffTmpFile}   | wc -l)
    remFiles=$(grep  '^removed' ${diffTmpFile} | wc -l)
    totFiles=$(wc -l ${diffTmpFile} | awk '{print $1}')
    changeFiles=$(awk -v tot=$totFiles -v a=$addFiles -v r=$remFiles 'BEGIN {print tot - a - r}')
    if [ ${totFiles} -eq 0 ]; then
        echo "No changes, additions or deletions since last backup"
    elif [ ${totFiles} -gt ${MAXFILES} ]; then
        #echo $(head ${diffTmpFile})
        head ${diffTmpFile}
        
        midFiles=$(awk -v tot=$totFiles -v max=$MAXFILES 'BEGIN {print tot - max}')
        echo "   ... ${midFiles} more changes (Changed $changeFiles, Added ${addFiles}, Removed ${remFiles})"
        tail ${diffTmpFile}
    else
        cat ${diffTmpFile}
    fi    
    rm ${diffTmpFile}
}

# Backup all of /home except a few excluded directories and files
echo $'\nCreating St33v\'s archive'
borg create -v --stats  --compression auto,lzma,6    \
   ::'{hostname}-{user}-{now:%Y%m%dT%H%M}' \
   /home/st33v  \
   /var/log/pacman.log \
   /etc/systemd/system \
    --exclude '/home/st33v/.cache'      \
    --exclude '/home/st33v/.local'      \
    --exclude '/home/$USER/cargo'   \
    --exclude '/home/st33v/.dropbox' \
    --exclude '/home/st33v/.dropbox-dist' \
    --exclude '/home/st33v/.config' \
    --exclude '/home/st33v/.mozilla' \
    --exclude '/home/st33v/.*' \
    --exclude '*.img'               \
    --exclude '*.iso'             

Differ cr4y

# Backup olho
echo $'\nCreating Image archive'
borg create -v --stats --compression none   \
    ::'olho-{now:%Y%m%dT%H%M}' /mnt/olho

Differ olho

backup_exit=$?
 
# Prune the repo of extra backups
echo $'\nPruning repository'
borg prune --stats          \
    --list                  \
    --keep-within   3d      \
    --keep-daily    14      \
    --keep-weekly   8       \
    --keep-monthly  12      \
    --keep-yearly   -1      \
    ::    
prune_exit=$?
 
# Include the remaining device capacity in the log
echo $(df -hl | grep --color=never /mnt/bak)
 
# borg list :: --format {name:40}{start}{NL} --sort-by name,timestamp 

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
    echo "Backup and Prune finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    echo "Backup ($backup_exit) and/or Prune ($prune_exit) finished with warnings"
else
    echo "Backup ($backup_exit) and/or Prune ($prune_exit) finished with errors"
fi
exit ${global_exit}
