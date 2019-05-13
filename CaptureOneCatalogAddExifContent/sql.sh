#!/bin/sh

CC="/Users/klaus8/Pictures/Nonrail.cocatalog"
CCDB=$(find "${CC}" -name '*.cocatalogdb' -maxdepth 1 -print0 | xargs -0 -n1 )

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
  
  echo $(sqlite3 "${OPTIONS[@]}" "${CCDB}" "$*")
}

IMAGEPATTERN=003

SQL_CountImagesOnPattern="SELECT COUNT(*) FROM ZIMAGE WHERE ZDISPLAYNAME LIKE '%_IMAGEPATTERN_%';"

executesql "${SQL_CountImagesOnPattern/_IMAGEPATTERN_/${IMAGEPATTERN}}" "-ascii"

### list IMAGENAMe and current Geo contents




