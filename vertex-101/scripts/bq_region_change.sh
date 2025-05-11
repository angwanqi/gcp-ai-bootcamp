#!/bin/bash

# Set variables
PROJECT_ID=$1
NEW_LOCATION=$2
OLD_DATASET="tx"
NEW_DATASET="tx"
SERVICE_ACCOUNT=$3
TRANSFER_JOB_NAME="transfer_job"



#PROJECT_ID="fraud123-438914"
#OLD_DATASET="tx"
#NEW_LOCATION="asia-southeast1"
#NEW_DATASET="tx"
#TRANSFER_JOB_NAME="transfer_job"
#SERVICE_ACCOUNT="520607199607-compute@developer.gserviceaccount.com"

# Step 1: Create a temporary dataset in the desired location
bq --project_id="$PROJECT_ID" mk --location="$NEW_LOCATION" --dataset "temp_$OLD_DATASET"

# Ensure that BQ transfer service api is enabled
# Step 2: Transfer dataset to the temp dataset via BQ Data Transfer Service
transfer_output=$(bq mk  --transfer_config --project_id="$PROJECT_ID" --data_source=cross_region_copy --target_dataset="temp_$OLD_DATASET" --display_name="Transfer $OLD_DATASET"  --params='{"source_dataset_id":"'"$OLD_DATASET"'","source_project_id":"'"$PROJECT_ID"'","overwrite_destination_table":"true"}' --service_account_name=$SERVICE_ACCOUNT)

echo $transfer_output

transfer_config_id=$(echo "$transfer_output" | grep -oE 'projects/[^ ]+')

transfer_config_id_cleaned=$(echo "$transfer_config_id" | sed "s/'$//")

# Step 3: Wait for the transfer job to complete
while true; do
    JOB_STATUS=$(bq ls --transfer_run  --run_attempt='LATEST' $transfer_config_id_cleaned | grep SUCCEEDED)
    if [[ "$JOB_STATUS" == *"SUCCEEDED"* ]] ; then
        break
    else
        sleep 10
    fi
done

# Step 4: Check the consistency
SOURCE_TABLES=$(bq --project_id="$PROJECT_ID" ls --max_results=1000 "$OLD_DATASET" | awk '{print $1}' | tail -n +3)
TARGET_TABLES=$(bq --project_id="$PROJECT_ID" ls --max_results=1000 "temp_$OLD_DATASET" | awk '{print $1}' | tail -n +3)





#CAUTION below statement assumes view names start with "v_" adapt per your needs
# Step 5: Copy views from source dataset to target dataset
for VIEW in $(bq --project_id="$PROJECT_ID" ls --max_results=1000 --format=json "$OLD_DATASET" | grep '"type":"VIEW"' | jq -r '.[].tableReference.tableId' ); do
    VIEW_QUERY=$(bq --project_id="$PROJECT_ID" show --format=prettyjson "$OLD_DATASET.$VIEW" | jq -r '.view.query')
    VIEW_QUERY_cleaned=$(echo "$VIEW_QUERY" | sed "s/$OLD_DATASET./temp_$OLD_DATASET./g")
    echo $VIEW-$VIEW_QUERY_cleaned
    bq --project_id="$PROJECT_ID"  mk --use_legacy_sql=false  --view "$VIEW_QUERY_cleaned" "temp_$OLD_DATASET.$VIEW"
done

# Check if the number of tables is the same
if [[ $(echo "$SOURCE_TABLES" | wc -l) -eq $(echo "$TARGET_TABLES" | wc -l) ]]; then
    echo "Number of tables is consistent between source and target datasets."
else
    echo "Number of tables is NOT consistent between source and target datasets."
fi

# Check row counts/sizes from the information schema
for TABLE in $SOURCE_TABLES; do
    SOURCE_ROWS=$(bq --project_id="$PROJECT_ID" query --nouse_legacy_sql "SELECT COUNT(*) FROM \`$PROJECT_ID.$OLD_DATASET.$TABLE\`" | tail -n +3)
    TARGET_ROWS=$(bq --project_id="$PROJECT_ID" query --nouse_legacy_sql "SELECT COUNT(*) FROM \`$PROJECT_ID.temp_$OLD_DATASET.$TABLE\`" | tail -n +3)

    if [[ "$SOURCE_ROWS" == "$TARGET_ROWS" ]]; then
        echo "Row count is consistent for table $TABLE."
    else
        echo "Row count is NOT consistent for table $TABLE."
    fi
done

# Step 6: Copy procedures from source dataset to target dataset
for PROCEDURE in $(bq --project_id="$PROJECT_ID" ls --max_results=1000 --format=json "$OLD_DATASET" | jq -r '.[].routineReference.routineId' | grep "^p_"); do
    PROCEDURE_QUERY=$(bq --project_id="$PROJECT_ID" show --format=prettyjson "$OLD_DATASET.$PROCEDURE" | jq -r '.routineType + " " + .definitionBody')
    PROCEDURE_QUERY_cleaned=$(echo "$PROCEDURE_QUERY" | sed "s/$OLD_DATASET./temp_$OLD_DATASET./g")
    bq query --project_id="$PROJECT_ID" --nouse_legacy_sql --replace -q "$PROCEDURE_QUERY_cleaned" --destination_table "$NEW_DATASET.$PROCEDURE"
done

# Step 7: Delete the old dataset
bq --project_id="$PROJECT_ID" rm -r -f "$OLD_DATASET"

# Step 8: Create the dataset in the new location with the same name
bq --project_id="$PROJECT_ID" mk --location="$NEW_LOCATION" --dataset "$NEW_DATASET"

# Step 9: Transfer temp dataset to the new dataset with the exact name in the new location

transfer_output=$(bq mk  --transfer_config --project_id="$PROJECT_ID" --data_source=cross_region_copy --target_dataset="$NEW_DATASET" --display_name="Transfer $NEW_DATASET"  --params='{"source_dataset_id":"'"temp_$OLD_DATASET"'","source_project_id":"'"$PROJECT_ID"'","overwrite_destination_table":"true"}' --service_account_name=$SERVICE_ACCOUNT)

transfer_config_id=$(echo "$transfer_output" | grep -oE 'projects/[^ ]+')

transfer_config_id_cleaned=$(echo "$transfer_config_id" | sed "s/'$//")

echo $transfer_output

# Step 10: Wait for the transfer job to complete

while true; do
    JOB_STATUS=$(bq ls --transfer_run  --run_attempt='LATEST' $transfer_config_id_cleaned | grep SUCCEEDED)
    if [[ "$JOB_STATUS" == *"SUCCEEDED"* ]] ; then
        break
    else
        sleep 10
    fi
done

# Step 11: Copy views from source dataset to target dataset


for VIEW in $(bq --project_id="$PROJECT_ID" ls --max_results=1000 --format=json "temp_$OLD_DATASET" | grep '"type":"VIEW"' | jq -r '.[].tableReference.tableId' ); do
    VIEW_QUERY=$(bq --project_id="$PROJECT_ID" show --format=prettyjson "temp_$OLD_DATASET.$VIEW" | jq -r '.view.query')
    VIEW_QUERY_cleaned=$(echo "$VIEW_QUERY" | sed "s/temp_$OLD_DATASET./$OLD_DATASET./g")
    echo $VIEW-$VIEW_QUERY_cleaned
    bq --project_id="$PROJECT_ID" mk  --use_legacy_sql=false --view "$VIEW_QUERY_cleaned" "$OLD_DATASET.$VIEW"
done

# Step 12: Copy procedures from source dataset to target dataset
for PROCEDURE in $(bq --project_id="$PROJECT_ID" ls --max_results=1000 --format=json "temp_$OLD_DATASET" | jq -r '.[].routineReference.routineId' | grep "^p_"); do
    PROCEDURE_QUERY=$(bq --project_id="$PROJECT_ID" show --format=prettyjson "temp_$OLD_DATASET.$PROCEDURE" | jq -r '.routineType + " " + .definitionBody')
    PROCEDURE_QUERY_cleaned=$(echo "$VIEW_QUERY" | sed "s/temp_$OLD_DATASET./$OLD_DATASET./g")
    bq query --project_id="$PROJECT_ID" --nouse_legacy_sql --replace -q "$PROCEDURE_QUERY_cleaned" --destination_table "$NEW_DATASET.$PROCEDURE"
done

# Check if the number of tables is the same
if [[ $(echo "$SOURCE_TABLES" | wc -l) -eq $(echo "$TARGET_TABLES" | wc -l) ]]; then
    echo "Number of tables is consistent between source and target datasets."
else
    echo "Number of tables is NOT consistent between source and target datasets."
fi

# Check row counts/sizes from the information schema
for TABLE in $SOURCE_TABLES; do
    SOURCE_ROWS=$(bq --project_id="$PROJECT_ID" query --nouse_legacy_sql "SELECT COUNT(*) FROM \`$PROJECT_ID.$OLD_DATASET.$TABLE\`" | tail -n +3)
    TARGET_ROWS=$(bq --project_id="$PROJECT_ID" query --nouse_legacy_sql "SELECT COUNT(*) FROM \`$PROJECT_ID.temp_$OLD_DATASET.$TABLE\`" | tail -n +3)

    if [[ "$SOURCE_ROWS" == "$TARGET_ROWS" ]]; then
        echo "Row count is consistent for table $TABLE."
    else
        echo "Row count is NOT consistent for table $TABLE."
    fi
done

# Step 13: Drop the temp dataset
bq --project_id="$PROJECT_ID" rm -r -f "temp_$OLD_DATASET"
