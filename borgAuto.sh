#!/usr/bin/bash
# 8 Sept 2019 SJ Pratt
# Copied from https://blog.andrewkeech.com/posts/170718_borg.html
# the envvar $REPONAME is something you should just hardcode
# export BORG_REPO="/mnt/bak/borg"  # (now set in ~/.bashrc)

# Route logging to journalctl
2>&1

MAXFILES=20     #Max number of file changes to log
MOUNTPOINT=/mnt/bak

# noauto = don't mount backup disk at boot
# user = allow user to mount the disk
# line from /etc/fstab:
# UUID=XXXX 	/mnt/bak	btrfs		defaults,noauto,user			0 0

# Try to mount the backup disk
mountpoint -q ${MOUNTPOINT}
mpExit=$?
if [ $mpExit -eq 32 ]; then
	echo "Mounting backup disk to ${MOUNTPOINT}."
	mount -v ${MOUNTPOINT}
    mountpoint -q ${MOUNTPOINT}
    mpExit=$?
    if [ $mpExit -ne 0 ] ; then
      echo "Failed to mount backup disk (mountpoint returned $mpExit)-- exiting"
	  exit 1
    fi
fi



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
    changes="Changed $changeFiles, Added ${addFiles}, Removed ${remFiles}"
    if [ ${totFiles} -eq 0 ]; then
        changes="No changes, additions or deletions since last backup"
        echo ${changes}
    elif [ ${totFiles} -gt ${MAXFILES} ]; then     # Lots of changes
        #echo $(head ${diffTmpFile})
        head ${diffTmpFile}
        
        midFiles=$(awk -v tot=$totFiles -v max=$MAXFILES 'BEGIN {print tot - max}')
        echo "   ... ${midFiles} more changes (${changes})"
        tail ${diffTmpFile}
    else                        # A 'small' number of changes
        echo ${totFiles} files changed:
        cat ${diffTmpFile}
    fi    
    rm ${diffTmpFile}
    notify "${changes}"
}

# Pruning must be performed on named repos, otherwise just the last one
#  from a period (day/week/etc) is kept.
function Pruner {
    # todo : replace --dry-run with --stats (they can't both be used)
    if [ $# -eq 1 ]; then
        borg prune                  \
            --prefix $1             \
            --list                  \
            --stats               \
            --keep-within   3d      \
            --keep-daily    14      \
            --keep-weekly   8       \
            --keep-monthly  12      \
            --keep-yearly   -1      \
            ::    
    else
      echo Pruner went wrong. Call it with just one prefix.
    fi
}

## Add some eye candy
function notify {
    if [ $# -gt 0 ]; then
        msg="${@}"      # Treat whatever was passed in as one string
    else
        msg="No message"
    fi
    # note the double quoted var to keep it as one argument
    notify-send 'borgAuto' "${msg}" --icon=dialog-information
}

#---------------------------------------------------------------------------


# Backup all of /home except a few excluded directories and files
echo $'\n'"Creating ${USER}'s archive"
borg create -v --stats  --compression auto,lzma,6    \
   ::'{hostname}-{user}-{now:%Y%m%dT%H%M}' \
   /home/${USER}  \
   /var/log/pacman.log \
   /etc/fstab          \
   /etc/systemd/system \
    --exclude '/home/st33v/cargo'   \
    --exclude '/home/st33v/.*' \
    --exclude '*.vdi'               \
    --exclude '*.img'               \
    --exclude '*.iso'               \
    --exclude '.git/'

Differ cr4y

# Backup olho (Image store)
# don't compress image files; they are already compressed
# TODO but what about RAW image files (*.NEF etc)
echo $'\nCreating Image archive'
borg create -v --stats --compression none   \
    ::'olho-{now:%Y%m%dT%H%M}' /mnt/olho

Differ olho

backup_exit=$?
 
# Prune the repo of extra backups
echo $'\nPruning repository'
Pruner cr4y
Pruner olho

prune_exit=$?
 
# Include the remaining device capacity in the log
diskSpaceFree=$(df -hl | grep --color=never /mnt/bak)
echo "${diskSpaceFree}"
notify "${diskSpaceFree}"

# borg list :: --format {name:40}{start}{NL} --sort-by name,timestamp 

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
    exitmsg="Backup and Prune finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    exitmsg="Backup ($backup_exit) and/or Prune ($prune_exit) finished with warnings"
else
    exitmsg="Backup ($backup_exit) and/or Prune ($prune_exit) finished with errors"
fi

umount -v ${MOUNTPOINT}
echo "${exitmsg}"
notify "${exitmsg}"
exit ${global_exit}
