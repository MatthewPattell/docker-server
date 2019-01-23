#!/bin/bash

cat << EOM > /etc/pure-ftpd/db/mysql.conf
MYSQLServer         $MYSQL_HOST
MYSQLPort           $MYSQL_PORT
MYSQLUser           $MYSQL_USER
MYSQLPassword       $MYSQL_PASSWORD
MYSQLDatabase       $MYSQL_DATABASE
MYSQLCrypt          md5
MYSQLGetPW          SELECT Password FROM $FTP_DB_TABLE_NAME WHERE User="\L" AND status="1" AND (ipaccess="*" OR ipaccess="\R")
MYSQLGetUID         SELECT Uid FROM $FTP_DB_TABLE_NAME WHERE User="\L" AND status="1" AND (ipaccess="*" OR ipaccess="\R")
MYSQLGetGID         SELECT Gid FROM $FTP_DB_TABLE_NAME WHERE User="\L" AND status="1" AND (ipaccess="*" OR ipaccess="\R")
MYSQLGetDir         SELECT Dir FROM $FTP_DB_TABLE_NAME WHERE User="\L" AND status="1" AND (ipaccess="*" OR ipaccess="\R")
MYSQLGetDir         SELECT CONCAT('/ftpdata/', Dir) FROM $FTP_DB_TABLE_NAME WHERE User="\L" AND status="1" AND (ipaccess="*" OR ipaccess="\R")
MySQLGetQTAFS       SELECT QuotaFiles FROM $FTP_DB_TABLE_NAME WHERE User="\L" AND status="1" AND (ipaccess="*" OR ipaccess="\R")
MySQLGetQTASZ       SELECT QuotaSize FROM $FTP_DB_TABLE_NAME WHERE User="\L" AND status="1" AND (ipaccess="*" OR ipaccess="\R")
MySQLGetBandwidthUL SELECT ULBandwidth FROM $FTP_DB_TABLE_NAME WHERE User="\L" AND status="1" AND (ipaccess="*" OR ipaccess="\R")
MySQLGetBandwidthDL SELECT DLBandwidth FROM $FTP_DB_TABLE_NAME WHERE User="\L" AND status="1" AND (ipaccess="*" OR ipaccess="\R")
EOM

# for options see: http://go2linux.garron.me/linux/2010/05/how-install-secure-pure-ftp-server-chrooted-virtual-users-743/
echo ",21" > /etc/pure-ftpd/conf/Bind
echo "yes" > /etc/pure-ftpd/conf/ChrootEveryone
echo "yes" > /etc/pure-ftpd/conf/CreateHomeDir
echo "yes" > /etc/pure-ftpd/conf/DontResolve
echo "no" > /etc/pure-ftpd/conf/PAMAuthentication
echo "no" > /etc/pure-ftpd/conf/UnixAuthentication
echo "30000 30009" > /etc/pure-ftpd/conf/PassivePortRange
echo "yes" > /etc/pure-ftpd/conf/VerboseLog
echo "yes" > /etc/pure-ftpd/conf/BrokenClientsCompatibility
# If you want to allow FTP and TLS sessions, run
echo 1 > /etc/pure-ftpd/conf/TLS
echo 10 > /etc/pure-ftpd/conf/MaxIdleTime
echo "yes" > /etc/pure-ftpd/conf/IPV4Only

openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem -subj "/C=${SUBJ_C}/ST=/L=${SUBJ_L}/O=${SUBJ_O}/OU=/CN=${SUBJ_CN}"
chmod 600 /etc/ssl/private/pure-ftpd.pem

chown -R ftpuser:ftpgroup /ftpdata
service pure-ftpd-mysql restart && tail -f /var/log/*.log
