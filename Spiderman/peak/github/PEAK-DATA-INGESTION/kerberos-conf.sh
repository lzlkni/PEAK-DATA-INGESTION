#!/usr/bin/env bash

HOSTNAME=`hostname`

# Import the helper method module.
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsight$
PRIMARY_HEADNODE=$(get_primary_headnode)

if [ $PRIMARY_HEADNODE == $HOSTNAME ];then
    echo "It's not primary head node. Exiting..."
    exit 0
fi

ENV=$(echo $PRIMARY_HEADNODE|cut -d '-' -f 3)

OS_VERSION=$(lsb_release -sr)
echo "OS Version is $OS_VERSION"

# Istall Kerberos
echo "Installing Kerberos..."
apt-get install krb5-kdc krb5-admin-server -y

if [ $? !=0 ];then
    echo "Installation failed..."
    exit 1
fi

# Config Kerberos
sed -i 's/\(default_realm = \)\S*/\1NIFI.INTERNAL.CLOUDAPP.NET/' /etc/krb5.conf
sed -i '/\[realms\]/a\
        NIFI.INTERNAL.CLOUDAPP.NET = {\n\
        kdc = ${HOSTNAME}\n\
        admin_server = ${HOSTNAME}\n\
        }' /etc/krb5.conf

sed -i '/\[domain_realm\]/a\
        .nifi.internal.cloudapp.net = NIFI.INTERNAL.CLOUDAPP.NET\
        nifi.internal.cloudapp.net = NIFI.INTERNAL.CLOUDAPP.NET' /etc/krb5.conf

# Create Domain
kdb5_util create -r NIFI.INTERNAL.CLOUDAPP.NET -s

if [ $? !=0 ];then
    echo "Create Kerberos Domain failed..."
    exit 1
fi

# Add user
kadmin.local -q "addprinc -pw ${principalpw} hdisshuser/admin"
if [ $? !=0 ];then
    echo "Add principle failed..."
    exit 1
fi
kadmin.local -q "ktadd -k /home/hdisshuser/hdisshuser.keytab hdisshuser/admin"
if [ $? !=0 ];then
    echo "Add keytab failed..."
    exit 1
fi

service krb5-admin-server restart
service krb5kdc start

# Generate and exchange certification between clients
download_file https://peakdiautomation.blob.core.windows.net/nifi/nifi-toolkit-1.7.1-bin.tar.gz /tmp/nifi-toolkit-1.7.1-bin.tar.gz

untar_file /tmp/nifi-toolkit-1.7.1-bin.tar.gz /usr/hdp/current

NIFITOOL='/usr/hdp/current/nifi-toolkit-1.7.1'
cp /usr/hdp/current/nifi/conf/nifi.properties $NIFITOOL

$NIFITOOL/bin/tls-toolkit.sh standalone -c ca.nifi.com -n \
"wn0-hdi-${ENV}, wn2-hdi-${ENV}, wn3-hdi-${ENV}, \
 wn4-hdi-${ENV}, wn5-hdi-${ENV}, wn6-hdi-${ENV}, \
 wn7-hdi-${ENV}, wn8-hdi-${ENV}, wn9-hdi-${ENV}" -o $NIFITOOL/target -f ./nifi.properties -O

# Export public key for each machine
for ((i=1;i<=6;i++));do
    cd  $NIFITOOL/target/wn${i}-hdi-ua
    KEYSTORE_PASS=$(cat nifi.properties  |grep nifi.security.keystorePasswd|cut  -d "=" -f 2)
    
    keytool -export -alias nifi-key -file $NIFITOOL/target/wn${i}-hdi-ua/wn${i}.cer  -keystore $NIFITOOL/target/wn${i}-hdi-ua/keystore.jks -storepass $KEYSTORE_PASS
    # upload data node key to blog storage
	az storage blob upload --container-name nifi --file $NIFITOOL/target/wn${i}-hdi-ua/wn${i}.cer --name $NIFITOOL/target/wn${i}-hdi-ua/wn${i}.cer --account-name peakdiautomation
done

# Import public key to each machine
for ((i=1;i<=6;i++));do
    cd  $NIFITOOL/target/wn${i}-hdi-ua
    TRUSTSTORE_PASS=$(cat nifi.properties  |grep nifi.security.truststorePasswd|cut  -d "=" -f 2)
    for ((j=1;j<=6;j++));do        
        keytool -import -alias nifi-key -file $NIFITOOL/target/wn${j}-hdi-ua/wn${j}.cer -keystore $NIFITOOL/target/wn${i}-hdi-uat/truststore.jks -storepass $TRUSTSTORE_PASS
    done
done

