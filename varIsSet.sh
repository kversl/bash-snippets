function varIsSet {
  # argument: a varname
  # return 0 if a variable of name varname is set
  # return error if a variable name is not set or invalid 
  varname="$1"
  # check if name is valid -- if no, then return 1
  if ! [[ "$varname" =~ ^[[:alpha:]][[:alnum:]_]*$ ]]; then 
    return 2; 
  fi

  # https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
  # and indirection '!'
  if [ -z ${!varname+x} ]; then 
    # echo "var is unset"; 
    return 1;
  else 
    # echo "var is set to '$var'"; 
    return 0;
  fi
}

function varIsArray {
  # argument: a varname
  # return 0 if a variable of name varname is set and is an array
  varname="$1"
  # check if name is valid -- if no, then return 1
  if ! [[ "$varname" =~ ^[[:alpha:]][[:alnum:]_]*$ ]]; then 
    return 2; 
  fi

  # https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
  # and indirection '!'
  if [ -z ${!varname+x} ]; then 
    # echo "var is unset"; 
    return 1;
  else 
    # echo "var is set to '$var'"; 
    # https://stackoverflow.com/questions/14525296/bash-check-if-variable-is-array
    declare -p ${!varname} 2> /dev/null | grep -q '^declare \-a'
    if [ $? == 0 ]; then
      return 0;
    else
      return 3; # variable is not an array
    fi
  fi
}
