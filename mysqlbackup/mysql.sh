#!/bin/bash

path="/opt/.mysqlbackup"

#vari
DATE_TIME=`date +%Y%m%d`
BACKUPFOLDER="database_backup"
YESTDAYBACKUP=`date -d '1 days ago' +%Y%m%d`
DB_HOSTNAME="10.51.28.212"
DB_USERNAME="xxxx"
DB_PASSWORD="xxxx"
DATABASES_NAME=(mytijian_prod)

DB_ROOTNAME="xxxx"
DB_ROOTPASSWORD="xxxx"
DB_RESTOREHOSTNAME="localhost"


#backup function
backup_mysql(){
	echo "begin backup mysql ..........."	
	/usr/bin/mysqldump -u"$DB_USERNAME" -p"$DB_PASSWORD" -h "$DB_HOSTNAME" -R $1>$path/"$BACKUPFOLDER"_"$DATE_TIME"/"$1"_"$DATE_TIME".sql
	echo "end backup mysql ............."	
}

function restore_mysql(){
	echo "begin restore mysql ..........."	
  	#/usr/bin/mysql -u"$DB_USERNAME" -h "$DB_HOSTNAME" $1 < $path/$BACKUPFOLDER"_"$DATE_TIME/$1"_"$DATE_TIME.sql
  	/usr/bin/mysql -u"$DB_ROOTNAME" -p"$DB_ROOTPASSWORD" -h "$DB_RESTOREHOSTNAME" $1 < $path/$BACKUPFOLDER"_"$DATE_TIME/$1_"$DATE_TIME".sql
  	#/usr/bin/mysql -u"$DB_ROOTNAME" -p"$DB_ROOTPASSWORD" -h "$DB_RESTOREHOSTNAME" mmtest < $path/$BACKUPFOLDER"_"$DATE_TIME/$1_"$DATE_TIME".sql
	echo "end restore mysql ............."	
}

#还原时数据库数据清理
Mysql_Data_Update() {
  echo "clear data....."
  cat $path/sql.ini | while read i
  do
          mysql -u$DB_ROOTNAME -p$DB_ROOTPASSWORD -e "$i"
  done
}

decide(){

	if [ $1 = 0 ] ;then
		echo "$path/$BACKUPFOLDER'_'$DATE_TIME/$2'_'$DATE_TIME.sql mysqldump ok!" | mail -s "$2 Aliyun DB BK OK! $DATE_TIME" liujunming@mytijian.com
	else
		echo "$path/$BACKUPFOLDER'_'$DATE_TIME/$2'_'$DATE_TIME.sql mysqldump failed" | mail -s "$2 Aliyun DB BK Faild! $DATE_TIME" liujunming@mytijian.com
	fi
}

Tar_Gz(){
	cd $path
	if [ -d "$BACKUPFOLDER"_"$YESTDAYBACKUP" ];then
		tar -zcvf "$BACKUPFOLDER"_"$YESTDAYBACKUP".tgz "$BACKUPFOLDER"_"$DATE_TIME"
		rm -rf "$BACKUPFOLDER"_"$YESTDAYBACKUP"
	fi
}

Tar_Gz_Today(){
        cd $path
        if [ -d "$BACKUPFOLDER"_"$DATE_TIME" ];then
                tar -zcvf "$BACKUPFOLDER"_"$DATE_TIME".tgz "$BACKUPFOLDER"_"$DATE_TIME"
                rm -rf "$BACKUPFOLDER"_"$YESTDAYBACKUP"
        fi
}

BACKUP_MYSQL(){
	for i in ${DATABASES_NAME[*]}
	do
		backup_mysql $i
		decide $? $i
	done
}

RESTORE_MYSQL(){
	for i in ${DATABASES_NAME[*]}
	do
  		restore_mysql $i
  		decide $? $i
	done
}
Create_Directory() {
if [ ! -d $path/"$BACKUPFOLDER"_"$DATE_TIME" ];then
	mkdir -p $path/"$BACKUPFOLDER"_"$DATE_TIME"
else
	rm -rf $path/"$BACKUPFOLDER"_"$DATE_TIME"/tmp
	mkdir -p $path/"$BACKUPFOLDER"_"$DATE_TIME"/tmp
	mv $path/"$BACKUPFOLDER"_"$DATE_TIME"/*.sql $path/"$BACKUPFOLDER"_"$DATE_TIME"/tmp/
fi
}

if [ X$1 = Xbackup ];then
	Create_Directory
	BACKUP_MYSQL
	Tar_Gz_Today
elif [ X$1 = Xrestore ];then
	RESTORE_MYSQL
	Mysql_Data_Update
else 
	echo "input error!!"
fi



