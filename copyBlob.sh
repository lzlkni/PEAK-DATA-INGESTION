#! /bin/bash

SCRIPTNAME=`basename $0`
SCRIPTPATH=`dirname ${0}`

# Usage of the script
function usage() {
    cat <<-EOF

    Provide a table list file in the same folder and format <database>/<table>
    Blob name will be combination of <database>/<table>/<start-date>/*
    If end-day is not provided, all blob from start-day to the latest day will be copied.
    If source-blob or destination-blob is provide, start-day and end-day will be ignored.

    Usage:
    $SCRIPTNAME 
        --table-file <Table list file>
        [--destination-container] <Destination container name>
        --account-name <Storage account name of destination>
        --sas-token <SAS token of destination>
        --source-account-name <Storage account name of source>
        --source-sas <SAS token of source>
        --source-container <continer name of source>
        [--source-blob] <Source blob name>

EOF
}

# Check if the vault null, and give alert
function checknull (){
    local value=$2
    local arg=$1    
    if [[ -z $value ]];then
        echo "$arg is empty!"
        usage
        exit 1
    fi
}

# Check the returen code and give error message
function checkerror(){
        local rc=$1
        local msg=$2
        if [[ $rc -ne 0 ]];then
                echo $msg
                exit $rc
        fi
}

ARGS=`getopt -a -o rh -l table-file:,start-date:,end-day:,destination-blob:,destination-container:,account-name:,sas-token:,source-account-name:,source-sas:,source-container:,source-blob:,remove-source,help -- "$@"`

[ $? -ne 0 ] && usage  

if [ $# -eq 0 ];then    
    usage
    exit -1
fi

eval set -- "${ARGS}" 

while true  
do  
        case "$1" in 
        --table-file)
                tableFile="$2"
                shift
                ;;
        --destination-container)
                dContainer="$2" 
                shift
                ;;  
        --account-name)
                accName="$2"
                shift
                ;;  
        --sas-token)
                sasToken="$2"                
                shift
                ;;  
        --source-account-name)
                sAccName="$2"                 
                shift
                ;;  
        --source-sas)
                sSas="$2"               
                shift
                ;;  
        --source-container)
                sContainer="$2"                 
                shift
                ;;  
        --source-blob)
                sBlob="$2"
                shift                
                ;;  
        -r|--remove-source)
                rmSrc="Y"
                ;;
        -h|--help)
                usage  
                ;;  
        --)  
                shift
                break 
                ;;  
        esac  
shift  
done 

# Check the mandatory arguments
checknull "Table List File"         $tableFile
checknull "Destination Accountname" $accName
checknull "SAS Tocken"              $sasToken
checknull "Source Account Name"     $sAccName
checknull "Source SAS"              $sSas	
checknull "Source Container"        $sContainer

if [[ ! -f ${tableFile} ]];then
        checkerror 1 "File ${tableFile} is not exist!"
fi

# Valuable
MAXENDDAY="9999-12-31"
todaydate=$(date +%Y%m%d)
currentdatetime=$(date +'%Y%m%d %H:%M:%S')
LOGFILE="${SCRIPTPATH}/logs/copyBlob.$(basename ${tableFile} .txt).${todaydate}.log"


echo "Copying started, please check ${LOGFILE} for detail."

exec 3>> ${LOGFILE}
exec 2>&3
exec 1>&3
chmod 744 ${LOGFILE}

echo "################"
echo "## Program started at $(TZ="Asia/Hong_Kong" date +'%Z %Y%m%d %H:%M:%S')"
echo "################"

echo "Copying blob from ${sAccName} to ${accName}" 

# If destination container is not provided, set it same as source one.
if [[ -z $dContainer ]];then
    dContainer=$sContainer
fi

## Check the dest container, if no exist create it
az storage container list --account-name "${accName}" --sas-token "${sasToken}" --query "[].name" | grep ${dContainer} >/dev/null

if [[ $? -ne 0 ]];then
    echo "Creating target container: ${dContainer} on ${accName}..."
    az storage container create --name "${dContainer}" --account-name "${accName}" --sas-token "${sasToken}"
    checkerror $? "Create destination container is failed!"
fi

# Process table one by one
while read line
do
        # Get info from parameter file
        inputTable=$(echo ${line}|awk -F ',' '{print $1}')
        startDate=$(echo ${line}|awk -F ',' '{print $2}')
        endDay=$(echo ${line}|awk -F ',' '{print $3}')

        # Process start date, end date
        echo "## Processing table: ${inputTable}"
        echo "Start Date: ${startDate}"
        startDateD=$(date -d "${startDate}" +%s)
        checkerror $? "Set start date error!"

        if [[ -n ${endDay}  ]];then
                echo "End day: ${endDay}"
                endDayD=$(date -d "${endDay}" +%s)
                checkerror $? "Set end date error!"
        else
                echo "End day is not provided, will extract to MAX date"
                endDayD=$(date -d "${MAXENDDAY}" +%s)
                checkerror $? "Set end date error!"
        fi

        # List blob in the source container
        query="?starts_with(name,'${inputTable}/')"

        tableList=$(az storage blob list --container-name  ${sContainer} \
        --account-name ${sAccName} \
        --sas-token ${sSas} \
        --query [${query}].name)

        if [[ ${#tableList} -eq 0 ]];then
        
                checkerror 1 "No table found for ${inputTable}, please check your input!"
        fi

        # Formate the table list, remove charactor [ , "  etc.
        tableListFormated=`echo ${tableList}|sed "s/,//g"|sed "s/\[//g"|sed "s/\]//g"|sed "s/\"//g"`

        # For all the tables in list, check the date is between the setting date, then copy it to target
        for t in ${tableListFormated}
        do
        
        tableDate=$(echo $t|awk -F '/' '{print $3}')
        tableDateD=$(date -d "${tableDate}" +%s)

        if [[ $tableDateD -ge $startDateD && $tableDateD -le $endDayD ]];then
                echo "Processing $t ..."
                command=$(az storage blob copy start \
                        --destination-blob "${t}" \
                        --destination-container "${dContainer}" \
                        --account-name "${accName}" \
                        --sas-token   "${sasToken}" \
                        --source-account-name "${sAccName}"  \
                        --source-sas  "${sSas}" \
                        --source-container "${sContainer}" \
                        --source-blob "$t")
                checkerror $? "Copy blob $t is failed"        
        fi

        done

        # Verify the copy is success
        for t in ${tableListFormated}
        do
        echo "Verifying blob $t complete copy..."

        tableDate=$(echo $t|awk -F '/' '{print $3}')
        tableDateD=$(date -d "${tableDate}" +%s)

        if [[ $tableDateD -ge $startDateD && $tableDateD -le $endDayD ]];then
                copyStatus=$(az storage blob show \
                        --container-name "${dContainer}" \
                        --name "$t" \
                        --sas-token "${sasToken}" \
                        --account-name "${accName}" \
                        --query properties.copy.status)
                cnt=0
                while [[ "${copyStatus//\"/}" != "success" && $cnt -le 360 ]];do
                        copyStatus=$(az storage blob show \
                        --container-name "${dContainer}" \
                        --name "$t" \
                        --sas-token "${sasToken}" \
                        --account-name "${accName}" \
                        --query properties.copy.status)
                        sleep 5
                done
                if [ $cnt -gt 360 ];then
                        checkerror 1 "Copy is not finished in 30 mins"
                fi
                echo "Blob $t complete copy."

                if [[ ${rmSrc} == 'Y' ]];then
                        echo "Removing source blob $t ..."
                        delStatus=$(az storage blob delete --container-name "${sContainer}" \
                       --name "$t" \
                       --sas-token "${sSas}" \
                       --account-name "${sAccName}"
                       )
                fi
        fi


        done
done < $SCRIPTPATH/$tableFile

echo "################"
echo "## All process done successfully! $(TZ="Asia/Hong_Kong" date +'%Z %Y%m%d %H:%M:%S')"
echo "################"