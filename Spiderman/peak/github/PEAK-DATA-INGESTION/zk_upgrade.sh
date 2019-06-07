#!/usr/bin/env bash

HOSTNAME=`hostname`

# Import the helper method module.
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsight$
PRIMARY_HEADNODE=$(get_primary_headnode)

# Common Valuables
if [ $PRIMARY_HEADNODE == $HOSTNAME ];then
    echo "It's not primary head node. Exiting..."
    exit 0
fi

ENV=$(echo $PRIMARY_HEADNODE|cut -d '-' -f 3)

OS_VERSION=$(lsb_release -sr)
echo "OS Version is $OS_VERSION"

# Download ZooKeeper
echo "Download zookeeper..."
download_file https://peakdiautomation.blob.core.windows.net/nifi/zookeeper-3.4.13.tar.gz /tmp/zookeeper-3.4.13.tar.gz

# Get HDP version
hdp_version=$(ls -l -d /usr/hdp/2.*|cut -d '/' -f 4)

# Untar and move to hdp
echo "Untart zookeeper..."
untar_file /tmp/zookeeper-3.4.13.tar.gz /usr/hdp/${hdp_version}/

# Backup previous ZooKeeper and replace with new version
echo "Backup previous ZooKeeper and replace with new version"
mv /usr/hdp/${hdp_version}/zookeeper /usr/hdp/${hdp_version}/zookeeper.bak
mv /usr/hdp/${hdp_version}/zookeeper-3.4.13 /usr/hdp/${hdp_version}/zookeeper

# Link back the conf 
echo "Link back the conf "
mv /usr/hdp/${hdp_version}/zookeeper/conf /usr/hdp/${hdp_version}/zookeeper/conf.bak

ln -s  /etc/zookeeper/${hdp_version}/0 /usr/hdp/${hdp_version}/zookeeper/conf

rm -rf /tmp/zookeeper-3.4.13.tar.gz