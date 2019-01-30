#!/bin/bash
source ./ip-address-functions.sh

### config ###########################################
MY_IF=eth1 # may be empty
SUBNETS=(192.168.253.0/24 192.168.70.0/24)
subnet_test=192.168.253.0/24 # TODO replace with SUBNETS
LISTFILES=(network-ips-192.168.253.txt network-ips-192.168.70.txt)
lfile_test=recent.txt # TODO replace with LISTFILES
IP_RESERV_DURATION=(10 1) # [days] Reservation duration of IP address within each SUBNET (days)
keep_days_test=7 # TODO preliminary version; replace with array 
LINE_FMT="%16s   %17s   %10s   %s\n"
NETSCAN_FILE=now_list_test.txt # temp file: network scan resulting file
BY="Versl"
ADMIN="Vogel"

function send_msg(){
  ### Args ################################################################
  declare level=$1   # Arg 1:   level
  declare msg="$2"   # Arg 2:   message text
  #########################################################################
  printf '\nlevel:%s  msg:%s \ngenerator:%s  By:%s Admin:%s\n' $level "$msg" "$0" "$BY" "$ADMIN"


  # TODO ............... send email ........................
}

function split_line(){
  ### Args ################################################################
  declare return_varname=$1  # Arg 1:    name of array variable to return (global; indirection)
  shift
  declare line="$@"          # Args: line of text; examples:
	#  192.168.253.91  00:17:c8:11:af:6c    01    060   Kyocera Mita Corporation"
	#  192.168.253.91  00:17:c8:11:af:6c    2017-11-24    060   Kyocera Mita Corporation"
	#  192.168.253.91  00:17:c8:11:af:6c    1511343427    060   Kyocera Mita Corporation"
  #########################################################################
	# split line of netdiscover output into array: (IP) (MAC) (rest of line)
  #       insert date, if not present
  #########################################################################
	[[ "$line"  =~ ^[[:space:]]*([[:graph:]]*)[[:space:]]*([[:graph:]]*)[[:space:]]*([[:graph:]]*)(.*)$ ]]
	ip="${BASH_REMATCH[1]}"
	mac="${BASH_REMATCH[2]}"
  dat="${BASH_REMATCH[3]}"
  rest="${BASH_REMATCH[4]}"
  if [[ "$dat" =~ ^[[:digit:]][[:digit:]][[:digit:]][[:digit:]]\-[[:digit:]-]*$ ]] # 2017-1-02
  then
  	:
  else
    dat=$(date -I)
  fi
  eval "$return_varname=(\$ip \$mac \$dat \"\$rest\")"
}


# netdiscover example command
## sudo netdiscover -i eth1 -P -r 192.168.253.0/24


function nowlist_create_file(){
  ### Args #############################################################
  src_file=${1:?$FUNCNAME[0] missing Argument}   # Arg 1: file path
  ######################################################################
  # netdiscover example output line
  ##  192.168.253.91  00:17:c8:11:af:6c    01    060   Kyocera Mita Corporation
  # TODO: save output in src_file 
}

function nowlist_prepare_from_file(){
  ### Args ##############################################################
  declare return_varname=$1   # Arg 1:    name of array variable to return 
                              #           (global; indirection)
  declare src_file="$2"       # Arg 2:    source file (raw created nowlist)
  declare snm=${3:-0.0.0.0/0} # Arg 3:    subnet with mask: drops IPs not in;
                              #           default mask 0.0.0.0/0: keep all
  #### process lines of netdiscover output ##############################
  # each line: split into array
  # each line: IP into decimal representation
  # all lines: sort lines
  #######################################################################
  declare -a lines_to_sort=()
  while IFS='' read -r line  ; do
    declare -a line_arr  # (IP) (MAC) (rest of line)
    split_line "line_arr" "$line"
    if [ ${#line_arr[@]} -ge 3 ] ; then
      if [ 0 == $(ip_in_subnet ${line_arr[0]} $snm) ]; then
        line_arr[0]=$(ipstring_to_ipdecimal ${line_arr[0]})
        lines_to_sort[${#lines_to_sort[@]}]=$(printf "$LINE_FMT" "${line_arr[@]}")  # assign = instead of +=
      fi    
    fi
  done < "$src_file"
  ### sort array of lines ###############################################
  declare -a ndlines=()
  set -o noglob
  IFS=$'\n' ndlines=($(sort <<<"${lines_to_sort[*]}"))
  unset IFS
  set +o noglob
  # printf '%s\n' "${ndlines[@]}" # debug
  ### return array as named global variable #############################
  eval "$return_varname=(\"\${ndlines[@]}\")"
}

function recentlist_prepare_from_file(){
  ### Args ################################################################
  declare return_varname=$1  # Arg 1:    name of array variable to return (global; indirection)
  declare src_file="$2"      # Arg 2:    path to recent list file (IP's from recent script run)                                  
  #### process lines of RECENT netdiscover output #########################
  # each line: split into array
  # each line: IP into decimal representation
  declare -a ndlines=()
  while IFS='' read -r line  ; do
    declare -a line_arr 
    split_line "line_arr" "$line"  # line: split into array  (IP) (MAC) (rest of line)
    if [ ${#line_arr[@]} -ge 3 ] ; then
      if [ 0 == $(ip_in_subnet ${line_arr[0]} 192.168.253.0/24) ]; then
        line_arr[0]=$(ipstring_to_ipdecimal ${line_arr[0]})
        ndlines[${#ndlines[@]}]=$(printf "$LINE_FMT" "${line_arr[@]}") 
      fi    
    fi
  done < "$src_file"
  # printf '%s\n' "${ndlines[@]}" # print array line by line # debug
  ### return array as named global variable ###############################
  eval "$return_varname=(\"\${ndlines[@]}\")"
}


function recentlist_drop_too_old_ips(){
  ### Args ################################################################
  declare return_varname=$1  # Arg 1:    name of array variable to return (global; indirection)
  shift
  declare -i kdays=$1        # Arg 2:    duration to keep IPs [days]
  shift
  declare rllines=("$@")     # Arg 3..x: lines
  #########################################################################
  declare -a rllines_checked=()
  for thisline in "${rllines[@]}"; do
    split_line lineparts "${thisline}"
    tsnow=$(date -u +%s)
    tsrecent=$( date -ud ${lineparts[2]} +%s )
    line_is_valid=$(( tsrecent + (kdays+1)*86400 >= tsnow )) #  RESERVED, not older than .. days
    # echo ${lineparts[0]} ${lineparts[1]} tsnow:$tsnow tsrecent:$tsrecent valid:$line_is_valid # debug
    if [ $line_is_valid -ne 0 ] ; then 
      rllines_checked[${#rllines_checked[@]}]="$thisline"
    fi
  done
  ### return array as named global variable ###############################
  eval "$return_varname=(\"\${rllines_checked[@]}\")"
}

function nowlist_check_dup_ips(){
  ### Args ################################################################
  declare return_varname=$1  # Arg 1:    name of array variable to return (global; indirection)
  shift
  declare rllines=("$@")     # Arg 2..x: lines
  #########################################################################
  declare -a rllines_checked=()
  ipprev=0
  # for i in $(seq 0 $(( ${#rllines[@]}-1 )) ); do
  for i in ${!rllines[@]}; do # indices of ${rllines[@]}
    split_line lineparts "${rllines[$i]}"
    if [[ $ipprev == ${lineparts[0]} ]] ; then
      # duplicate ip (a follow-up line with the same IP)
      ip_str=$(ipdecimal_to_ipstring $ipprev)
      split_line lineppts "${rllines[$((i-1))]}"
      send_msg 1 "DUPLICATE IP: $ip_str \n  $ip_str ${lineppts[1]}  ${lineppts[2]}  ${lineppts[3]}\n  $ip_str ${lineparts[1]}  ${lineparts[2]}  ${lineparts[3]}" 
    else
      rllines_checked[${#rllines_checked[@]}]="${rllines[$i]}"
    fi
    ipprev="${lineparts[0]}"
  done
  ### return array as named global variable ###############################
  eval "$return_varname=(\"\${rllines_checked[@]}\")"
}


function recent_now_compare_lists(){
  ### Args ################################################################
  declare return_varname=$1  # Arg 1:    name of array variable to return (global; indirection)
  ### reads    global Variables !!!!!! #####################################
  # reads:    "${recentlist[@]}"  #    expected as sorted numerically indexed array of lines
  # reads:    "${nowlistx[@]}"    #    expected as sorted numerically indexed array of lines
  ##########################################################################
  #### perform COMPARISON CHECKS checks:  NOW lines against RECENT lines
  # - IP new in NOW >> OK message, insert NOW line
  # - IP missing in NOW: IP is reserved; no action, keep RECENT line 
  # - IP with changed MAC >> WARNING message, keep RECENT line (IP stays reserved / alternate: keep NOW line)
  # - IP and MAC in both: keep RECENT line but insert now date
  ##########################################################################
  #echo recentlist: ----------------------------
  #printf '%s\n' "${recentlist[@]}" # print array line by line # debug
  #echo nowlist: ---------------------------------
  #printf '%s\n' "${nowlistx[@]}" # print array line by line # debug
  #return # debug

  declare -a complines=()
  declare -i inow=0
  declare -i lnow=${#nowlistx[@]} # count of rows
  declare curdate=$(date -I)
  # declare -i ip_inserted=0 # if now_ip has been inserted, then don't insert recent_ip also.
  # cycle through RECENTLIST, compare with NOWLIST
  for thisrline in "${recentlist[@]}"; do
    split_line thisrlineparts "$thisrline"
    recent_ip=${thisrlineparts[0]}
    recent_mac=${thisrlineparts[1]}
    recent_date=${thisrlineparts[2]}
    recent_rest=${thisrlineparts[3]}
    while [[ $inow -lt $lnow ]] ; do
      thisnline="${nowlistx[$inow]}"
      split_line thisnlineparts "$thisnline"
      now_ip=${thisnlineparts[0]}
      now_mac=${thisnlineparts[1]}
      now_date=${thisnlineparts[2]}
      now_rest=${thisnlineparts[3]}
      # echo ---recent:$(ipdecimal_to_ipstring ${recent_ip})  NOW:$(ipdecimal_to_ipstring ${now_ip})## debug
      if [[ $recent_ip -gt $now_ip ]]; then
        # -    IP new in NOW >> OK message, insert NOW line
        now_ip_str=$(ipdecimal_to_ipstring $now_ip)
        thisnlineparts[2]=$curdate
        send_msg 5 "NEW IP: $now_ip_str \n      $now_ip_str   $now_mac  $now_rest" 
        #complines[${#complines[@]}]="$thisnline 0. r>n"
        complines[${#complines[@]}]=$(printf "$LINE_FMT" $(ipdecimal_to_ipstring ${thisnlineparts[0]}) ${thisnlineparts[1]} ${thisnlineparts[2]} "${thisnlineparts[3]}")
        let inow++  
        #break  # TODO test
      elif [[ $recent_ip -lt $now_ip ]]; then
        # - IP missing in NOW: IP is reserved; no action, keep RECENT line 
        # no action! complines[${#complines[@]}]="$thisrline 0. r<n"
        break
      elif [[ $recent_ip -eq $now_ip ]]; then
        if [[ $recent_mac = $now_mac ]]; then
          # -    IP and MAC in both: keep RECENT line but insert now date
          thisrlineparts[2]=${curdate}
          # no action complines[${#complines[@]}]=$(printf "%16s   %s   %10s   %s 0. r=n a\n" "${thisrlineparts[@]}")
          # ip_inserted=$now_ip
        else
          # -    IP with changed MAC >> WARNING message, keep RECENT line (IP stays reserved / alternate: keep NOW line)
          recent_ip_str=$(ipdecimal_to_ipstring $recent_ip)
          now_ip_str=$(ipdecimal_to_ipstring $now_ip)
          send_msg 2 "CONFLICTING NEW IP: $now_ip_str \n      $now_ip_str   $now_mac   $now_rest\n      $recent_ip_str   $recent_mac   $recent_rest" 
          # no action complines[${#complines[@]}]="$thisrline 0. r=n b"
        fi
        let inow++
        #break # TODO test
      else
        :
      fi
      # echo complines:  ------- "${#complines[@]}"----now_ip:$(ipdecimal_to_ipstring ${now_ip})---------    # debug
    done
    if [ $line_is_valid -ne 0 ] ; then 
      # if recent_ip ist nicht bereits aus Now_list eingetragen
      complines[${#complines[@]}]=$(printf "$LINE_FMT" $(ipdecimal_to_ipstring ${thisrlineparts[0]}) ${thisrlineparts[1]} ${thisrlineparts[2]} "${thisrlineparts[3]}")
      #complines[${#complines[@]}]="$thisrline 1. r.n"
    fi
  #  echo complines:  - "${#complines[@]}"-------recent_ip:$(ipdecimal_to_ipstring ${recent_ip})---------    # debug
  done
  echo complines: --------------------                       # debug
  printf '%s\n' "${complines[@]}" # print array line by line # debug
  eval "$return_varname=(\"\${complines[@]}\")"
}

function lines_write_to_file(){
  ### Args ################################################################
  declare f="$1"              # Arg 1:    target file  (will be overwritten)
  shift
  declare subnet="$1"         # Arg 2:    subnet with mask (to enrich output)
  shift
  declare rdur="$1"           # Arg 3:    reservation duration  (to enrich output)
  shift
  declare clines=("$@")       # Arg 4..x: array of lines or lines
  #########################################################################
  declare contents=""
  contents=$(printf '%s\n' " _____________________________________________________________________________")
  contents+='\n'$(printf ' Reserved IPs in Subnet: %s, Reservation duration: %s days\n'  "$subnet" "$rdur")
  contents+='\n'$(printf '%s\n' " _____________________________________________________________________________")
  contents+='\n'$(printf "$LINE_FMT" IP  MAC  "last-seen"  "     vendor / text")
  contents+='\n'$(printf '%s\n' " -----------------------------------------------------------------------------")
  for line in "${clines[@]}"; do
    contents+='\n'$(printf '%s\n' "$line")
  done
  contents+='\n'$(printf '%s\n' " -----------------------------------------------------------------------------")
  contents+='\n'$(printf ' generator:%s  written By:%s  Admin:%s\n' "$0" "$BY" "$ADMIN")
  contents+='\n'$(printf ' based on: %s.\n' "netdiscover")  
  contents+='\n'$(printf ' requirements: %s\n' "bash, netdiscover, sudo")  
  contents+='\n'$(printf '%s\n' " -----------------------------------------------------------------------------")
  # write to file
  echo -e "$contents" > "$f"
  return $?
}

#### prepare NOW list #######################################
# - IP into decimal representation
# - drop IPs not in this subnet
# - sort by IP
# - check for duplicate IPs; send warning msg, keep only one
#### prepare RECENT list ####################################
# - IP into decimal representation
# - omit line if date is too old
#### perform COMPARISON CHECKS checks:  NOW lines against RECENT lines
# - IP new in NOW >> OK message, insert NOW line
# - IP missing in NOW: IP is reserved; no action, keep RECENT line 
# - IP with changed MAC >> WARNING message, keep RECENT line (IP stays reserved / alternate: keep NOW line)
# - IP and MAC in both: keep RECENT line but insert now date
#### write concatenated list as RECENT list #################

nowlist_create_file "$NETSCAN_FILE"
nowlist_prepare_from_file nowlistx "$NETSCAN_FILE" $subnet_test
    # printf '%s\n' "${nowlistx[@]}" ## debug
nowlist_check_dup_ips nowlistx "${nowlistx[@]}"
    # echo "====== NOW LIST (duplicate IPs are dropped) =============" ## debug
    # printf '%s\n' "${nowlistx[@]}" ## debug
recentlist_prepare_from_file recentlist "$lfile_test"
recentlist_drop_too_old_ips recentlist $keep_days_test "${recentlist[@]}"
    # echo "====== RECENT LIST (too old items are dropped) =============" ## debug
    # printf '%s\n' "${recentlist[@]}" ## debug
recent_now_compare_lists  result_list
lines_write_to_file test.out  $subnet_test $keep_days_test "${result_list[@]}"




##### TODO ###################################################



####  several networks ######################################
# - list of IP/23 networks
# - list of reservation durations
# - different files (recent list)

#### implementing: ##########################################
# environment variables / config variables
# - send_msg  email function?
#

#### cleanup ################################################
# - delete intermediate files (nowlist)

