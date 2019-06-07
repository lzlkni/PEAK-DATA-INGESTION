#!/bin/bash
az monitor activity-log alert list -g rg-uat-hk-di-alerts -o tsv --query "[*].[name]" > output.tsv
cat output.tsv | while read -r name; 
do
	az monitor activity-log alert delete --name "$name" --resource-group 'rg-uat-hk-di-alerts' --verbose
done