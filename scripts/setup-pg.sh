#!/bin/bash

# 1. Update & Upgrade
export DEBIAN_FRONTEND=noninteractive
sudo apt update && sudo apt upgrade -y

# 2. Install Tools & PostgreSQL
sudo apt install htop iotop sysstat postgresql postgresql-contrib -y

# 3. Configure postgresql.conf, allow outside connection
PG_VERSION=$(psql -V | egrep -o '[0-9]{1,2}' | head -1)
CONF_FILE="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
HBA_FILE="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" $CONF_FILE

# 4. Configure pg_hba.conf, allow the client node to connect
echo "host    all             all             192.168.240.20/32            md5" | sudo tee -a $HBA_FILE

# 5. Restart PostgreSQL
sudo systemctl restart postgresql

# 6. Create Database, User, and permissions (SQL)
sudo -u postgres psql <<EOF
CREATE USER admin WITH PASSWORD '1234';
CREATE DATABASE tpcc;
GRANT ALL PRIVILEGES ON DATABASE tpcc TO admin;
ALTER USER admin WITH CREATEDB;
ALTER DATABASE tpcc OWNER TO admin;
\c tpcc
GRANT ALL ON SCHEMA public TO admin;
EOF

echo "PostgreSQL Setup Completed!"