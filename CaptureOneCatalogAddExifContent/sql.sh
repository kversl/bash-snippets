#!/bin/sh

executesql(){
  # any parameter string starting with '-' will be treated as OPTION, examples:
  # -ascii
  # -separator |
  # any following parameters will be treated as a sql QUERY.
  POSITIONAL=()
  OPTIONS=()
  while [[ $# -gt 0 ]]; do
    local key="$1"
    case $key in
    -*)
      OPTIONS+=("$1")
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
  done
  set -- "${POSITIONAL[@]}"             # restore positional parameters
  
  # echo $(sqlite3 "${OPTIONS[@]}" "${CCDB}" "$*")
  sqlite3 "${OPTIONS[@]}" "${CCDB}" "$*"
  # sqlite3 "${OPTIONS[@]}" "${CCDB}" "$*" | xargs echo -n
}



