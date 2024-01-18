#!/bin/bash
# used to add to configmap for grafana 
# Define the ConfigMap name
CONFIG_MAP_NAME="prometheus-grafana"

# Check if the number of command-line arguments is correct
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <key=value>"
  exit 1
fi

# Split the input into key and value
INPUT="$1"
IFS="=" read -r NEW_KEY NEW_VALUE <<< "$INPUT"

# Check if the input was successfully split
if [ -z "$NEW_KEY" ] || [ -z "$NEW_VALUE" ]; then
  echo "Invalid input format. Please use the format 'key=value'."
  exit 1
fi

# Retrieve the existing ConfigMap data
EXISTING_CONFIG_MAP=$(kubectl get configmap $CONFIG_MAP_NAME -o json -n prometheus-grafana)

# Use jq to add the new key-value pair after the "domain" key under "grafana.ini"
MODIFIED_CONFIG_MAP=$(echo "$EXISTING_CONFIG_MAP" | jq --arg NEW_KEY "$NEW_KEY" --arg NEW_VALUE "$NEW_VALUE" '.data."grafana.ini" |= . + "\n\($NEW_KEY) = \($NEW_VALUE)"')

# Apply the modified ConfigMap
echo "$MODIFIED_CONFIG_MAP" | kubectl apply -n prometheus-grafana -f -
