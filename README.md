# DB Benchmark Project

## Overview
Setup an virtual environment for benchmarking PostgreSQL and CockroachDB with Benchbase (Multi-DBMS SQL Benchmarking Framework via JDBC).

- This will setup five VMs (client, PostgreSQL server, and three CockroachDB servers).
- Benchbase and its dependencies are setup and built on the client (client node) ready to run a test.
- PostgreSQL server (pg_node) will have PostgreSQL installed and configured.

## Tools
Install these tools and verify that they are working. Download links and setup please see [Links](#links) section.
- VMware Workstation Pro 25H2 (version 25.0.0.24995812)
- Vagrant (2.4.9)
  - vagrant-vmware-desktop (3.0.5, global)
  - vagrant-vmware-utility (1.0.21)
- Python (3.14.4)
  - This is optional, only if you want to do data plotting with Python

## Setup
- Clone the repository.
- Modify virtual machines specification in Vagrantfile, setup-pg.sh, and setup-client.sh and save before proceeding.
- In project folder, run  
`vagrant up`
- Five VMs will be created.

| VM | IP |
| --- | --- |
| client_node | 192.168.240.20 |
| pg_node | 192.168.240.10 |
| cr_node_1 | 192.168.240.31 |
| cr_node_2 | 192.168.240.32 |
| cr_node_3 | 192.168.240.33 |

- To close all VMs run  
`vagrant halt`

## Tips
- For resources efficiency run each environment separately.
  - Run PostgreSQL environment
    - Run  
`vagrant up pg_node client_node`
  - Run CockroachDB environment
    - Run  
`vagrant up cr_node_1 cr_node_2 cr_node_3 client_node`
  - Stop unused nodes ex.
    - To stop the pg_node run  
`vagrant halt pg_node`
- To visualize the result with Python
  - Install

## Run Test
- **PostgreSQL**
  - `vagrant up pg_node client_node`
  - SSH to client_node  
`vagrant ssh client_node`
  - At the client_node
    - `cd benchbase-run/`
    - Modify (if needed) the config file (config/postgres/sample_tpcc_config.xml) ex. scalefactor, terminals. Save.
    - Create/initialize the database  
    `java -jar benchbase.jar -b tpcc -c config/postgres/sample_tpcc_config.xml --create=true`
    - Load data to PostgreSQL server.  
    `java -jar benchbase.jar -b tpcc -c config/postgres/sample_tpcc_config.xml --load=true`
    - Or create and load at the same time  
    `java -jar benchbase.jar -b tpcc -c config/postgres/sample_tpcc_config.xml --create=true --load=true`
    - After loading is done, if you are going to stick with this data, my advise is to shutdown the PostgreSQL server (pg_node) and make a VM snapshot.
    - Execute the benchmaek workload. Note that the result location can be modify in the command, now set to "/vagrant/results/first_test".  
`java -jar benchbase.jar -b tpcc -c config/postgres/sample_tpcc_config.xml --execute=true -d /vagrant/results/first_test`
  - At Host
    - The results will be saved in results folder.
    - Plotting graph (optional)
      - Make sure Python virtual environment and required packages are setup, please see [Python venv and packages](#python-venv-and-packages).
      - Activate Python virtual environment  
`.venv\Scripts\activate `
      - 

## Links
- Download **VMware**
  - https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion
- Download **Vagrant (2.4.9)**
  - https://developer.hashicorp.com/vagrant/install
- Install **vagrant-vmware-desktop (3.0.5, global)**
  - After installed Vagrant run  
`vagrant plugin install vagrant-vmware-desktop`
- Download an installer of **vagrant-vmware-utility (1.0.21)**
  - https://releases.hashicorp.com/vagrant-vmware-utility/1.0.21/vagrant-vmware-utility_1.0.21_x86_64.msi
- **Benchbase** github page
  - https://github.com/cmu-db/benchbase

## Other Setups
### Python venv and packages
- Go to analysis folder  
`cd .\analysis\`
- Create Python virtual environment  
`python -m venv .venv`
- Activate venv  
`.venv\Scripts\activate` 
- Install packages  
`pip install -r requirements.txt`