#!/bin/bash
# encoding: UTF-8
set -e

DATADIR="/var/lib/mysql"
IP_ADDRESS=$(hostname -i | awk ' { print $1 } ')
MYSQL_ROOT_PASSWORD="docker"
MYSQL_ADMIN_PASSWORD="d0ck3r"
MYSQL_MONITOR_PASSWORD="monitor"
XTRABACKUP_PASSWORD="backup"
SST_PASSWORD="s3cret"

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
  CMDARG="$@"
fi

if [ ! -e "$DATADIR/mysql" ]; then
  echo "MySQL initialize insecure mode..."
  mkdir -p "$DATADIR"
  mysqld --initialize-insecure
  chown -R mysql:mysql "$DATADIR"
  chown mysql:mysql /var/log/mysqld.log

  mysqld --user=mysql --datadir="$DATADIR" --skip-networking &
  pid="$!"

  mysql=( mysql --protocol=socket -uroot )

  for i in {30..0}; do
    if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
      break
    fi
    echo 'MySQL init process in progress...'
    sleep 1
  done

  echo 'MySQL populating the Time Zone Tables...'
  mysql_tzinfo_to_sql /usr/share/zoneinfo | "${mysql[@]}" -f mysql > /dev/null 2>&1

  echo 'MySQL configure users privileges...'
"${mysql[@]}" <<-EOSQL
  SET @@SESSION.SQL_LOG_BIN=0;
  SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ROOT_PASSWORD}');
  GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
  ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
  GRANT ALL ON *.* TO 'admin'@'%' WITH GRANT OPTION;
  ALTER USER 'admin'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}';
  CREATE USER 'xtrabackup'@'localhost' IDENTIFIED BY '${XTRABACKUP_PASSWORD}';
  GRANT RELOAD,PROCESS,LOCK TABLES,REPLICATION CLIENT ON *.* TO 'xtrabackup'@'localhost';
  GRANT REPLICATION CLIENT ON *.* TO monitor@'localhost' IDENTIFIED BY '${MYSQL_MONITOR_PASSWORD}';
  GRANT PROCESS ON *.* TO monitor@localhost IDENTIFIED BY 'monitor';
  CREATE USER 'sstuser'@'localhost' IDENTIFIED BY '${SST_PASSWORD}';
  GRANT PROCESS, RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'sstuser'@'localhost';
  DROP DATABASE IF EXISTS test;
  FLUSH PRIVILEGES;
EOSQL

  if ! kill -s TERM "$pid" || ! wait "$pid"; then
    echo >&2 'MySQL stopping process failed.'
    exit 1
  fi

  echo 'MySQL init process done. Ready for start up.'
fi

chown -R mysql:mysql "$DATADIR"

exec mysqld --user=mysql \
            --wsrep_node_address="${IP_ADDRESS}" \
            $CMDARG
