#!/bin/bash

# 1. Install Basic Tools
export DEBIAN_FRONTEND=noninteractive

# Package list Java 23, Maven, Git, and monitor tools
PACKAGES=(htop iotop sysstat wget netcat-openbsd)
TO_INSTALL=()

# Check installed packages
for pkg in "${PACKAGES[@]}"; do
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

# 2. Install CockroachDB Binary
CK_INSTALL_PATH="/usr/local/bin/cockroach"

if [ ! -f "$CK_INSTALL_PATH" ]; then
    echo "Installing CockroachDB binary..."
    wget -qO- https://binaries.cockroachdb.com/cockroach-v25.4.8.linux-amd64.tgz | tar xvz
    sudo cp -i cockroach-v25.4.8.linux-amd64/cockroach /usr/local/bin/
    rm -rf cockroach-v25.4.8.linux-amd64
fi

# 3. Create Data Directory
if [ ! -d "/home/vagrant/ckdb_data" ]; then
    # 3. Create Data Directory
    sudo mkdir -p /home/vagrant/ckdb_data
    sudo chown -R vagrant:vagrant /home/vagrant/ckdb_data
fi

# 4. Create and start CockroachDB service (start at boot)

MY_IP="192.168.240.3${NODE_ID}"    # Use NODE_ID from Vagrantfile to set its own IP
CK_SERV_FILE="/etc/systemd/system/cockroach.service"

if [ ! -f "$CK_SERV_FILE" ]; then
  # Create a service for systemd
  sudo tee $CK_SERV_FILE <<EOF
[Unit]
Description=CockroachDB
# Wait for network online
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
User=vagrant
# Delay 10 seconds
ExecStartPre=/bin/sleep 10
ExecStart=/usr/local/bin/cockroach start --insecure --store=/home/vagrant/ckdb_data --listen-addr=${MY_IP}:26257 --http-addr=${MY_IP}:8080 --join=192.168.240.31:26257,192.168.240.32:26257,192.168.240.33:26257 --cache=25% --max-sql-memory=25%
# Delay restart 10 seconds
Restart=always
RestartSec=10
# Disable the limit
StartLimitIntervalSec=0

[Install]
WantedBy=multi-user.target
EOF

  # Enable and start the service
  sudo systemctl daemon-reload
  sudo systemctl enable cockroach

  if pgrep -x "cockroach" > /dev/null; then
      sudo pkill -9 cockroach
      sleep 2
  fi
  
  sudo systemctl start cockroach
fi

# 5. Initialize cluster (only node_3 do trigger)

if [ "$NODE_ID" == "3" ]; then

  sleep 5

  # Cluster is already initialized?
  if ! cockroach node status --insecure --host=192.168.240.31 > /dev/null 2>&1; then

    echo "Node 3: Checking neighbors (Node 1 & 2)..."

    # Node 1 and 2
    NODES=("192.168.240.31" "192.168.240.32")
    
    for NODE_IP in "${NODES[@]}"; do
      echo "Checking connection to $NODE_IP..."

      # Loop until successfully connect to port 26257
      while ! nc -z $NODE_IP 26257; do
        echo "Waiting for $NODE_IP ..."
        sleep 5
      done

      echo "Connection to $NODE_IP established!"

    done
      
    # When all nodes are online, initialize cluser via node_1
    echo "All nodes are online. Initializing cluster..."
    cockroach init --insecure --host=192.168.240.31:26257

    # Wait for Cluster ready to recieve SQL
    sleep 10
    echo "Creating tpcc database..."
    cockroach sql --insecure --host=192.168.240.31:26257 --execute="CREATE DATABASE tpcc;"

    echo "CockroachDB Cluster is fully operational!"
    
  else
    echo "Cluster is already initialized."
  fi
fi
    
