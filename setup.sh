#!/bin/bash
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

token=$(gcloud auth print-access-token)
project=cabral-app-integration
region=southamerica-east1
source_integration_name="salesforce-sched-to-bq"
source_integration_version="2" #CHECK LATEST VERSION
template_table_name="TEMPLATE_TABLE" # please set to something unique within the integration
target_tables=("Orders" "Claims" "Custom__c")



### Step #0 - Connector Setup
echo "Make sure all connections are up and setup. All generated integrations will use the same connections."


echo "Installing integrationcli ..."
curl -L https://raw.githubusercontent.com/GoogleCloudPlatform/application-integration-management-toolkit/main/downloadLatest.sh | sh -
export PATH=$PATH:$HOME/.integrationcli/bin

integrationcli prefs set -p $project -r $region -t $token

### Step #1 - Export Template 
# Export with: 
integrationcli integrations scaffold -n ${source_integration_name} -s ${source_integration_version} -e template -f . --skip-connectors 


for table in "${target_tables[@]}"; do
  temp_dir="temp-${table}"
  mkdir -p "${temp_dir}/src"  # Create directories if they don't exist
  cp -r src/* "${temp_dir}/src/"  # Copy contents of src directory
  cp -r template/* "${temp_dir}/"  # Copy contents of template directory

  # Construct a unique filename for each table
  output_filename="${source_integration_name}_${table}.json"

  # Check if the source file exists before running sed
  if [ ! -f "${temp_dir}/src/${source_integration_name}.json" ]; then
    echo "Error: Source file ${temp_dir}/src/${source_integration_name}.json not found"
    continue
  fi

  # Use sed to replace the placeholder
  sed -i "" "s/${template_table_name}/${table}/g" "${temp_dir}/src/${source_integration_name}.json"
  
  # Rename the JSON file
  mv "$temp_dir/src/${source_integration_name}.json" "$temp_dir/src/$output_filename"

  echo "Integration template for table '$table' created in: $temp_dir"
  echo "Renamed JSON file to: $output_filename"

  integrationcli integrations apply -f "${temp_dir}" --wait=true -g
done