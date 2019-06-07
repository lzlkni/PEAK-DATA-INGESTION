#! /bin/bash

SCRIPTNAME=`basename $0`
SCRIPTPATH=`dirname ${0}`

# Usage of the script
function usage() {
    cat <<-EOF

    Provide ehub namespace, ehub and the year, month, date to perform the copy. 
    The default for year, month, date is * .

    Usage:
    $SCRIPTNAME 
        --table-file <Table list file>
        [--destination-container] <Destination container name>
        --account-name <Storage account name of destination>
        --sas-token <SAS token of destination>
        --source-account-name <Storage account name of source>
        --source-sas <SAS token of source>
        --source-container <continer name of source>
       

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

# Check the reture code and give error message
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

todaydate=$(date +%Y%m%d)
MAXENDDAY=${todaydate}
currentdatetime=$(date +'%Y%m%d %H:%M:%S')
LOGFILE="${SCRIPTPATH}/logs/$SCRIPTNAME.$(basename ${tableFile} .txt).${todaydate}.log"


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

# Process folder one by one
while read line
do
        # Get info from parameter file
        ehubns=$(echo ${line}|awk -F ',' '{print $1}')
        ehub=$(echo ${line}|awk -F ',' '{print $2}')
        year=$(echo ${line}|awk -F ',' '{print $3}')
        month=$(echo ${line}|awk -F ',' '{print $4}')
        day=$(echo ${line}|awk -F ',' '{print $5}')

        checknull "EventHub Name Space"         $ehubns
        checknull "EventHub"         $ehub

        # Build path
        blobPath="${ehubns}/${ehub}/*/${year:='*'}/${month:='*'}/${day:='*'}/*/*/*.avro"
        

        echo "Processing $blobPath ..."

        command=$(az storage blob copy start-batch \
                --destination-container "${dContainer}" \
                --account-name "${accName}" \
                --sas-token   "${sasToken}" \
                --source-account-name "${sAccName}"  \
                --source-sas  "${sSas}" \
                --source-container "${sContainer}" \
                --pattern "${blobPath}" 
                )
        checkerror $? "Copy blob ${blobPath} is failed"        



        # if [[ ${rmSrc} == 'Y' ]];then
        #         echo "Removing source blob $b ..."
        #         delStatus=$(az storage blob delete --container-name "${sContainer}" \
        #         --name "$b" \
        #         --sas-token "${sSas}" \
        #         --account-name "${sAccName}"
        #         )
        # fi

done < $SCRIPTPATH/$tableFile

echo "################"
echo "## All process done successfully! $(TZ="Asia/Hong_Kong" date +'%Z %Y%m%d %H:%M:%S')"
echo "################"