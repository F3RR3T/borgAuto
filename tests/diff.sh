
function Differ {
    MAXFILES=20
    newArchive=$(borg list :: -P $1 --last 2 --format {name}{NL})
    diffTmpFile=`mktemp /tmp/borgAutoXXXXX`        #  in /tmp dir
    borg diff ::$newArchive > $diffTmpFile
    echo newArchive:  $newArchive
    echo $(wc $diffTmpFile)
    addFiles=$(grep  '^added' ${diffTmpFile}   | wc -l)
    echo $addFiles
    remFiles=$(grep  '^removed' ${diffTmpFile} | wc -l)
    echo $remFiles
    totFiles=$(wc -l ${diffTmpFile} | awk '{print $1}')
    echo $totFiles
    echo $totFiles $addFiles $remFiles
    if [ ${totFiles} -eq 0 ]; then
        echo "No additions or deletions since last backup"
    elif [ ${totFiles} -gt ${MAXFILES} ]; then
        #echo $(head ${diffTmpFile})
        head ${diffTmpFile}
        
        midFiles=$(awk -v tot=$totFiles -v max=$MAXFILES 'BEGIN {print tot - max}')
        echo "   ... ${midFiles} more files changed (Added ${addFiles}, Removed ${remFiles})"
        tail ${diffTmpFile}
    else
        cat ${diffTmpFile}

    fi    
    rm ${diffTmpFile}
}

Differ $1
