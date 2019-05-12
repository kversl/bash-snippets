#!/bin/bash
#
##########################################



latlong2exif(){
  # parameter 1: Grades decimal number (-180.0...0..+180.0) '49.1078'
  # parameter 2: positive marker
  # parameter 3: negative marker
  # returns in EXIF style  '49,6.654N'
  local GD=$1
  if [[ $1 == -* ]] ; then
    mark=$3
    GD=${GD#-}
  else
    mark=$2
  fi

  GradMinutes=$(
    IFS='.'                         # my array separator
    GD=(${GD})                      # split decimal to array
    GDgrad=${GD[0]}                 
    GDmin=$(echo "0.${GD[1]} * 60" | bc -l)
    echo "${GDgrad:-0},${GDmin}${mark}"
  )
  echo "GradMinutes=$GradMinutes"
}


xx=$(latlong2exif $1 $2 $3)
echo $xx

decdec2array(){

  :
}
