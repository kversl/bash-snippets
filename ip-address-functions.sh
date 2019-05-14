function ipstring_to_ipdecimal(){
  ### Args #############################################################
  declare IPv4=${1:-0}   # Arg 1: ipv4 string; default: 0
  #### split ipv4 into octets ##########################################
  if  [[ "$IPv4" =~ ^[[:digit:]]*.[[:digit:]]*.[[:digit:]]*.[[:digit:]]*$ ]]
  then
    IFS='.' read -r -a octet <<< $IPv4  ## word split
    ### octets=(192 168 253 178)  in Binärzahl umwandeln
    echo $(( (${octet[0]}<<24) + (${octet[1]}<<16) + (${octet[2]}<<8) + ${octet[3]} ))
  else
    echo "$IPv4"
  fi
}

function ipdecimal_to_ipstring(){
  ### Args #############################################################
  declare -i ipd=$1        # Arg 1: integer as ipv4 binary representation 
  declare -i width=${2:-0} # Arg 2: width in chars; default: 0
  #### binary representation into Octets  ##############################
  declare ip4=()
  for i in 3 2 1 0; do
    ip4[$i]=$(( ipd & 0xFF ))
    ipd=$(( ipd >> 8 ))
  done
  #### Octets into IPv4 String, formatted <width> chars, left aligned
  declare ip4s="${ip4[0]}.${ip4[1]}.${ip4[2]}.${ip4[3]}"
  printf %-${width}s%n $ip4s
}

function ip_in_subnet() {
  ### Args #############################################################  
  declare ipv4=$1          # Arg 1: IPv4 address           "192.168.253.22"
                           #           or decimal          "3232300521"
  declare subnetwm=$2      # Arg 2: IPv4 subnet with mask: "192.168.253.0/24"
	### test if IPv4 address is in IPv4 SUBNET with Mask #################
  declare -i subnetmnr=${subnetwm#*/} # 24
  declare subnetmbits=$(( 0xFFFFFFFF & 0xFFFFFFFF << (32- subnetmnr) ))
  declare subnet0="${subnetwm%/*}" # 192.168.253.0
  declare -i subnet0dec=$(ipstring_to_ipdecimal $subnet0)
	###
  if  [[ "$ipv4" =~ ^[[:digit:]]*.[[:digit:]]*.[[:digit:]]*.[[:digit:]]*$ ]]
  then
    declare -i ipd=$(ipstring_to_ipdecimal $ipv4)
  elif [[ "$ipv4" =~ ^[[:digit:]]*$ ]]; then
    declare -i ipd=$ipv4
  fi
  declare -i ipd0=$(( ipd & subnetmbits))
  [[ $subnet0dec == $ipd0 ]]
  echo $?
}



