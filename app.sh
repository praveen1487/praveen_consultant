#!/bin/bash

FILE_PATH=/eOffice/APPSOS
mkdir -p $FILE_PATH
mkdir -p $FILE_PATH/CONF
mkdir -p $FILE_PATH/LOG
mkdir -p $FILE_PATH/CONTEXT
mkdir -p $FILE_PATH/CONNECTION
mkdir -p $FILE_PATH/SAR
mkdir -p $FILE_PATH/CRONS
mkdir -p $FILE_PATH/SERVICE

chown -R eoffice:eoffice $FILE_PATH
DATE=`date '+%Y-%m-%d %H:%M:%S'`
tomcat='/bin/version.sh'
sanspeedDB=$(dd if=/dev/zero of=/Uploads/test1.img bs=1G count=1 oflag=dsync 2>&1)
sanspeedDB=$(echo ${sanspeedDB##*s,})
echo "***************** Today Date $DATE *****************"  >> $FILE_PATH/SOS.txt 2>&1
date1="$(date '+%Y-%m-%d')"
TDATE="$(date  '+%d')"
YDATE="$(date --date="yesterday" '+%d')"
DBNAME=eOffice
USERNAME=postgres
echo -e " \n "  >> $FILE_PATH/SOS.txt 2>&1

echo -e "IP Address of Server          : `hostname -I | awk -F' ' '{print $1}'`"  >> $FILE_PATH/SOS.txt 2>&1      
echo -e "Hostname                      : `hostname`"   >> $FILE_PATH/SOS.txt 2>&1                                 
echo -e "OS Flavour with version       : `cat /etc/redhat-release`"  >> $FILE_PATH/SOS.txt 2>&1                                 
echo -e "Total RAM                     : `free -g |grep "Mem:" |awk -F' ' '{print $2 + 1}'`G "  >> $FILE_PATH/SOS.txt 2>&1     
echo -e "Total vCPU                    : `nproc` "  >> $FILE_PATH/SOS.txt 2>&1                                                    
echo -e "Server Date & Time            : `date` " >> $FILE_PATH/SOS.txt 2>&1 
echo -e "Server Load Average           : `uptime | awk -F'load average: ' '{ print $2 }'` " >> $FILE_PATH/SOS.txt 2>&1
echo -e "SAN utilization:              : `df -h | grep Filesystem`  " >> $FILE_PATH/SOS.txt 2>&1 
echo -e "SAN utilization(eOffice)      : `df -h | grep /eOffice` "   >> $FILE_PATH/SOS.txt 2>&1 
echo -e "SAN utilization(/Uploads)     : `df -h | grep /Uploads` "   >> $FILE_PATH/SOS.txt 2>&1 
echo -e "SAN writing speed /Uploads    : $sanspeedDB "  >> $FILE_PATH/SOS.txt 2>&1

CHK=`chkconfig --list 2>/dev/null | grep eofficestartup | awk '{print $6}'  | awk -F':' '{print $2}'`

if [[ "$(echo "$CHK" | tr '[:upper:]' '[:lower:]')" == *"on"* ]] ;then
echo -e  "eOfficestartup Boot Status   : Enabled" >> $FILE_PATH/SOS.txt 2>&1
else
echo -e  "eOfficestartup Boot Status   : Not Enabled" >>  $FILE_PATH/SOS.txt 2>&1
fi

touch /Uploads/test.txt

if [ /Uploads/test.txt ]; then

echo -e "SAN                           : read/write mode " >> $FILE_PATH/SOS.txt 2>&1

rm -f /Uploads/test.txt 

else

echo -e "SAN                           : read only mode " >> $FILE_PATH/SOS.txt 2>&1

fi 


echo -e "SERVER UPTIME                 : `uptime  | awk -F' ' '{ print $3,$4 }'`"  >> $FILE_PATH/SOS.txt 2>&1 
echo -e "Firewall status               : `service  firewalld status  | grep Active | awk -F':' '{ print $2}'|awk '{$1=$1};1'`  " >> $FILE_PATH/SOS.txt 2>&1 
echo -e "SELinux status	              : `getenforce`" >> $FILE_PATH/SOS.txt 2>&1 

echo -e "APACHE IS RUNNING ON PORT     : ` netstat -nelpt | grep httpd | awk -F ' ' '{print $4}' | awk -F ':::' '{print $2}'| sed 's/^$/bla/'|sed -e :a -e '{N; s/\n/,/g; ta}'`" >> $FILE_PATH/SOS.txt 2>&1

NFS=`service  nfs status  | grep Active | awk -F':' '{ print $2}'|awk '{$1=$1};1'`
if [[ "$(echo "$NFS" | tr '[:upper:]' '[:lower:]')" == *"inactive"* ]] ;then
echo -e "NFS STATUS                    : NFS NOT RUNNING" >> $FILE_PATH/SOS.txt 2>&1
else
echo -e ""NFS STATUS                   : NFS RUNNING"" >> $FILE_PATH/SOS.txt 2>&1
 fi
echo -e "PHP/PHP-FPM Version           : `rpm -qa php | grep php-5 |  cut -d '-' -f 2,3`" >> $FILE_PATH/SOS.txt 2>&1
echo -e "PHP/PHP-FPM PORT              : `netstat -nelpt | grep php | awk '{print $4}' | cut -d : -f 2`" >> $FILE_PATH/SOS.txt 2>&1
echo -e "RUNNING APPLICATION TOMCAT    : `ps -ewf | awk -F"home" '/logging/{print $2}' | cut -d '=' -f2 | awk '{print $1}' | grep -v logging|  sed  's/\/eOffice\/JApps\/Tomcat\///g'| sed -e :a -e '{N; s/\n/,/g; ta}'`" >> $FILE_PATH/SOS.txt 2>&1


echo -e "WKHTML                        : `ls -lrth /usr/local/bin/wkhtmltopdf* | awk '{print $9}' | cut -d / -f 5 | sed -e :a -e '{N; s/\n/,/g; ta}'`" >> $FILE_PATH/SOS.txt 2>&1
echo -e "Open Office                   : `ls -lrth /opt/ | grep openoffice* | awk '{print $9}' | sed -e :a -e '{N; s/\n/,/g; ta}'`" >> $FILE_PATH/SOS.txt 2>&1
echo -e "Libre Office                  : `ls -lrth /opt/ | grep libreoffice* | awk '{print $9}' | sed -e :a -e '{N; s/\n/,/g; ta}'`" >> $FILE_PATH/SOS.txt 2>&1
echo -e "FONTS DIRECTORIES             : `(ls -lrth /usr/share/fonts | grep truetype  | awk '{print $9}' ; ls -lrth /usr/share/fonts | grep ttf | awk '{print $9}') | sed -e :a -e '{N; s/\n/,/g; ta}'`" >> $FILE_PATH/SOS.txt 2>&1



`for i in $(ps -ewf | grep java | awk -F '=' '{print $2}' | awk -F 'conf' '{print $1}'  | grep -v auto) ; do sh  $i/bin/version.sh >> $FILE_PATH/all_tomcat_version.txt ; done`
sed -i '/Using CATALINA_BASE/ i "******************************************************************************************************************************"'  $FILE_PATH/all_tomcat_version.txt 
echo -e " \n "  >> $FILE_PATH/SOS.txt 2>&1


echo -e "EMD_Version                   : `grep -ri "application.version" /eOffice/JApps/APPS/EMD/war-deploy/EMD*/WEB-INF/classes/project-version.properties | tail -1 | awk '{print $1}' | cut -d = -f 2 | tr -d $'\r'`" >> $FILE_PATH/SOS.txt 2>&1
echo -e "EFILE_Version                 : `grep -ri "Version :" /eOffice/JApps/APPS/EFILE/war-deploy/eFile*/WEB-INF/pages/efile/panels/home/EFileVersionPanel.html | tail -1 | awk '{print $3}' | sed  's/<\/div>//g'| cut -d : -f 2 | tr -d $'\r'`" >> $FILE_PATH/SOS.txt 2>&1
echo -e "MIS_Version                   : `grep -ri "Version :" /eOffice/JApps/APPS/MIS/war-deploy/MIS*/pages/eFileMISVersion.html | awk -F'Version :' '{print $2}'| tr -d $'\r' `" >> $FILE_PATH/SOS.txt 2>&1
echo -e "MDM_Version                   : `grep -ri "application.version" /eOffice/JApps/APPS/EMD/war-deploy/EMD*/WEB-INF/classes/project-version.properties | tail -1 | awk '{print $1}' | cut -d = -f 2 | tr -d $'\r'`" >> $FILE_PATH/SOS.txt 2>&1
ELEAVE=/eOffice_JApps/Tomcat/ELEAVE

if [ -d "$ELEAVE" ]; then

echo -e "ELEAVE_Version                : `grep -ri "application.version" /eOffice/JApps/APPS/EMD/war-deploy/EMD*/WEB-INF/classes/project-version.properties | tail -1 | awk '{print $1}' | cut -d = -f 2 | tr -d $'\r'`" >> $FILE_PATH/SOS.txt 2>&1
else
echo -e "ELEAVE_Version                : Lite Version"  >> $FILE_PATH/SOS.txt 2>&1
fi
echo -e "PORTAL_Version                : `grep -ri Version /eOffice/eofficev6/Portal/portal_footer_portlet.php | awk '{print $2}' `" >> $FILE_PATH/SOS.txt 2>&1
echo -e "KMS_Version                   :`grep -ri "define('VER" /eOffice/eofficev6/kms-v6/app/Config/core.php |   awk -F',' '{print $2}' | awk -F';' '{print $1}' | awk -F')' '{print $1}'  | tr -d "'" `" >> $FILE_PATH/SOS.txt 2>&1



open=`ls -lrth /opt/ | grep openoffice* | awk '{print $9}' | sed -e :a -e '{N; s/\n/ /g; ta}'`
libr=`ls -lrth /opt/ | grep libreoffice* | awk '{print $9}' | sed -e :a -e '{N; s/\n/ /g; ta}'`

arr=($open)
for  i in "${arr[@]}"
do 
grep -ri "$i"  /eOffice/JApps/Tomcat/*/conf/context.xml >> $FILE_PATH/openliberoffice.txt
grep -ri "$i"  /eOffice/JApps/APPS/*/war-deploy/ >> $FILE_PATH/openliberoffice.txt
done


arr=($libr)
for  h in "${arr[@]}"
do 
grep -ri "$h"  /eOffice/JApps/Tomcat/*/conf/context.xml >> $FILE_PATH/openliberoffice.txt
grep -ri "$h"  /eOffice/JApps/APPS/*/war-deploy/  >> $FILE_PATH/openliberoffice.txt
done

echo -e " \n "  >> $FILE_PATH/SOS.txt 2>&1

sleep 1

#done
#done

running=` ps -ewf | grep java | awk -F '=' '{print $2}' | awk -F 'conf' '{print $1}'  | grep -v auto  | sed -e :a -e '{N; s/\n/ /g; ta}'`

arr=($running)
for g in "${arr[@]}"
do
i=`echo $g | awk -F '/' '{print $5}'`
        if [[ "$i" ==  "EFILE-LB1" || "$i" == "MIS" || "$i" == "EFILE-LB2" || "$i" == "EFILE-LB3"  || "$i" == "EFILE-LB4" || "$i" == "EFILE-LB5"    ]];
        then
                appbase=`grep -ri "Appbase" /eOffice/JApps/Tomcat/$i/conf/server.xml | awk -F '=' '{print $3}' | tr -d '"'`
                cp -rf $appbase/*/META-INF/context.xml $FILE_PATH/${i}_context.xml
        else
                cp -rf $g/conf/context.xml $FILE_PATH/${i}_context.xml
        fi
done

running=` ps -ewf | grep java | awk -F '=' '{print $2}' | awk -F 'conf' '{print $1}'  | grep -v auto  | sed -e :a -e '{N; s/\n/ /g; ta}'`
arr=($running)
for g in "${arr[@]}"
do
i=` echo $g | awk -F '/' '{print $5}'`


if [[ -f $g/logs/catalina.out  &&  -f $g/logs/localhost.$date1.log ]] ; then
              cp -rf $g/logs/localhost.$date1.log $FILE_PATH/${i}_localhost.out
              cp -rf $g/logs/catalina.out $FILE_PATH/${i}_catalina.out

        elif [  -f $g/logs/localhost.$date1.log  ]; then
                cp -rf $g/logs/localhost.$date1.log $FILE_PATH/${i}_localhost.out


        elif [  -f $g/logs/catalina.out  ]; then
                cp -rf $g/logs/catalina.out $FILE_PATH/${i}_catalina.out
else
echo -e "  LOG STATUS                          : ${i}_LOG file DOESNT exist"    >> $FILE_PATH/LOG_STATUS.log
fi

done 
cp -rf /var/log/messages $FILE_PATH/system.log 
cp -rf /var/log/httpd/access_log  $FILE_PATH/apache_access.log
cp -rf /var/log/httpd/error_log $FILE_PATH/apache_error.log
cp -rf  /eOffice/eofficev6/kms-v6/app/tmp/logs/error.log $FILE_PATH/php_error.log
cp -rf  /eOffice/eofficev6/kms-v6/app/tmp/logs/debug.log $FILE_PATH/php_debug.log

cp -rf /etc/httpd/conf/httpd.conf $FILE_PATH/.
cp -rf /etc/php-fpm.d/www.conf $FILE_PATH/. 
cp -rf /eOffice/JApps/APPS/EFILE/war-deploy/eFile/WEB-INF/web.xml $FILE_PATH/.
cp -rf  /eOffice/eofficev6/connection/config.php $FILE_PATH/.
cp -rf /var/spool/cron/eoffice $FILE_PATH/.
cp -rf /var/spool/cron/root  $FILE_PATH/.
cp -rf /var/log/secure $FILE_PATH/secure.log
cp -rf /etc/fstab $FILE_PATH/secure.log
cp -rf /var/log/sa/sa$TDATE $FILE_PATH/.
cp -rf  /var/log/sa/sa$YDATE  $FILE_PATH/.

ping -c 30 dbserver >>  $FILE_PATH/ping.txt


mv $FILE_PATH/*.log $FILE_PATH/LOG/.
mv $FILE_PATH/*.out $FILE_PATH/LOG/.
mv $FILE_PATH/*.conf $FILE_PATH/CONF/.
mv $FILE_PATH/*.xml $FILE_PATH/CONTEXT/.
mv $FILE_PATH/config.php  $FILE_PATH/CONNECTION/.
mv $FILE_PATH/eoffice $FILE_PATH/CRONS/.
mv $FILE_PATH/root $FILE_PATH/CRONS/.
mv $FILE_PATH/sa* $FILE_PATH/SAR/.
mv $FILE_PATH/all_tomcat_version.txt $FILE_PATH/openliberoffice.txt $FILE_PATH/ping.txt  $FILE_PATH/SERVICE/.
rm -f /Uploads/test1.img

sitename=`cat /eOffice/eofficev6/connection/config.php  | grep url | head -1 | cut -d ';' -f 1 | cut -d ',' -f 2 | cut -d '"' -f 2 | cut -d '.' -f 1`

rm -f /Uploads/test1.img

tar -cvpzf /eOffice/SOS_APP_REPORT_"$sitename"_"$date1".tar.gz  -C $FILE_PATH .

rm -rf $FILE_PATH/*


