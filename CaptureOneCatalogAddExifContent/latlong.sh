#!/bin/bash

latlong2exif(){
  # parameter 1: Grades decimal number (-180.0...0..+180.0) '49.1078'
  # parameter 2: positive marker
  # parameter 3: negative marker
  # $latlong2exif_v:  EXIF style  '49,6.654N'
  local GD=$1
  if [[ $1 == -* ]] ; then
    mark=$3
    GD=${GD#-}
  else
    mark=$2
  fi
  latlong2exif_v=$(
    IFS=.                           # my array separator
    GD=(${GD})                      # split decimal to array
    GDgrad=${GD[0]}                 
    GDmin=$(echo "0.${GD[1]} * 60" | bc -l)
    echo "${GDgrad:-0},${GDmin}${mark}"
  )
}

lat2exif(){
  # parameter 1: Grades decimal number (-90...0...90)
  latlong2exif_v=0
  latlong2exif $1 N S
  lat2exif_v=$latlong2exif_v
}

long2exif(){
  # parameter 1: Grades decimal number (-180...0...180)
  latlong2exif_v=0
  latlong2exif $1 E W
  long2exif_v=$latlong2exif_v
}

llsplit(){
  # parameter 1: lat/long string as "49.1078/9.737"
  # ${llsplit_a[@]}: numbers as an array
  OIFS="$IFS"
  IFS='/' read -r -a llsplit_a <<< "$1"
  IFS="$OIFS"
}

csvsplit(){
  # parameter 1: csv values as string
  # ${csvsplit_a[@]}: comma-separated values as an array
  #   note: comma inside string is treated as separator!!!
  OIFS="$IFS"
  IFS=',' read -r -a csvsplit_a <<< "$@"
  IFS="$OIFS"
  echo ${llarray[@]}
}

linesplit(){
  # parameters: lines of text
  # ${linesplit_a[@]} an array
  linesplit_a=()
  if [[ ${#@} > 0 ]]; then
    while IFS='\n' read -r aline ; do
      linesplit_a+=("$aline")
    done < <(echo "$*")
  fi
}





# llarray=($(llsplit 49.1078/9.737))
# latexif=$(lat2exif ${llarray[0]})
# longexif=$(long2exif ${llarray[1]})
