#!/bin/bash

# upgrades a 4.6.x node to 4.8.x install using the DataStax community AMI

NEW_YAML=~/cassandra.yaml_48
DEFAULT_YAML_LOCATION=/etc/dse/cassandra/cassandra.yaml
BACKUP_DIR=/etc/dse/cassandra/_backup_46
SLEEP_TIME=5

# backup current configuration
echo "Backing up existing cassandra configs..."
cp $DEFAULT_YAML_LOCATION $NEW_YAML
mkdir $BACKUP_DIR
cp /etc/dse/cassandra/* $BACKUP_DIR

# comment out deprecated settings from 4.6 cassandra.yaml file
echo "Upgrading the backed up cassandra.yaml to be 4.8 compatible.."
sed -i -e "s/multithreaded_compaction: \(.*\)/# multithreaded_compaction: \1/g" $NEW_YAML
sed -i -e "s/memtable_flush_queue_size: \(.*\)/# memtable_flush_queue_size: \1/g" $NEW_YAML
sed -i -e "s/compaction_preheat_key_cache: \(.*\)/# compaction_preheat_key_cache: \1/g" $NEW_YAML
sed -i -e "s/in_memory_compaction_limit_in_mb: \(.*\)/# in_memory_compaction_limit_in_mb: \1/g" $NEW_YAML
sed -i -e "s/preheat_kernel_page_cache: \(.*\)/# preheat_kernel_page_cache: \1/g" $NEW_YAML

# update broadcast rpc value
sed -i -e "s/broadcast_address: \(.*\)/broadcast_rpc_address: \1/g" $NEW_YAML

# update java to version 8
echo "Installing Java 8"
add-apt-repository ppa:webupd8team/java -y
aptitude update -y
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
aptitude install oracle-java8-installer -y

#verify version
echo "Setting Java 8 to the default version..."
java -version
update-java-alternatives -s java-8-oracle
java -version

#remove v7
echo "Removing Java 7..."
aptitude remove oracle-java7-installer oracle-java7-set-default -y

# shutdown dse service cleanly

echo "Flushing cassandra..."
nodetool flush

echo "Sleeping ${SLEEP_TIME}s..."
sleep $SLEEP_TIME

echo "Draining cassandra..."
nodetool drain

echo "Sleeping ${SLEEP_TIME}s..."
sleep $SLEEP_TIME

echo "Stopping DSE service..."
service dse stop

# upgrade dse using .deb and aptitude
echo "Upgrading DSE to 4.8.x..."
aptitude upgrade dse-full -y

#copy 4.8 yaml back to original location
echo "Moving 4.8 version of yaml back to etc..."
cp $NEW_YAML $DEFAULT_YAML_LOCATION

#force ownership of directory
echo "Reapplying ownership of directories owned by cassandra user..."
chown -R cassandra:cassandra /mnt/cassandra

# startup dse
echo "Starting DSE service..."
service dse start


# remaining manual steps
# 1. check node is back online and seen by other nodes: nodetool status
# 2. upgrade the existing sstables: nodetool upgradesstables
# 3. Review logs to ensure all went well
