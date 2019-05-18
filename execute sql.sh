# execute sql query

h=localhost
p=3307
db=db_pv_control
u=pv_controller
pwd=321zu321db
q="SHOW tables;"
opt="--batch"

 mysql --protocol=TCP --host=$h --port=$p $opt -u$u -p$pwd $db --execute="$q"

