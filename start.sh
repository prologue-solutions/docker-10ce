#!/bin/bash

set -e


function insert_config() {

		echo db_host=$DB_PORT_5432_TCP_ADDR >> /etc/odoo/odoo.conf
		sub_db_port=(${DB_PORT_5432_TCP//:/ })
		db_port=${sub_db_port[2]}
		echo db_port=$db_port >> /etc/odoo/odoo.conf
		echo db_user=$odoo_db_user >> /etc/odoo/odoo.conf
		echo db_password=$odoo_db_pass >> /etc/odoo/odoo.conf
		echo $(date '+%d%m%Y_%H%M%S_%5N') >> /var/log/odoo/access.log
		echo odoo_id=$odoo_id >> /etc/odoo/odoo.conf
}

odoo_config=`[ -f /etc/odoo/odoo.conf ] && echo -n "TRUE" || echo -n "FALSE"`;
access_log=`[ -f /var/log/odoo/access.log ] && echo -n "TRUE" || echo -n "FALSE"`;
if [ "$DB_PORT_5432_TCP_ADDR" = "" ]
then
echo "No PostgreSQL database container linked, exiting!";
exit 0
fi
if [ "$access_log" = "FALSE" ]
then
		echo "Generating first Odoo Config.";
		odoo_id=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1);
		odoo_db_user=odoo${ODOO_VERSION::-2}_$(date '+%d%m%Y_%H%M%S_%5N'_$odoo_id);
		odoo_db_pass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1);
		REQ_PSQL=`PGPASSWORD=$DB_ENV_POSTGRES_PASSWORD psql -h $DB_PORT_5432_TCP_ADDR -U postgres -d template1 -c "create user $odoo_db_user with password '$odoo_db_pass';alter user $odoo_db_user createdb;"`;
		if [ "$REQ_PSQL" = "ALTER ROLE" ]
		then
				if [ "$odoo_config" = "TRUE" ]
				then
					mkdir /etc/odoo-backup-config
					cp /etc/odoo/odoo.conf /etc/odoo-backup-config/odoo.conf.$odoo_db_user.bak;

					sed -i '/^db_host/ d' /etc/odoo/odoo.conf
					sed -i '/^db_port/ d' /etc/odoo/odoo.conf
					sed -i '/^db_user/ d' /etc/odoo/odoo.conf
					sed -i '/^db_password/ d' /etc/odoo/odoo.conf
					sed -i '/^db_filter/ d' /etc/odoo/odoo.conf
					sed -i '/^\s*$/d' /etc/odoo/odoo.conf

					insert_config
					
				else
					
					echo [options] >> /etc/odoo/odoo.conf
					echo addons_path = /mnt/extra-addons,/usr/lib/python2.7/dist-packages/odoo/addons >> /etc/odoo/odoo.conf
					
					insert_config				
				
				fi
		else 
			echo "PostgreSQL database container :: postgres credentials missed or not working, exiting!";
			exit 0
		fi
fi
if [ "$odoo_config" = "TRUE" ]
then
		echo $(date '+%d_%m_%Y_%H_%M_%S_%5N') >> /var/log/odoo/access.log
		service lighttpd start && echo starting odoo && sudo -u odoo odoo -c /etc/odoo/odoo.conf
else
echo "Odoo config removed or missing, check  /etc/odoo/odoo.conf , exiting!";
exit 0
fi


