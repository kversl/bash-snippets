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
    IFS=.                           # my array separator
    GD=(${GD})                      # split decimal to array
    GDgrad=${GD[0]}                 
    GDmin=$(echo "0.${GD[1]} * 60" | bc -l)
    echo "${GDgrad:-0},${GDmin}${mark}"
  )
  echo "GradMinutes=$GradMinutes"
}

lat2exif(){
  # parameter 1: Grades decimal number (-90...0...90)
  local gd=$(latlong2exif $1 N S)
  echo $gd
}

long2exif(){
  # parameter 1: Grades decimal number (-180...0...180)
  local gd=$(latlong2exif $1 E W)
  echo $gd
}

llsplit(){
  # parameter 1: lat/long string as "49.1078/9.737"
  # returns both numbers as an array
  lls=$1
  llarray=$(
    IFS=/                           # my array separator
    llarray=(${lls})                # split to array
    echo ${llarray[@]}
  )
  echo ${llarray[@]}
}





llarray=($(llsplit 49.1078/9.737))
latexif=$(lat2exif ${llarray[0]})
longexif=$(long2exif ${llarray[1]})


