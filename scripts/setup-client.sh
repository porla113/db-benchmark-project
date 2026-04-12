#!/bin/bash

# 1. Update
export DEBIAN_FRONTEND=noninteractive
sudo apt update && sudo apt upgrade -y

# 2. Install Java 23, Maven, Git และเครื่องมือ Monitor
sudo apt install -y maven git htop iotop sysstat postgresql-client

# Download และ Install Oracle JDK 23
echo "Downloading Oracle JDK 23..."
wget https://download.oracle.com/java/23/archive/jdk-23.0.2_linux-x64_bin.deb
sudo dpkg -i jdk-23.0.2_linux-x64_bin.deb
rm jdk-23.0.2_linux-x64_bin.deb

# Add JAVA_HOME to /etc/environment
echo 'JAVA_HOME="/usr/lib/jvm/jdk-23.0.2-oracle-x64"' | sudo tee -a /etc/environment

# Make Path available for current session and future session
export JAVA_HOME="/usr/lib/jvm/jdk-23.0.2-oracle-x64"
export PATH=$JAVA_HOME/bin:$PATH

# Add JAVA_HOME to .bashrc of user vagrant
echo 'export JAVA_HOME="/usr/lib/jvm/jdk-23.0.2-oracle-x64"' >> /home/vagrant/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /home/vagrant/.bashrc

# 3. Clone BenchBase
cd /home/vagrant
git clone --depth 1 https://github.com/cmu-db/benchbase.git
cd benchbase

# 4. Build BenchBase (for Postgres profile)
./mvnw clean package -P postgres

# 5. Extract Build
cd target
tar -xvzf benchbase-postgres.tgz


mv benchbase-postgres /home/vagrant/benchbase-run

# 6. Add permission for user vagrant
sudo chown -R vagrant:vagrant /home/vagrant/benchbase-run

# Change URL and password in config
CONFIG_FILE="/home/vagrant/benchbase-run/config/postgres/sample_tpcc_config.xml"

sed -i "s|<url>jdbc:postgresql://localhost:5432/benchbase?sslmode=disable&amp;ApplicationName=tpcc&amp;reWriteBatchedInserts=true</url>|<url>jdbc:postgresql://192.168.240.10:5432/tpcc</url>|g" $CONFIG_FILE
sed -i "s|<password>password</password>|<password>1234</password>|g" $CONFIG_FILE

echo "Client Node Setup Completed! BenchBase is ready in /home/vagrant/benchbase-run"