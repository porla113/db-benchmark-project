Vagrant.configure("2") do |config|

    # --- VM 1: PostgreSQL-node ---
    config.vm.define "pg_node" do |pg|
    
    # Use Image Ubuntu 24.04
    pg.vm.box = "bento/ubuntu-24.04"
    
    # Network configure
    pg.vm.network "private_network", ip: "192.168.240.10"
    
    # Hardware configuration
    pg.vm.provider "vmware_desktop" do |v|
      v.gui = false
      v.cpus = 2
      v.memory = 16384 

    end

    # Run this script after VM creation
    pg.vm.provision "shell", path: "./scripts/setup_pg.sh"

  end

  # --- VM 2: Client-node ---
  config.vm.define "client_node" do |client|
    client.vm.box = "bento/ubuntu-24.04"
    client.vm.network "private_network", ip: "192.168.240.20"
    
    client.vm.provider "vmware_desktop" do |v|
      v.gui = false
      v.cpus = 2     
      v.memory = 8192
    end

    # Run this script after VM creation
    client.vm.provision "shell", path: "./scripts/setup_client.sh"
  end

end