#!/bin/bash

set -euo pipefail

LB=$1
FACILITIES_PATH=${2:-facilities/v0}

OUT=$(mktemp)

onExit() { rm $OUT; }
trap onExit EXIT

request() {
  local path="$1"
  curl -sHapikey:${API_KEY} -k "$LB/$FACILITIES_PATH/$path" -o $OUT -w "$(date +'%D %T') %{http_code} %{time_total} $path\n"
}

request facilities/all
ids=( $(jq -r '.features[].properties.id' $OUT) )
for id in "${ids[@]}"
do
  request facilities/$id
  lat="$(jq -r '.data.attributes.lat' $OUT)"
  long="$(jq -r '.data.attributes.long' $OUT)"
  zip="$(jq -r '.data.attributes.address.physical.zip' $OUT)"
  state="$(jq -r '.data.attributes.address.physical.state' $OUT)"
  request "facilities?zip=${zip%-*}"
  request "facilities?state=$state"
  request "facilities?lat=$lat&lng=$long&ids=$id"
  request "nearby?lat=$lat&lng=$long"
done

