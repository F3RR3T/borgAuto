function notify {
      if [ $# -gt 0 ]; then
         msg="$@"
      else
         msg="No message"
      fi  
     # msg=test message no quotes
      notify-send 'borgAuto' "${msg}" --icon=dialog-information
      echo $#  " ${@}"
}

echo "Testing notify"
notify "$@"
notify 'here is my message'
notify

