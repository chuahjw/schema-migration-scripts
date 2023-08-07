#!/bin/bash

###### Edit this Section accordingly ######

SRC_SCHEMA_REGISTRY="http://localhost:8081"
DST_SCHEMA_REGISTRY="http://localhost:8082"

# TLS Encryption
# SRC_CACERT="/path/to/src/cacert.crt"
# DST_CACERT="/path/to/dst/cacert.crt"

# Authentication
# SRC_USER_PASSWORD="abc123:abc123"
# DST_USER_PASSWORD="abc123:abc123"

###### End Edit ######

echo "Schema Migration Tool (Option 1): Copy Schemas from Source to Destination"
echo "CHECK: Ensure that Destination Schema Registry mode.mutability=true before continuing"
read -p "Press ENTER to continue..." REPLY

# Construct CURL_OPTS
CURL_OPTS_SRC="-s"
CURL_OPTS_DST="-s"

if [ ! -z "$SRC_CACERT" ]; then
    CURL_OPTS_SRC="$CURL_OPTS_SRC --cacert $SRC_CACERT"
fi

if [ ! -z "$SRC_USER_PASSWORD" ]; then
    CURL_OPTS_SRC="$CURL_OPTS_SRC -u $SRC_USER_PASSWORD"
fi

if [ ! -z "$DST_CACERT" ]; then
    CURL_OPTS_DST="$CURL_OPTS_DST --cacert $DST_CACERT"
fi

if [ ! -z "$SRC_USER_PASSWORD" ]; then
    CURL_OPTS_DST="$CURL_OPTS_DST -u $DST_USER_PASSWORD"
fi

# echo "Constructed CURL_OPTS:"
# echo "SRC: $CURL_OPTS_SRC"
# echo "DST: $CURL_OPTS_DST"
# echo

# Import Schema into Destination Schema Registry
register_schema () {
    # $1: subject name
    # $2: schema in JSON format
    # Sample schema: 
    # {
    #     "subject": "test-topic-value",
    #     "version": 1,
    #     "id": 1,
    #     "schema": "{\"type\":\"record\",\"name\":\"myrecord\",\"fields\":[{\"name\":\"f1\",\"type\":\"string\"}]}"
    # }
    echo "Importing $1: $2"

    # PUT SUBJECT in IMPORT Mode
    curl $CURL_OPTS_DST -X PUT -H "Content-Type: application/json" $DST_SCHEMA_REGISTRY/mode/$1?force=true --data '{"mode": "IMPORT"}'

    echo ""

    curl $CURL_OPTS_DST -X POST -H "Content-Type: application/json" --data ""$2"" $DST_SCHEMA_REGISTRY/subjects/$1/versions

    echo ""

    curl $CURL_OPTS_DST -X PUT -H "Content-Type: application/json" $DST_SCHEMA_REGISTRY/mode/$1 --data '{"mode": "READWRITE"}'

    echo ""
}

# Get list of subjects
# Assumption - Return value in the format: ["subject-1","subject-2",...]
IN_SUBJECT=$(curl $CURL_OPTS_SRC $SRC_SCHEMA_REGISTRY/subjects)

# Iterate through subject-version pairs, one by one
while IFS='[]",' read -ra SUBJECTS; do
  for i in "${SUBJECTS[@]}"; do
    if [ ! -z "$i" ]; then
        # Assumption: Source Schema Registry provides the /subjects/{subject-name}/versions endpoint to fetch the schema
        IN_VERSION=$(curl $CURL_OPTS_SRC $SRC_SCHEMA_REGISTRY/subjects/$i/versions)
        while IFS='[]",' read -ra VERSIONS; do
            for j in "${VERSIONS[@]}"; do
                if [ ! -z "$j" ]; then
                    SCHEMA=$(curl $CURL_OPTS_SRC $SRC_SCHEMA_REGISTRY/subjects/$i/versions/$j)
                    register_schema $i $SCHEMA
                fi
            done
            done <<< "$IN_VERSION"
    fi
  done
done <<< "$IN_SUBJECT"