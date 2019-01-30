#!/bin/bash
#
# get System status 
# of several Baltos / NUC devices in parallel.
# central script runs on mobilevpn.eu
#
# PREPARATION: register ssh keys for automated login:
#  you@host to mobilevpn       and 
#  you@mobilevpn to iplon@targetdevice 
# http://askubuntu.com/questions/46424/adding-ssh-keys-to-authorized-keys
#
# failure detection (error.log):
#      - DEVS(device identifier) not found in proxy.list
#      - failure 2: mobilevpn to iGate: Connection refused (old iGate)
#      - failure 2: mobilevpn: device offline: Connection timed out
#
SRV=mobilevpn.eu
SCR="./getMotd.sh"
OUTDIR="./"
ERRFILE=error.log
DEVSFILE="$HOME/.getDeviceStatus.deviceIDs"
DEVS=()
SSHPORT=22 # ssh port 22 or 2018
USAGE="
====================================
$0 USAGE:
====================================
                 gets devices Status from default devices 
 -g {devID, ..}  gets devices Status only from stated devices 
                 Note: a device can only reply, if 
                 - it is accessible from mobilevpn.eu by ssh key without password
                 - it must have received an \"update\" (-u option) at least once.
 -h              prints help message and exits.
 -a {devID, ..}  appends [{devID}s] to default devices list 
                 and install updates on devices. 
 -d {devID, ..}  deletes [{devID}s] from default devices list
 -u              updates script files on mobilevpn and default devices 
 -l              lists installed Device IDs and exits.
----------------
     {devID}     a string that identifies an iGate / Baltos in proxy.list.
                 example: 2140010,   where
                         214     = Portal-ID
                            0010 = iGateID, 4-digits
                 must consist of exactly 7 digits
====================================
requirements: 
------------------------------------
Uses ssh-keys without password-protection 
for authentication to mobilevpn and to each device. 
====================================
"
APPENDS=()
DELETES=()
GETS=()
UPDATEDO=0
LISTONLY=0
HELPONLY=0
AISSET=0
DISSET=0
GETDO=0
C=("$@")
while getopts "ulhg:a:d:" opt; do
  # note: getopts can't handle more than one argument to an option. 
  # Therefore, I added an inner loop ("while true; ... ; done" )
  #            processing additional arguments.
  while true; do
    case "${opt}" in
      a) [[ $OPTARG =~ [0-9]{7} ]] && APPENDS+=("$OPTARG") && AISSET=1 ;; # only if 7-digit-string
      d) [[ $OPTARG =~ [0-9]{7} ]] && DELETES+=("$OPTARG") && DISSET=1 ;; # only if 7-digit-string
      u) UPDATEDO=1;;
      l) LISTONLY=1;;
      g) [[ $OPTARG =~ [0-9]{7} ]] && GETS+=("$OPTARG")    && GETDO=1  ;; # only if 7-digit-string
      h) HELPONLY=1 ;;
     \?) echo "unknown option. Exit now. For help, type \"$0 -h\"" ; exit 1 ;;
    esac
    let "nextOPTIND=OPTIND + 1"
    let "OPTINDm1=OPTIND - 1"
    nextOPTARG="${C[$OPTINDm1]}"
    if [[ $nextOPTARG =~ -.* || -z $nextOPTARG ]] 
    then
        break
    else
        OPTIND="$nextOPTIND"
        OPTARG="$nextOPTARG"
    fi
  done    
done
unset C nextOPTIND OPTINDm1
set --

function varDef() {
    # return a shell command line that defines a variable
    # arg0:     variable name
    # arg1:     variable value
    echo $1=\""$2"\"
}

read -d '' SCR1 <<"EOF1"
#!/bin/bash
# by Versl
# changes will be overwritten 
# 
# execute on mobilevpn.eu
#
# ssh log in to several Baltos 
# and return a status overview (motd-like).
#
IPv4PAT="10.[[:digit:]]{1,3}.[[:digit:]]{1,3}.[[:digit:]]{1,3}";
PRLIST="proxy.list"
SCRM="./motd.sh" # path on target device
EOF1
defERR=$(varDef ERRFILE $ERRFILE)
defSHP=$(varDef SSHPORT $SSHPORT)
read -d '' SCR3 <<"EOF3"
USAGE="$0 ====================================
USAGE:
====================================
 -h              prints help message and exits.
 -g [devID, ..]  gets device status of devices in DEVS
 -u [devID, ..]  updates script files on devices
====================================
# TODO failure:
#      - any Cmdline option can take only ONE argument!!
#        this is due to bash builtin optargs limitation
$0 This script is maintained and executed by Versl's host script"
GETDEVS=()
UPDATES=()
HELPONLY=0

C=("$@")
while getopts "g:u:h" opt; do
  # note: getopts can't handle more than one argument to an option. 
  # Therefore, I added an inner loop ("while true; ... ; done" )
  #            processing additional arguments.
  while true; do
    case $opt in
      g) [[ $OPTARG =~ [0-9]{7} ]] && GETDEVS+=("$OPTARG");; # only if 7-digit-string 
      u) [[ $OPTARG =~ [0-9]{7} ]] && UPDATES+=("$OPTARG");; # only if 7-digit-string
      h) HELPONLY=1 ;;
     \?) echo "unknown option. Exit now. For help, type \"$0 -h\"" ; exit 1 ;;
    esac
    let "nextOPTIND=OPTIND + 1"
    let "OPTINDm1=OPTIND - 1"
    nextOPTARG="${C[$OPTINDm1]}"
    if [[ $nextOPTARG =~ -.* || -z $nextOPTARG ]] 
    then
        break
    else
        OPTIND="$nextOPTIND"
        OPTARG="$nextOPTARG"
    fi
  done
done
unset C
set --

read -d '' SCR4 <<"EOF4"
#!/bin/sh 
# by Versl 
# changes will be overwritten 
# 
# arg1: device identifier
# generates a status overview ("motd")
#
if [ -z $1 ] ; then set missingIdentifier ; fi
motd() {
    # arg1:  device identifier
    echo "$1 +++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "$1 +++++++++++ $(date --rfc-3339=seconds) +++++++++++"
    echo "$1 +++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "$1 + Hostname = $(hostname)"
    echo "$1 + Uptime =$(uptime)"
    echo "$1 + Memory = $(exec 3< /proc/meminfo && awk '/MemFree|MemTotal/ {ORS=" ";print $1 $2" "$3";"}' <&3 ; exec 3<&-)"
    echo "$1 + disk   = $(df -h | sort -grk 5 | head -n1 | awk '{ print "" $1": free:"$4" used:"$5 }')"
    echo "$1 + HW; SW = $( if [ -r /etc/iplonHW ] ; then cat /etc/iplonHW ; fi ); $(if [ -x /opt/iplon/scripts/sq ] ; then /opt/iplon/scripts/sq unit version ; fi )"
}
motd $1
EOF4
function pexec() {
    # arg 1    ERRWORD
    # arg 2..x COMMAND
    #
    # execute command (eval "$@"),
    # prepend stderr-message with ERRWORD
    # return exit status of COMMAND
    # suppress typical ssh info messages which are no failures.
    local ERRWORD="$1 "
    shift
    exec 3>&1
    eval "$*" 2>&1 1>&3 | grep -vE 'Warning|Debian Image|^$' |  sed s/^/"$ERRWORD"/g
    return ${PIPESTATUS[0]} # exit code of eval
}
function waitUntilFinished() {
    # arg1:  message
    # ${PIDS[@]}:   process IDs to wait for
    # wait until all background processes are finished.
    # if any background process have failed, then echo failure message
    local msg="$1"
    local FAIL=0
    for job in "${PIDS[@]}"
    do
        wait $job || let "FAIL++"
    done
    if [ "$FAIL" -gt 0 ]; then
        echo "$ERRFILE $FAIL $msg"
    fi
}
TM=$(date --rfc-3339=seconds)
# ##### DO IT (Helpmessage) | update, get status ##############
if [ $HELPONLY = 1 ]; then
    echo -e "$USAGE"
    exit 0
fi
# ####### update script files on devices ######################
PIDS=()
for arg in "${UPDATES[@]}"
do
    ####### prepare to connect: get IP from proxy.list #######
    IP=$( grep -s $arg $PRLIST | tail -n1 | grep -oE $IPv4PAT )
    if [ -z "$IP" ]; then
        # if $IP is empty, return a error line
        echo "$ERRFILE $TM $arg not found in $PRLIST."
    else
        ####### ssh update script on device #######################
        echo -e "$SCR4" | ssh iplon@$IP -p $SSHPORT "cat - > $SCRM && chmod a+x $SCRM" &
        PIDS+=($!)
    fi
done
waitUntilFinished "devices could not be updated."
# #############################################################

# ####### get status from devices #############################
for arg in "${GETDEVS[@]}"
do
    ####### prepare to connect: get IP from proxy.list #######
    IP=$( grep -s $arg $PRLIST | tail -n1 | grep -oE $IPv4PAT )
    if [ -z "$IP" ]; then
        # if $IP is empty, return a error line
        echo "$ERRFILE $TM "$arg" not found in $PRLIST.";
    else
        ####### ssh get motd from device ######################
        pexec "$ERRFILE $arg $TM" ssh iplon@$IP -p $SSHPORT $SCRM $arg &
    fi
done
# TODO waitall until all ready ?? Problem: wait blocks while receiving notifications
# waitUntilFinished "devices failed to return status."
# #############################################################
EOF3

function desktopnotify() {
    # open a popup message
    # arg1: count of errors
    # on Ubuntu, only one message at a time will be displayed,
    # so open only one summary message for any error occured 
    notify-send "Baltos error" "$1 failures. See $OUTDIR$ERRFILE"
}

function processReply(){
    # get replies, loop for each line
    # $a if error: "error.log";       else: device identifier
    # $b if error: device identifier; else: next word of message
    # $c message
    #
    local errct=0
    while read -r a b c
    do
        echo "$a: $b $c"   # to stdout
        echo "$b $c" >> "$OUTDIR$a" # to device history file OR error.log
        if [[ $a == $ERRFILE ]]; then
            let "errct++"
            echo "$a $c" >> "$OUTDIR$b" # error to device history
        fi
    done
    if [ $errct -gt 0 ] ; then
        desktopnotify $errct
    fi
}

# ##### DO IT ###############################################
# depending on options, do following, in this order:
# -h    print $USAGE and exit
# -l    list DEVS and exit
# -d {} delete devs from DEVS list (leave scripts on these devices) 
# -a {} append to devs to DEVS list and install scripts on these devices
# -u    install / update scripts on all devices
# [-g]  get device status from DEVS. 
# ###########################################################
function readDEVS(){
    # cat $DEVSFILE  at once
    # split words into $DEVS array
    DEVS=()
    R=$(cat "$DEVSFILE")
    while read; do 
        # append word by word
        DEVS+=("$REPLY")     
    done < <(printf "%s\n" "$R")
}
# ##### -h help #############################################
if [ $HELPONLY = 1 ] ; then
    echo -e "$USAGE"
    exit 0
fi
# ##### -l listonly #########################################
if [ $LISTONLY = 1 ] ; then
    cat $DEVSFILE
    exit 0
fi
# ##### -d DELETE ###########################################
if [ $DISSET = 1 ]; then
    readDEVS                                  # read DEVS from file
    for del in "${DELETES[@]}" ; do           # DELETE each IN DEVS  
      DEVS=("${DEVS[@]/$del}")
    done
    printf "%s\n" "${DEVS[@]}" > "$DEVSFILE"  # write to file
    echo "deleted items successfully"
fi
# ##### -a append ###########################################
if [ $AISSET = 1 ] ; then
    readDEVS                                  # read DEVS from file
    for app in "${APPENDS[@]}" ; do
        DEVS=("${DEVS[@]/$app}")              # delete; omit duplicates
        DEVS+=($app)                          # append
    done
    printf "%s\n" "${DEVS[@]}" > "$DEVSFILE"  # write to file
    echo  "appended to default devices list and ... "
fi
# ##### -u update ###########################################
if [[ $UPDATEDO = 1 || $AISSET = 1 ]] ; then
    if [ $UPDATEDO = 1 ] ; then
        readDEVS                              # read DEVS from file
    else
        :                                     # keep DEVS from ${APPENDS[@]}
    fi
    echo -e "$SCR1\n$defERR\n$defSHP\n$SCR3" | ssh $SRV "cat - > $SCR && chmod ug+x $SCR && $SCR -u ${DEVS[@]}" | processReply
    echo "updated successfully"
fi
# #####    get status #######################################
if [[ $AISSET = 0 && $DISSET = 0 && $UPDATEDO = 0 || $GETDO = 1 ]] ; then
    if [ "${#GETS[@]}" -gt 0 ] ; then
        DEVS=("${GETS[@]}")
    else
        readDEVS                                # read DEVS from file
    fi
    echo $SRV "$SCR -g ${DEVS[@]}"
    ssh $SRV "$SCR -g ${DEVS[@]}" | processReply
fi
# ###########################################################


