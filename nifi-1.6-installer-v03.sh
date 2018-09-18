#!/usr/bin/env bash

# Author: Zhuo Li Lin
# Date: 20180917
# Description: Add config for OIDC connection.
# The script only run on worker node

# Check parameter
# If miss exist with error
aadapp_id=$1
aadapp_pwd=$2
tenant_id=$3


if [[ -z "$aadapp_id" ]]; then
	echo "Application ID cannot by null, exit..."
    exit 1
else if [[ -z "$aadapp_pwd" ]]; then
    echo "Application secret cannot be null, exit..."
    exit 1
else if [[ -z "$tenant_id" ]]; then
    echo "Tenant ID cannot be null, exit..."
    exit 1
fi

# Import the helper method module.
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsight$

if [ `test_is_zookeepernode` == 1 ]; then
    echo "NIFI cannot be installed on Zookeeper nodes. Exiting..."
    exit 0
fi

OS_VERSION=$(lsb_release -sr)
echo "OS Version is $OS_VERSION"

# In case NIFI is installed, exit.
if [ -e /usr/hdp/current/nifi ]; then
    echo "NIFI is already installed, exiting ..."
    exit 0
fi

# Download NIFI binary to temporary location.
echo "Downloading NIFI binaries"
download_file https://peakdiautomation.blob.core.windows.net/nifi/nifi-1.6.0-bin.tar.gz /tmp/nifi-1.6.0-bin.tar.gz

# Untar the NIFI binary and move it to proper location.
untar_file /tmp/nifi-1.6.0-bin.tar.gz /usr/hdp/current
mv /usr/hdp/current/nifi-1.6.0 /usr/hdp/current/nifi

# Remove the temporary file downloaded.
rm -f /tmp/nifi-1.6.0-bin.tar.gz

# Configure NIFI
echo "Configuring NIFI cluster"
ZKHOSTS=`grep -R zookeeper /etc/hadoop/conf/yarn-site.xml | grep 2181 | grep -oPm1 "(?<=<value>)[^<]+"`
if [ -z "$ZKHOSTS" ]; then
    ZKHOSTS=`grep -R zk /etc/hadoop/conf/yarn-site.xml | grep 2181 | grep -oPm1 "(?<=<value>)[^<]+"`
fi

cd /usr/hdp/current/nifi/conf
HOSTNAME=`hostname`
# Revised for OIDC - Lik
sed -i "s/nifi.web.http.host=/nifi.web.https.host=${HOSTNAME}/g" nifi.properties
sed -i 's/nifi.web.http.port=8080/nifi.web.http.port=/g' nifi.properties
sed -i 's/nifi.web.https.port=/nifi.web.https.port=9443/g' nifi.properties
sed -i 's/nifi.cluster.is.node=false/nifi.cluster.is.node=true/g' nifi.properties
sed -i "s/nifi.cluster.node.address=/nifi.cluster.node.address=${HOSTNAME}/g" nifi.properties
sed -i 's/nifi.cluster.node.protocol.port=/nifi.cluster.node.protocol.port=11443/g' nifi.properties
sed -i "s/nifi.zookeeper.connect.string=/nifi.zookeeper.connect.string=${ZKHOSTS}/g" nifi.properties
sed -i "s/<property name=\"Connect String\"><\/property>/<property name=\"Connect String\">${ZKHOSTS}<\/property>/g" state-management.xml
# Add OIDC setting - Lik
sed -i "s/nifi.security.user.oidc.discovery.url=/nifi.security.user.oidc.discovery.url=https:\/\/login.microsoftonline.com\/${tenant_id}\/.well-known\/openid-configuration/" nifi.properties
sed -i "s/nifi.security.user.oidc.client.id=/nifi.security.user.oidc.client.id=${aadapp_id}/" nifi.properties
sed -i "s/nifi.security.user.oidc.client.secret=/nifi.security.user.oidc.client.secret=${aadapp_pwd}/" nifi.properties

sed -i 's/java.arg.2=-Xms512m/java.arg.2=-Xms4g/g' bootstrap.conf
sed -i 's/java.arg.3=-Xmx512m/java.arg.3=-Xmx8g/g' bootstrap.conf

# Install NIFI service
echo "Installing NIFI as service"
cat >/etc/systemd/system/multi-user.target.wants/nifi.service <<EOL
[Unit]
Description=Apache NiFi

[Service]
Type=forking
ExecStart=/usr/hdp/current/nifi/bin/nifi.sh start
ExecStop=/usr/hdp/current/nifi/bin/nifi.sh stop
ExecRestart=/usr/hdp/current/nifi/bin/nifi.sh restart

[Install]
WantedBy=multi-user.target
EOL

echo "Starting the NIFI service"
if [[ $OS_VERSION == 16* ]]; then
    echo "Using systemd configuration"
    systemctl daemon-reload
    systemctl start nifi
else
    echo "Using upstart configuration"
    initctl reload-configuration
    start nifi
fi
