#!/bin/bash
#
# required: ##########################
#   CaptureOne on MacOSX              
# ####################################
# VARS:
# - Image name (part of)
# - overwrite?
# - latitude/longitude
# - path to CaptureOne Catalog
######################################
USAGE="
====================================
adds EXIF coordinates to an IMAGE
   inside a CaptureOne COCATALOG
   or in a COSESSION
====================================
prerequisites:
- remembers CaptureOne cocatalog: "$CC"
- do not replace existing coordinates 
- limit to one IMAGE, if not a range
====================================
required parameters 
1. geoCoordinates as decimal numbers string \"[latitude]/[longitude]\"
2. one or several (part of) IMAGE names (filename)
   or
2. range of consecutive full IMAGE NAMES

optional parameters
-c \"path/to/CaptureOne catalog\" 
====================================
"
PREFERENCESDIR="${HOME}/.config"
PREFERENCESFILE="$0.pref"
CCDBPATTERN="*.cocatalogdb"

prefsdirCheck(){
  if [ ! -d "$PREFERENCESDIR" ]; then mkdir -p "$PREFERENCESDIR" ; fi
}

writeprefs(){
  prefsdirCheck
  echo "CC=${CC}" > "${PREFERENCESDIR}/${PREFERENCESFILE}"
}

# read preferences 
if [ -r "${PREFERENCESDIR}/${PREFERENCESFILE}" ]; then
  . "${PREFERENCESDIR}/${PREFERENCESFILE}"
fi

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -c|--catalog)
      CATALOGBUNDLE="$2"
      WRITEPREFS=1
      shift
      shift
      ;;
    -h|--help)
      echo "$USAGE"
      exit 0
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done
set -- "${POSITIONAL[@]}"             # restore positional parameters

======================================

if [[ "${POSITIONAL[1]}" == *?-?* ]]; then
  # imagename contains a hyphen
  echo "image name contains a hyphen. Range not implemented yet."
  exit
else
  IMAGEPATTERN="${POSITIONAL[1]}"
fi






if [[ $WRITEPREFS -eq 1 ]]; then  
  writeprefs
fi

