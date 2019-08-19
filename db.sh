#!/bin/bash
FILE_PATH=/var/lib/pgsql/SOS
mkdir -p $FILE_PATH
mkdir -p $FILE_PATH/CONF
mkdir -p $FILE_PATH/LOG
mkdir -p $FILE_PATH/SAR
mkdir -p $FILE_PATH/CRONS
mkdir -p $FILE_PATH/CONFIG

chown -R postgres:postgres $FILE_PATH
DATE=`date '+%Y-%m-%d %H:%M:%S'`

sanspeedDB=$(dd if=/dev/zero of=$FILE_PATH/test1.img bs=1G count=1 oflag=dsync 2>&1)
sanspeedDB=$(echo ${sanspeedDB##*s,})
echo "***************** Today Date $DATE *****************"  >> $FILE_PATH/SOS.txt 2>&1
PORT=5432
DBSERVER=(127.0.0.1)
## DB Directory  
CLUST_PATH=`netstat -tulpn 2> /dev/null | grep postgres | grep 5432 | awk '{print $NF}' | awk -F'/' '{print $1}' | xargs ps -f  | sed "1d" | awk '{print $09}' |rev | cut -d"/" -f3- | rev`
DB_PATH=` netstat -tulpn 2> /dev/null | grep postgres | grep 5432 | awk '{print $NF}' | awk -F'/' '{print $1}' | xargs ps -f  | sed "1d" | awk '{print $09}' |rev | cut -d"/" -f4- | rev`
date1="$(date '+%Y-%m-%d')"
TDATE="$(date  '+%d')"
YDATE="$(date --date="yesterday" '+%d')"
USERNAME=postgres
echo -e " \n "  >> $FILE_PATH/SOS.txt 2>&1
#PRI_IP=`cat $CLUST_PATH/data/recovery.conf | grep primary_conninfo | awk '{print $3}'  | cut -c7-25`
_standby=`cat $CLUST_PATH/data/postgresql.auto.conf | grep hot_standby  | head -n 2 | tail -1  | awk '{print $3}'`
if [[ "$(echo "$_standby" | tr '[:upper:]' '[:lower:]')" == *"on"* ]] ;then
echo -e "Database Server               : STREAMING  REPLICATION SERVER(SR)" >> $FILE_PATH/SOS.txt 2>&1
else
echo -e "Database Server               : PRIMARY DATABASE SERVER" >> $FILE_PATH/SOS.txt 2>&1
 fi

echo -e "IP Address of Server          : `hostname -I | awk -F' ' '{print $1}'`"  >> $FILE_PATH/SOS.txt 2>&1      
echo -e "Hostname                      : `hostname`"   >> $FILE_PATH/SOS.txt 2>&1                                 
echo -e "OS Flavour with version       : `cat /etc/redhat-release`"  >> $FILE_PATH/SOS.txt 2>&1                                 
echo -e "Total RAM                     : `free -g |grep "Mem:" |awk -F' ' '{print $2 + 1}'`G "  >> $FILE_PATH/SOS.txt 2>&1     
echo -e "Total vCPU                    : `nproc` "  >> $FILE_PATH/SOS.txt 2>&1                                                    
echo -e "Server Date & Time            : `date` " >> $FILE_PATH/SOS.txt 2>&1 
echo -e "Server Load Average           : `uptime | awk -F'load average: ' '{ print $2 }'` " >> $FILE_PATH/SOS.txt 2>&1
echo -e "SAN utilization:              : `df -h | grep Filesystem`  " >> $FILE_PATH/SOS.txt 2>&1 
echo -e "SAN utilization(Pgsql)        : `df -h | grep /var/lib/pgsql` "   >> $FILE_PATH/SOS.txt 2>&1 
echo -e "SAN writing speed Database    : $sanspeedDB "  >> $FILE_PATH/SOS.txt 2>&1
touch $FILE_PATH/test.txt

if [ $FILE_PATH/test.txt ]; then
echo -e "READ AND WRITE MODE           : Enabled" >> $FILE_PATH/SOS.txt 2>&1
rm $FILE_PATH/test.txt -f
else
echo -e "READ AND WRITE MODE           :   not Enabled" >> $FILE_PATH/SOS.txt 2>&1
fi
echo -e "SERVER UPTIME                 : `uptime  | awk -F' ' '{ print $3,$4 }'`"  >> $FILE_PATH/SOS.txt 2>&1 
echo -e "Firewall status               : `service  firewalld status  | grep Active | awk -F':' '{ print $2}'|awk '{$1=$1};1'`  "  >> $FILE_PATH/SOS.txt 2>&1
echo -e "SELinux status                : `getenforce`"  >> $FILE_PATH/SOS.txt 2>&1
echo -e "PostgreSQL Status             : `su - postgres -c  "$CLUST_PATH/bin/pg_ctl -D $CLUST_PATH/data/ status" | grep pg_ctl | awk -F':' '{print \$2}' | awk -F' ' '{print \$1,\$2,\$3}'`"  >> $FILE_PATH/SOS.txt 2>&1
SR=`$CLUST_PATH/bin/psql -U $USERNAME -xc "select state from pg_stat_replication where application_name ='walreceiver';"  | head -2 | tail -1 | awk '{print $3}'`
SR_IP=`$CLUST_PATH/bin/psql -U $USERNAME -xc "select client_addr from pg_stat_replication where application_name ='walreceiver';"  | head -2 | tail -1 | awk '{print $3}'`
if [[ "$(echo "$SR" | tr '[:upper:]' '[:lower:]')" == *"streaming"* ]] ;then

echo -e "SR STATUS                     : STREAMING  REPLICATION SUCCESSFULLY RUNNING(SR_IP=$SR_IP)" >> $FILE_PATH/SOS.txt 2>&1
else
echo -e "SR STATUS                     : STREAMING  REPLICATION NOT RUNNING" >> $FILE_PATH/SOS.txt 2>&1
 fi
CHK1=`systemctl list-unit-files  | grep postgresql- | awk '{print $2}'  | awk -F':' '{print $2}'`
CHK2=`chkconfig --list 2>/dev/null |  grep postgresql- | awk '{print $6}'  | awk -F':' '{print $2}'`

if [[ "$(echo "$CHK1" | tr '[:upper:]' '[:lower:]')" == *"enabled"* ]] ;then
echo -e  "PostgreSQL Boot Status                  : Enabled" >> $FILE_PATH/SOS.txt 2>&1
elif [[ "$(echo "$CHK2" | tr '[:upper:]' '[:lower:]')" == *"4:on"* ]] ;then
echo -e  "PostgreSQL Boot Status        : Enabled" >> $FILE_PATH/SOS.txt 2>&1
else 
echo -e  "PostgreSQL Boot Status        : Not Enabled" >>  $FILE_PATH/SOS.txt 2>&1
fi

for host in ${DBSERVER[@]};
  do
############################################################## Get All Database Name ###########################################################################
schemaname=`$CLUST_PATH/bin/psql  -h $host -U $USERNAME -c "SELECT datname from pg_database  where  datname not like 'eOffice_MasterDB'  and  datname not like 'alerts' and  datname not like 'RevocationRegistry' and datname not ilike '%template%' and datname not ilike 'postgres' order by 1 ;" |sed "1,2d" |head -n -2`
for s in ${schemaname[@]};
  do

DBUSER=`$CLUST_PATH/bin/psql -h $host -U $USERNAME -c "SELECT pg_catalog.pg_get_userbyid(d.datdba) as Owner FROM pg_catalog.pg_database d WHERE d.datname = '$s' ORDER BY 1;"| sed "4d" | sed "1,2d"`

sitename=`$CLUST_PATH/bin/psql -d $s -h $host -U $USERNAME -c "select trim(department_name) from fl_department;"| sed "4d" | sed "1,2d"  | cut -d ' ' -f  2`


echo -e " \n "  >> $FILE_PATH/SOS.txt 2>&1

PRODUCT=`$CLUST_PATH/bin/psql -U $DBUSER -d $s  -c "select schema_name from information_schema.schemata where schema_name ='eleave';"  | head -3 | tail -2`
if [[ "$(echo "$PRODUCT" | tr '[:upper:]' '[:lower:]')" == *"eleave"* ]] ;then

echo -e "eOffice Product Type          : Premium" >> $FILE_PATH/SOS.txt 2>&1
else
echo -e "eOffice Product Type          : Lite" >> $FILE_PATH/SOS.txt 2>&1
 fi
echo -e "Application Mode              : `$CLUST_PATH/bin/psql -U $USERNAME -d $s  -c "select sub_module_name from admin.adm_sub_module  where description = 'Browse and Diarise';" | sed -e 's/^[ \t]*//'  | head -3 | tail -1`" >> $FILE_PATH/SOS.txt 2>&1

$CLUST_PATH/bin/psql -U $DBUSER -d $s  -c "\\o $FILE_PATH/fl_config_$s.txt" -c "select * from fl_configuration;"


echo -e "Last Vacuum status            : Database $s  "  >> $FILE_PATH/SOS.txt 2>&1 

echo -e " \n "  >> $FILE_PATH/SOS.txt 2>&1
$CLUST_PATH/bin/psql -U $DBUSER -d $s -xc "select last_autoanalyze, last_autovacuum, last_vacuum from pg_stat_all_tables where relname='fl_note';" | head -5 | tail -4 >> $FILE_PATH/SOS.txt 2>&1 

echo -e " \n "  >> $FILE_PATH/SOS.txt 2>&1

echo -e "DATABASE SIZE                 :  "  >> $FILE_PATH/SOS.txt 2>&1
echo -e " \n "  >> $FILE_PATH/SOS.txt 2>&1

$CLUST_PATH/bin/psql -U $USERNAME -c "SELECT row_number() over (order by 1) sno, pg_database.datname as "database_name", pg_size_pretty(pg_database_size(pg_database.datname)) AS size_in_mb FROM pg_database where pg_database.datname <>'postgres' and pg_database.datname <>'template1' and  pg_database.datname <>'template0' and pg_database.datname <>'alerts' and  pg_database.datname <>'eOffice_MasterDB'  and pg_database.datname <>'RevocationRegistry' ORDER by 1;"  >> $FILE_PATH/SOS.txt


echo -e " \n "  >> $FILE_PATH/SOS.txt 2>&1

echo -e "Number of tables              : `$CLUST_PATH/bin/psql -U $DBUSER -d $s -c "select count(*) as total from information_schema.tables WHERE table_type = 'BASE TABLE' and table_schema <> 'pg_catalog' and table_schema <> 'information_schema'" ;` " | head -3 | tail -3  >> $FILE_PATH/SOS.txt 2>&1 


echo -e "Number of views               : `$CLUST_PATH/bin/psql -U $DBUSER -d $s -c "select count(*) as total from information_schema.views WHERE table_schema <> 'pg_catalog' and table_schema <> 'information_schema'" ;` "  | head -3 | tail -3   >> $FILE_PATH/SOS.txt 2>&1 


echo -e "Postgres owner tables         : `$CLUST_PATH/bin/psql -U $DBUSER -d $s -c "SELECT count(*) FROM pg_class c, pg_user u WHERE c.relowner = u.usesysid and c.relkind = 'r'  and  u.usename='postgres'  and relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname NOT LIKE 'pg_%'AND nspname != 'information_schema');"` "  | head -3 | tail -3   >> $FILE_PATH/SOS.txt 2>&1 

#echo -e "Postgres owner tables   : `$CLUST_PATH/bin/psql -U $DBUSER -d $s -c "SELECT c.relname,u.usename FROM pg_class c, pg_user u WHERE c.relowner = u.usesysid and c.relkind = 'r'  and  u.usename='postgres'  and relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname NOT LIKE 'pg_%'AND nspname != 'information_schema');"` "   >> $FILE_PATH/SOS.txt 2>&1 


echo -e "Postgres owner views          : `$CLUST_PATH/bin/psql -U $DBUSER -d $s -c "SELECT count(*) FROM pg_class c, pg_user u WHERE c.relowner = u.usesysid and c.relkind = 'v'  and  u.usename='postgres'  and relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname NOT LIKE 'pg_%'AND nspname != 'information_schema')" ;` "  | head -3 | tail -3   >> $FILE_PATH/SOS.txt 2>&1 

#echo -e "Postgres owner views    : `$CLUST_PATH/bin/psql -U $DBUSER -d $s -c "SELECT c.relname,u.usename FROM pg_class c, pg_user u WHERE c.relowner = u.usesysid and c.relkind = 'v'  and  u.usename='postgres'  and relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname NOT LIKE 'pg_%'AND nspname != 'information_schema')" ;` "   >> $FILE_PATH/SOS.txt 2>&1 




echo -e "Postgres owner sequences      : `$CLUST_PATH/bin/psql -U $DBUSER -d $s -c "SELECT count(*) FROM pg_class c, pg_user u WHERE c.relowner = u.usesysid and c.relkind = 'S'  and  u.usename='postgres'  and relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname NOT LIKE 'pg_%'AND nspname != 'information_schema')" ;` "  | head -3 | tail -3   >> $FILE_PATH/SOS.txt 2>&1 

#echo -e "Postgres owner sequences    : `$CLUST_PATH/bin/psql -U $DBUSER -d $s -c "SELECT c.relname,u.usename FROM pg_class c, pg_user u WHERE c.relowner = u.usesysid and c.relkind = 'S'  and  u.usename='postgres'  and relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname NOT LIKE 'pg_%'AND nspname != 'information_schema')" ;` "  | head -3 | tail -3   >> $FILE_PATH/SOS.txt 2>&1 




$CLUST_PATH/bin/psql -U $DBUSER -d $s -A -c "CREATE OR REPLACE FUNCTION mis_version_test()
   RETURNS VARCHAR(50) AS \$$
DECLARE
mversion text;
 BEGIN

 IF EXISTS ( SELECT 1 FROM   information_schema.tables where table_name ='release_note') then
 select max(version) from mis.release_note into mversion;

 ELSE
 select '0' into mversion;
 END IF;
 return mversion;

END; \$$
LANGUAGE plpgsql;"

$CLUST_PATH/bin/psql -U $DBUSER -d $s -A -c "CREATE OR REPLACE FUNCTION eleave_version_test()
   RETURNS VARCHAR(50) AS \$$
  declare lversion text;
 BEGIN

 IF EXISTS ( SELECT 1 FROM   information_schema.tables where table_name ='eleave_release_note') then
 select max(eleave_version) from eleave.eleave_release_note into lversion;

 ELSE
 select '0' into lversion;
 END IF;
 return lversion;

END; 

\$$
LANGUAGE plpgsql;"


$CLUST_PATH/bin/psql -U $DBUSER -d $s -A -c "drop table server_check;"

echo -e " \n "  >> $FILE_PATH/SOS.txt 2>&1

echo -e "$s  data   :"  >> $FILE_PATH/SOS.txt 2>&1


$CLUST_PATH/bin/psql -d $s -U $DBUSER -xc "create table  server_check as
select
(select trim(resource_value) as instance_name from fl_configuration  where resource_key ='ministryName') as instance_name,
(select '$date1'::date as stats_date) stats_date,
(select now() as report_date) as report_date,
(select min(opening_date::date) as initiation_date from fl_file where file_nature='E' and (is_migrated=false or is_migrated is null)) as first_efile_opening_date,
(select min(receipt_creation_date::date) from fl_correspondence_receipt where receipt_nature='E') as first_ereceipt_creation_date,
(select count(*) from emd.emd_user) as total_users,
(select count(*) from empdetailsview) as active_users_portal,
(select count(distinct(login_id)) from vw_employee_details_with_department  where is_user_active=true and is_postdetail_active=true and isemployee_active=true) as active_users_efile,
(select count(*) from fl_file where file_nature = 'E'  and file_state_fk NOT IN (11,12) and  opening_date::date<='$date1') as electronic_files_created,
(select count(*) from fl_file where file_nature = 'P'  and file_state_fk NOT IN (11,12)  and opening_date::date<='$date1') as physical_files_created,
(select count(*) from fl_correspondence_receipt where receipt_nature = 'E' and receipt_creation_date::date<='$date1') as electronic_receipts_created,
(select count(*) from fl_correspondence_receipt where receipt_nature = 'P' and receipt_creation_date::date<='$date1') as physical_receipts_created,
(select count(*) from fl_file fl inner join fl_file_movement movement on movement.file_number_fk = fl.file_id inner join vw_employee_details_with_department vw on vw.post_detail_id = movement.sent_by_post_fk where  fl.file_nature = 'E' and movement.sent_date::date <='$date1') as electronic_file_moved,
(select count(*) from fl_file fl inner join fl_file_movement movement on movement.file_number_fk = fl.file_id inner join vw_employee_details_with_department vw on vw.post_detail_id = movement.sent_by_post_fk where  fl.file_nature = 'P' and movement.sent_date::date <='$date1') as physical_file_moved,
(select count(*) from fl_correspondence_receipt cr inner join fl_correspondence_receipt_movement movement on movement.correspondence_receipt_fk = cr.correspondence_id inner join vw_employee_details_with_department vw on vw.post_detail_id = movement.sent_by_post_fk where  cr.receipt_nature = 'E' and movement.send_date::date <='$date1') as electronic_receipts_moved,
(select count(*) from fl_correspondence_receipt cr inner join fl_correspondence_receipt_movement movement on movement.correspondence_receipt_fk = cr.correspondence_id inner join vw_employee_details_with_department vw on vw.post_detail_id = movement.sent_by_post_fk where  cr.receipt_nature = 'P' and movement.send_date <='$date1') as physical_receipts_moved,
(select count(*) from fl_file where file_nature = 'E'  and file_state_fk NOT IN (4,11,12) and  opening_date::date<='$date1') as electronic_files_active,
(select count(*) from fl_file where file_nature = 'E'  and file_state_fk=4 and  opening_date::date<='$date1') as electronic_files_closed,
(select count(*) from fl_file where file_nature = 'P'  and file_state_fk NOT IN (4,11,12)  and opening_date::date<='$date1') as physical_files_active,
(select count(*) from fl_file where file_nature = 'P'  and file_state_fk=4  and opening_date::date<='$date1') as physical_files_closed,
(select count(distinct(departmentname)) from vw_employee_details_with_department vw left join emd.emd_org_unit ou on vw.departmentid=ou.org_unit_id where ou.is_active=true ) as active_global_ou,
(select max(version) from fl_release_note) as efile_current_version,
(SELECT max(substring(emd_version from '(([0-9]+.*)*[0-9]+)'))FROM emd.emd_version) as emd_current_version,
(SELECT mis_version_test()) as misversion ,
(SELECT eleave_version_test()) as eleaveversion ,
(SELECT current_setting('server_version')) as postgresql_version " >> $FILE_PATH/SOS.txt 2>&1


echo -e "$s Data   : `$CLUST_PATH/bin/psql -d $s -U $USERNAME -xc "select * from server_check" ;` " | sed -n '1!p'  >> $FILE_PATH/SOS.txt 2>&1 
 
sleep 1

done
done



LOG=`$CLUST_PATH/bin/psql -U $USERNAME  -c "show log_directory;"  | head -3 | tail -1 | sed -e 's/^[ \t]*//'`

if [[ "$LOG" == log ]] ;then

find $CLUST_PATH/data/log/ -type f -name *.log ! -path '$CLUST_PATH/data/log/startup.log' -mtime -7 -exec cp -rf  {} $FILE_PATH \;
else
find $CLUST_PATH/data/pg_log/ -type f -name *.log ! -path '$CLUST_PATH/data/pg_log/startup.log' -mtime -7 -exec cp -rf  {} $FILE_PATH \;
fi


cp -rf $CLUST_PATH/data/postgresql.auto.conf $FILE_PATH/.
cp -rf $CLUST_PATH/data/postgresql.conf $FILE_PATH/.
cp -rf /var/spool/cron/postgres $FILE_PATH/.
cp -rf $CLUST_PATH/data/pg_hba.conf $FILE_PATH/.
cp -rf /var/log/messages $FILE_PATH/system.log
cp -rf /var/spool/cron/root  $FILE_PATH/.
cp -rf /var/log/secure $FILE_PATH/secure.log
cp -rf /etc/fstab $FILE_PATH/secure.log
cp -rf /var/log/sa/sa$TDATE $FILE_PATH/.
cp -rf  /var/log/sa/sa$YDATE  $FILE_PATH/.


mv $FILE_PATH/*.log $FILE_PATH/LOG/.
mv $FILE_PATH/*.conf $FILE_PATH/CONF/.
mv $FILE_PATH/postgres $FILE_PATH/CRONS/.
mv $FILE_PATH/root $FILE_PATH/CRONS/.
mv $FILE_PATH/sa* $FILE_PATH/SAR/.
mv $FILE_PATH/fl_config* $FILE_PATH/CONFIG/.

rm -f $FILE_PATH/test1.img

tar -cvpzf /var/lib/pgsql/SOS_DB_REPORT_"$sitename"_"$date1".tar.gz  -C $FILE_PATH .


rm -rf $FILE_PATH/*

