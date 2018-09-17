#!/usr/bin/env bash
function error-handler(){
    rc=$1
    msg=$2

    if [[ $rc != 0 ]];then
        echo "$msg is error, exit..."
        exit 1
    fi
}

HOSTNAME=`hostname`

# Import the helper method module.
wget -O /tmp/HDInsightUtilities-v01.sh -q https://hdiconfigactions.blob.core.windows.net/linuxconfigactionmodulev01/HDInsightUtilities-v01.sh && source /tmp/HDInsightUtilities-v01.sh && rm -f /tmp/HDInsight$
PRIMARY_HEADNODE=$(get_primary_headnode)

if [ $PRIMARY_HEADNODE == $HOSTNAME ];then
    echo "It's not primary head node. Exiting..."
    exit 0
fi

ENV=$(echo $PRIMARY_HEADNODE|cut -d '.' -f 1|cut -d '-' -f 3)

OS_VERSION=$(lsb_release -sr)
echo "OS Version is $OS_VERSION"

# Generate and exchange certification between clients
download_file https://peakdiautomation.blob.core.windows.net/nifi/nifi-toolkit-1.7.1-bin.tar.gz /tmp/nifi-toolkit-1.7.1-bin.tar.gz

tar -zxvf /tmp/nifi-toolkit-1.7.1-bin.tar.gz /usr/hdp/current

NIFITOOL='/usr/hdp/current/nifi-toolkit-1.7.1'
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
    echo "Upload key wn${i} to hdfs..."    
    hdfs dfs -mkdir -p /user/root/truststore/wn${i}
    hdfs dfs -put $NIFITOOL/target/wn${i}-hdi-${ENV}/truststore.jks /user/root/truststore/wn${i}
    error-handler $? "Upload key wn${i}"
done

echo "Generate key and exchange done successfully!"
exit 0

