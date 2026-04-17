#!/bin/bash

# 1. Install Basic Tools
export DEBIAN_FRONTEND=noninteractive
sudo apt update && sudo apt upgrade -y
sudo apt install -y htop iotop sysstat wget netcat-openbsd

# 2. Install CockroachDB Binary
wget -qO- https://binaries.cockroachdb.com/cockroach-v25.4.8.linux-amd64.tgz | tar xvz
sudo cp -i cockroach-v25.4.8.linux-amd64/cockroach /usr/local/bin/

# 3. Create Data Directory
mkdir -p /home/vagrant/ckdb_data

# Start CockroachDB Node
# Use NODE_ID from Vagrantfile to set its own IP
MY_IP="192.168.240.3${NODE_ID}"

nohup cockroach start \
  --insecure \
  --store=/home/vagrant/ckdb_data \
  --listen-addr=${MY_IP}:26257 \
  --http-addr=${MY_IP}:8080 \
  --join=192.168.240.31:26257,192.168.240.32:26257,192.168.240.33:26257 \
  --cache=25% \
  --max-sql-memory=25% \
  --background

# Only node 1 initializes cluster
if [ "$NODE_ID" == "1" ]; then
  echo "Node 1: Waiting for all nodes to start their engines..."
  
  # IP addresses in the cluster
  NODES=("192.168.240.32" "192.168.240.33")
  
  for NODE_IP in "${NODES[@]}"; do
    echo "Checking connection to $NODE_IP..."
    # Loop until successfully connect to port 26257
    while ! nc -z $NODE_IP 26257; do
      echo "Still waiting for $NODE_IP to be ready..."
      sleep 4
    done
    echo "Connection to $NODE_IP established!"
  done

  # When all nodes are online
  echo "All nodes are online. Initializing cluster..."
  cockroach init --insecure --host=192.168.240.31:26257
  
  # รอให้ Cluster พร้อมรับคำสั่ง SQL
  sleep 5
  echo "Creating tpcc database..."
  cockroach sql --insecure --host=192.168.240.31:26257 --execute="CREATE DATABASE tpcc;"
  
  echo "CockroachDB Cluster is fully operational!"
fi