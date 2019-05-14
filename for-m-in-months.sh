#  for m in months

yy=2011  # start 
mm=2    # start
months=97 # count of months
y=$yy
for m in $(seq 1 $months) ; do
  yyp=$yy
  mmp=$mm
  
  let "mm=m%12 + 1"
  let "yy=$y + m / 12"

  dmp=$yyp-$mmp-01
  dm=$yy-$mm-01 

  echo $dmp , $dm

done
