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
USAGE:
$0 49.231/10.9234 DCC0333

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
CC="/Users/klaus8/Pictures/Nonrail.cocatalog"
CCDB=$(find "${CC}" -name '*.cocatalogdb' -maxdepth 1 -print0 | xargs -0 -n1 )

# import functions 
. ./sql.sh ####### executesql(){} ########
. ./latlong.sh ### geo-functions llsplit(), lat2exif(), long2exif()

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

#======================================
if [[ ${#POSITIONAL[@]} -lt 2 ]]; then
  PROMPTUSER=1
  echo "$USAGE"
else
  if [[ "${POSITIONAL[1]}" == *?-?* ]]; then
    # imagename contains a hyphen
    echo "image name contains a hyphen. Range not implemented yet."
    exit
  else
    echo "IMAGEPATTERN=${POSITIONAL[1]};"
    IMAGEPATTERN="${POSITIONAL[1]}"
  fi
  LLSTRING="${POSITIONAL[0]}"
  echo "LLSTRING=${POSITIONAL[0]};"
fi
#=====================================

#########################################
##    Auftrag: bild-Pattern und Geo-string
## 1. genau ein Bild gefunden?
## 2. Geo noch nicht gesetzt?
## 3. wenn OK, dann schreiben.
#########################################

## 1. 
[[ $PROMPTUSER -eq 1 ]] && read -p "Enter Image PATTERN: " IMAGEPATTERN
SQL_CountImagesOnPattern="SELECT ZDISPLAYNAME FROM ZIMAGE WHERE ZDISPLAYNAME LIKE '%_IMAGEPATTERN_%';"
dnamescsv=$(executesql "${SQL_CountImagesOnPattern/_IMAGEPATTERN_/${IMAGEPATTERN}}" -csv)
if [[ ${#dnamescsv} > 2 ]]; then
  linesplit_a=()
  linesplit "$dnamescsv"
else
  echo "SQL RETURNED TOO LESS:${#dnamescsv}; CHARACTERS"
  echo "GEFUNDEN TOO LESS:${#linesplit_a[@]};"
fi
echo "SQL RETURNED:${#dnamescsv}; CHARACTERS"
echo "GEFUNDEN:${#linesplit_a[@]};"
if [[ ${#linesplit_a[@]} -eq 1 ]] ; then
  DISPLAYNAME="${linesplit_a[0]}"
else
  echo "PATTERN matches ${#linesplit_a[@]} images. Only one is accepted. Exit now. These images: ${linesplit_a[@]}" 
  exit;
fi

## 2.
SQL_LatLongFromPattern="SELECT ZGPSLATITUDE, ZGPSLONGITUDE FROM ZIMAGE WHERE ZDISPLAYNAME LIKE '%_IMAGEPATTERN_%';"
llIMG=$(executesql "${SQL_LatLongFromPattern/_IMAGEPATTERN_/${IMAGEPATTERN}}" -csv )
if [[ "$llIMG" = "," ]] || [[ "$llIMG" = ",,*" ]] ; then
  echo "Contains no Coordinates. Continue."
else
  echo "image already contains Coordinates:${llIMG}. Exit now"
fi

## 3.
llstring="${LLSTRING}"
[[ $PROMPTUSER -eq 1 ]] &&  read -p "Enter Lat/Long: " llstring
llsplit_a=()
llsplit $llstring
lat2exif_v=0
lat2exif ${llsplit_a[0]}
long2exif_v=0
long2exif ${llsplit_a[1]}

SQL_SetLatLongOnImage="UPDATE ZIMAGE SET ZGPSLATITUDE = '_LAT_', ZGPSLONGITUDE = '_LONG_' WHERE ZDISPLAYNAME = '_DISPLAYNAME_';"
SQL_SetLatLongOnImage="${SQL_SetLatLongOnImage/_LAT_/$lat2exif_v}"
SQL_SetLatLongOnImage="${SQL_SetLatLongOnImage/_LONG_/$long2exif_v}"
llIMG=$(executesql "${SQL_SetLatLongOnImage/_DISPLAYNAME_/${DISPLAYNAME}}" -csv )
echo sql replied:"${llIMG};"





#======================================
if [[ $WRITEPREFS -eq 1 ]]; then  
  writeprefs
fi

