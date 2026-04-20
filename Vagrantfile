Vagrant.configure("2") do |config|

  # --- VM 1: PostgreSQL-node ---
  config.vm.define "pg_node" do |pg|

    # Host name
    pg.vm.hostname = "pg-node" # Display at promt
    
    # Use Image Ubuntu 24.04
    pg.vm.box = "bento/ubuntu-24.04"
    
    # Network configure
    pg.vm.network "private_network", ip: "192.168.240.10"
    
    # Hardware configuration
    pg.vm.provider "vmware_desktop" do |v|
      v.vmx["displayname"] = "Bench-PostgreSQL-Node" # Display in VMware
      v.gui = true
      v.cpus = 2
      v.memory = 16384 # 16 GB

    end

    # Run this script after VM creation
    pg.vm.provision "shell", path: "./scripts/setup-pg.sh"

  end

  # --- VM 2: Client-node ---
  config.vm.define "client_node" do |client|

    # Host name
    client.vm.hostname = "client-node" # Display at promt

    # Use Image Ubuntu 24.04
    client.vm.box = "bento/ubuntu-24.04"

    # Network configure
    client.vm.network "private_network", ip: "192.168.240.20"
    
    # Hardware configuration
    client.vm.provider "vmware_desktop" do |v|
      v.vmx["displayname"] = "Bench-Client-Node" # Display in VMware
      v.gui = true
      v.cpus = 2     
      v.memory = 8192 # 8 GB
    end

    # Run this script after VM creation
    client.vm.provision "shell", path: "./scripts/setup-client.sh"
  end

  # --- VM 3-5: CockroachDB 3-Node Cluster ---
  (1..3).each do |i|
    config.vm.define "ckdb_node_#{i}" do |node|

      # Host name
      node.vm.hostname = "ckdb-node-#{i}" # Display at promt

      # Use Image Ubuntu 24.04
      node.vm.box = "bento/ubuntu-24.04"

      # Network configure
      node.vm.network "private_network", ip: "192.168.240.3#{i}"

      # Hardware configuration
      node.vm.provider "vmware_desktop" do |v|
        v.vmx["displayname"] = "Bench-CockroachDB-Node-#{i}"
        v.gui = true
        v.cpus = 2
        v.memory = 8192 # 8GB total 24GB for Cluster
      end

      # Run this script after VM creation
      node.vm.provision "shell", path: "./scripts/setup-ckdb.sh", env: {"NODE_ID" => i}
    end

  end

end