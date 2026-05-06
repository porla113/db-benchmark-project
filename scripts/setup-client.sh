#!/bin/bash

# 1. Update and install packages

# Package list Java 23, Maven, Git, and monitor tools
PACKAGES=(maven git htop iotop tmux sysstat postgresql-client)
TO_INSTALL=()

# Check installed packages
for pkg in "${PACKAGES[@]}"; do
    # dpkg-query -W will return 0 if package exists
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
        TO_INSTALL+=("$pkg")
    fi
done

if [ ${#TO_INSTALL[@]} -ne 0 ]; then
    echo "Installing missing packages: ${TO_INSTALL[*]}"
    sudo apt update
    sudo apt install -y "${TO_INSTALL[@]}"
else
    echo "All packages are already installed. Skipping..."
fi

# Install Java 23
JAVA_INSTALL_PATH="/usr/lib/jvm/jdk-23.0.2-oracle-x64"

if [ ! -d "$JAVA_INSTALL_PATH" ]; then
    echo "Java 23 not found. Starting installation..."

    # Download and Install Oracle JDK 23
    echo "Downloading Oracle JDK 23..."
    wget https://download.oracle.com/java/23/archive/jdk-23.0.2_linux-x64_bin.deb
    sudo dpkg -i jdk-23.0.2_linux-x64_bin.deb
    rm jdk-23.0.2_linux-x64_bin.deb

    # Add JAVA_HOME to /etc/environment
    if ! grep -q "JAVA_HOME" /etc/environment; then
        echo "JAVA_HOME=\"$JAVA_INSTALL_PATH\"" | sudo tee -a /etc/environment
    fi

    # Make Path available for current session and future session
    export JAVA_HOME="$JAVA_INSTALL_PATH"
    export PATH=$JAVA_HOME/bin:$PATH

    # Add JAVA_HOME to .bashrc of user vagrant
    if ! grep -q "JAVA_HOME" /home/vagrant/.bashrc; then
        echo "export JAVA_HOME=\"$JAVA_INSTALL_PATH\"" >> /home/vagrant/.bashrc
        echo "export PATH=$JAVA_HOME/bin:$PATH" >> /home/vagrant/.bashrc
    fi
else
    echo "Java 23 is already installed. Skipping..."
fi

# 2. Clone BenchBase
cd /home/vagrant

if [ ! -d "benchbase" ]; then
    git clone --depth 1 https://github.com/cmu-db/benchbase.git
    sudo chown -R vagrant:vagrant benchbase
fi

# --- Build & Config PostgreSQL ---
if [ ! -d "/home/vagrant/benchbase-run-pg" ]; then
    echo "Setting up BenchBase for PostgreSQL..."
    cd /home/vagrant/benchbase

    # Build BenchBase (for Postgres profile)
    ./mvnw clean package -P postgres

    # Extract Build
    mkdir -p /home/vagrant/benchbase-run-pg
    tar -xvzf target/benchbase-postgres.tgz -C /home/vagrant/benchbase-run-pg --strip-components=1

    # Change URL and password in config
    CONFIG_PG_FILE="/home/vagrant/benchbase-run-pg/config/postgres/sample_tpcc_config.xml"

    sed -i "s|<url>.*</url>|<url>jdbc:postgresql://192.168.240.10:5432/tpcc</url>|g" $CONFIG_PG_FILE
    sed -i "s|<password>.*</password>|<password>1234</password>|g" $CONFIG_PG_FILE
fi

# --- Build & Config CockroachDB ---
if [ ! -d "/home/vagrant/benchbase-run-ck" ]; then
    echo "Setting up BenchBase for CockroachDB..."
    cd /home/vagrant/benchbase
    
    # Build BenchBase (for Postgres profile)
    ./mvnw clean package -P cockroachdb

    # Extract Build
    mkdir -p /home/vagrant/benchbase-run-ck
    tar -xvzf target/benchbase-cockroachdb.tgz -C /home/vagrant/benchbase-run-ck --strip-components=1

    # Change URL and password in config
    CONFIG_CK_FILE="/home/vagrant/benchbase-run-ck/config/cockroachdb/sample_tpcc_config.xml"

    sed -i "s|<url>.*</url>|<url>jdbc:postgresql://192.168.240.31:26257/tpcc?sslmode=disable</url>|g" $CONFIG_CK_FILE
    sed -i "s|<username>.*</username>|<username>root</username>|g" $CONFIG_CK_FILE
    sed -i "s|<password>.*</password>|<password></password>|g" $CONFIG_CK_FILE
fi

# 3. Add permission for user vagrant
sudo chown -R vagrant:vagrant /home/vagrant/benchbase-run-*


echo "Client Node Setup Completed! BenchBase is ready in /home/vagrant/benchbase-run-pg and /home/vagrant/benchbase-run-ck"