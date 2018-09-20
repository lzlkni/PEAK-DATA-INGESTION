#!/usr/bin/env bash

# Author: Zhuo Li Lin
# Date: 20180917
# Description: Add config for OIDC connection.
# The script only run on worker node

# Check parameter
# If miss exist with error

###################################
# Function
###################################

function error-handler {
    rc=$1
    msg=$2

    if [[ $rc != 0 ]];then
        echo "$msg is error, exit..."
        exit 1
    fi
}

function nifi-key-exch {
    # Generate and exchange certification between clients
    download_file https://peakdiautomation.blob.core.windows.net/nifi/nifi-toolkit-1.7.1-bin.tar.gz /tmp/nifi-toolkit-1.7.1-bin.tar.gz
    NIFITOOL='/usr/hdp/current/nifi-toolkit-1.7.1'
    # Clean up previous installation
    rm -rf $NIFITOOL

    untar_file /tmp/nifi-toolkit-1.7.1-bin.tar.gz /usr/hdp/current
    rm -rf /tmp/nifi-toolkit-1.7.1-bin.tar.gz
    
    cp /usr/hdp/current/nifi/conf/nifi.properties $NIFITOOL

    $NIFITOOL/bin/tls-toolkit.sh standalone -c ca.nifi.com -n \
    "wn0-hdi-${ENV}, wn1-hdi-${ENV}, wn2-hdi-${ENV}, wn3-hdi-${ENV}, \
    wn4-hdi-${ENV}, wn5-hdi-${ENV}, wn6-hdi-${ENV}, \
    wn7-hdi-${ENV}, wn8-hdi-${ENV}, wn9-hdi-${ENV}" -o $NIFITOOL/target -f $NIFITOOL/nifi.properties -O

    error-handler $? "Generating key"

    # Export public key for each machine
    
    hdfs dfs -mkdir -p /user/root/cert
    for ((i=0;i<=9;i++));do
        cd  $NIFITOOL/target/wn${i}-hdi-${ENV}
        KEYSTORE_PASS=$(cat nifi.properties  |grep nifi.security.keystorePasswd|cut  -d "=" -f 2)

        echo "Exporting cert wn${i}..."
        keytool -export -alias nifi-key -file $NIFITOOL/target/wn${i}-hdi-${ENV}/wn${i}.cer  -keystore $NIFITOOL/target/wn${i}-hdi-${ENV}/keystore.jks -storepass $KEYSTORE_PASS
        error-handler $? "Exporting cert"

        # upload data node key to storage	
        echo "Upload cert wn${i} to hdfs..."    
        hdfs dfs -put $NIFITOOL/target/wn${i}-hdi-${ENV}/wn${i}.cer /user/root/cert
        error-handler $? "Upload cert wn${i}"

        # upload keystore file
        echo "Upload keystore wn${i} to hdfs..."
        
        hdfs dfs -mkdir  -p /user/root/keystore/wn${i} 
        hdfs dfs -put  $NIFITOOL/target/wn${i}-hdi-${ENV}/keystore.jks /user/root/keystore/wn${i} 
        error-handler $? "Upload keystore wn${i}"

        # upload nifi.properties to storage
        echo "Upload nifi.properties wn${i} to hdfs..."
        
        hdfs dfs -mkdir  -p /user/root/nifi-properties/wn${i} 
        hdfs dfs -put $NIFITOOL/target/wn${i}-hdi-${ENV}/nifi.properties /user/root/nifi-properties/wn${i}        
        error-handler $? "nifi.properties wn${i}"
    done

    # Exchange keys

    for ((i=0;i<=9;i++));do
        cd  $NIFITOOL/target/wn${i}-hdi-${ENV}
        TRUSTSTORE_PASS=$(cat nifi.properties  |grep nifi.security.truststorePasswd|cut  -d "=" -f 2)

        echo "Importing cert to wn${i}..."
        for ((j=0;j<=9;j++));do        
            keytool -import -noprompt -alias nifi-key-wn${j} -file $NIFITOOL/target/wn${j}-hdi-${ENV}/wn${j}.cer -keystore $NIFITOOL/target/wn${i}-hdi-${ENV}/truststore.jks -storepass $TRUSTSTORE_PASS
            error-handler $? "Import key"
        done
        echo "Upload trustore wn${i} to hdfs..."
        
        hdfs dfs -mkdir -p /user/root/truststore/wn${i}
        hdfs dfs -put $NIFITOOL/target/wn${i}-hdi-${ENV}/truststore.jks /user/root/truststore/wn${i}
        error-handler $? "Upload key wn${i}"
    done
}

function wait-file-gen {
    # Wait the file generate from wn0
    local file=$1    
    local flag=1
    local cnt=0
    while [[ $flag -ne 0 && $cnt -le 359 ]]; do
        hdfs dfs -ls $file
        flag=$?
        if [[ $flag -eq 0 ]];then
            echo "File $file is ready"
            break
        fi
        echo "File $file not ready, retry 5sec..."
        sleep 5
        ((cnt++))
    done

    # If wait more then 30min, exit the program
    if [[ $cnt -eq 360 ]];then       
        error-handler 1 "Wait 30 mins, there should be error somewhere, please check..."
    fi
}
###################################
# Main 
###################################

aadapp_id=$1
aadapp_pwd=$2
tenant_id=$3


if [[ -z "$aadapp_id" ]]; then
	echo "Application ID cannot be null, exit..."
    exit 1
elif [[ -z "$aadapp_pwd" ]]; then
    echo "Application secret cannot be null, exit..."
    exit 1
elif [[ -z "$tenant_id" ]]; then
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

# Clean up the previous installation
rm -rf /usr/hdp/current/nifi

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
ENV=$(echo $HOSTNAME|cut -d '-' -f 3)

# Revised for OIDC - Lik
sed -i 's/nifi.web.http.port=8080/nifi.web.http.port=/g' nifi.properties
sed -i 's/nifi.web.http.port=8070/nifi.web.http.port=/g' nifi.properties
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
sed -i "s/nifi.security.user.authorizer=managed-authorizer/nifi.security.user.authorizer=file-provider/" nifi.properties

sed -i "s/nifi.variable.registry.properties=/nifi.variable.registry.properties=conf\/peak_custom.properties/" nifi.properties
# Review
sed -i "s/nifi.web.proxy.host=/nifi.web.proxy.host=/" nifi.properties


sed -i 's/java.arg.2=-Xms512m/java.arg.2=-Xms4g/g' bootstrap.conf
sed -i 's/java.arg.3=-Xmx512m/java.arg.3=-Xmx8g/g' bootstrap.conf

# Cleanup any output before
hdfs dfs -rm -r -f /user/root/cert
hdfs dfs -rm -r -f /user/root/keystore
hdfs dfs -rm -r -f /user/root/nifi-properties
hdfs dfs -rm -r -f /user/root/truststore

# If it's wn0 run the key gen and exchange
    
    if [[ $(test_is_first_datanode) -eq 1 ]];then
        nifi-key-exch
    fi

# Get nifi.property, keystort and truststore from hdfs
    rm -rf /usr/hdp/current/nifi/conf/nifi.properties
    WNNAME=$(hostname -s|cut -d '-' -f 1)
    file_list="/user/root/nifi-properties/${WNNAME}/nifi.properties \
    /user/root/keystore/${WNNAME}/keystore.jks \
    /user/root/truststore/${WNNAME}/truststore.jks"
    
    for f in $file_list; do
        wait-file-gen $f        
        hdfs dfs -get $f /usr/hdp/current/nifi/conf
        error-handler $? "Getting $f error..."
    done

# Config authorizers.xml
echo "Configing authorizers.xml"

sed -i 's/<\/authorizers>//g' /usr/hdp/current/nifi/conf/authorizers.xml
cat >>  /usr/hdp/current/nifi/conf/authorizers.xml << EOF
    <authorizer>
        <identifier>file-provider</identifier>
        <class>org.apache.nifi.authorization.FileAuthorizer</class>
        <property name="Authorizations File">./conf/authorizations.xml</property>
        <property name="Users File">./conf/users.xml</property>
        <property name="Initial Admin Identity">zhuo.li.lin@hsbc.com.cn</property>
        <property name="Legacy Authorized Users File"></property>
        <property name="Node Identity 1">CN=wn0-hdi-${ENV}, OU=NIFI</property>
        <property name="Node Identity 2">CN=wn1-hdi-${ENV}, OU=NIFI</property>
        <property name="Node Identity 3">CN=wn2-hdi-${ENV}, OU=NIFI</property>
        <property name="Node Identity 4">CN=wn3-hdi-${ENV}, OU=NIFI</property>
        <property name="Node Identity 5">CN=wn4-hdi-${ENV}, OU=NIFI</property>
        <property name="Node Identity 6">CN=wn5-hdi-${ENV}, OU=NIFI</property>
        <property name="Node Identity 7">CN=wn6-hdi-${ENV}, OU=NIFI</property>
        <property name="Node Identity 8">CN=wn7-hdi-${ENV}, OU=NIFI</property>
        <property name="Node Identity 9">CN=wn8-hdi-${ENV}, OU=NIFI</property>
        <property name="Node Identity 10">CN=wn9-hdi-${ENV}, OU=NIFI</property>
     </authorizer>
</authorizers>     

EOF

# Config logback.xml
sed -i '/ <!-- Suppress non-error messages due to excessive logging by class or library -->/a\
    <logger name="org.apache.nifi.cluster.coordination.heartbeat.AbstractHeartbeatMonitor" level="WARN"\/>\n \
    <logger name="org.apache.nifi.cluster.protocol.impl.SocketProtocolListener" level="WARN"\/>\n \
    <logger name="org.apache.nifi.controller.cluster.ClusterProtocolHeartbeater" level="WARN"\/>' /usr/hdp/current/nifi/conf/logback.xml

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
