#!/bin/sh

CC="/Users/klaus8/Pictures/Nonrail.cocatalog"
CCDB=$(find "${CC}" -name '*.cocatalogdb' -maxdepth 1 -print0 | xargs -0 -n1 )

executesql(){
  sqlite3 "${CCDB}" "$*"
}

IMAGEPATTERN=003

SQL_CountImagesOnPattern="SELECT COUNT(*) FROM ZIMAGE WHERE ZDISPLAYNAME LIKE '%_IMAGEPATTERN_%';"

executesql "${SQL_CountImagesOnPattern/_IMAGEPATTERN_/${IMAGEPATTERN}}"





