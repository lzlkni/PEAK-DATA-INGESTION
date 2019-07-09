#! /bin/bash

cluster_id=$1
path=$2
jar_list=$3

while read line
do
    echo "Installing ${line} ..."

    databricks libraries install --cluster-id  ${cluster_id}  --jar   ${path}${line}
    sleep 1


done < ${jar_list}
