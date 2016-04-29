#!/bin/bash

# upgrades a 4.6.x node to 4.8.x install using the DataStax community AMI

NEW_YAML=~/cassandra.yaml_48
DEFAULT_YAML_LOCATION=/etc/dse/cassandra/cassandra.yaml
BACKUP_DIR=/etc/dse/cassandra/_backup_46

# backup current configuration
cp $DEFAULT_YAML_LOCATION $NEW_YAML
mkdir $BACKUP_DIR
cp /etc/dse/cassandra/* $BACKUP_DIR

# comment out deprecated settings from 4.6 cassandra.yaml file
sed -i -e "s/multithreaded_compaction: \(.*\)/# multithreaded_compaction: \1/g" $NEW_YAML
sed -i -e "s/memtable_flush_queue_size: \(.*\)/# memtable_flush_queue_size: \1/g" $NEW_YAML
sed -i -e "s/compaction_preheat_key_cache: \(.*\)/# compaction_preheat_key_cache: \1/g" $NEW_YAML
sed -i -e "s/in_memory_compaction_limit_in_mb: \(.*\)/# in_memory_compaction_limit_in_mb: \1/g" $NEW_YAML
sed -i -e "s/preheat_kernel_page_cache: \(.*\)/# preheat_kernel_page_cache: \1/g" $NEW_YAML

# update broadcast rpc value
sed -i -e "s/broadcast_address: \(.*\)/broadcast_rpc_address: \1/g" $NEW_YAML

# update java to version 8
add-apt-repository ppa:webupd8team/java -y
aptitude update -y
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
aptitude install oracle-java8-installer -y

#verify version
java -version
update-java-alternatives -s java-8-oracle
java -version

#remove v7
aptitude remove oracle-java7-installer oracle-java7-set-default -y

# shutdown dse service cleanly
nodetool flush
nodetool drain
service dse stop

# upgrade dse using .deb and aptitude
aptitude upgrade dse-full -y

#copy 4.8 yaml back to original location
cp $NEW_YAML $DEFAULT_YAML_LOCATION

#force ownership of directory
chown -R cassandra:cassandra /mnt/cassandra


# remaining manual steps
# 1. verify everything done above looks good
# 2. start dse service: service dse start
# 3. check node is back online and seen by other nodes: nodetool status
# 4. upgrade the existing sstables: nodetool upgradesstables
# 5. Review logs to ensure all went well
