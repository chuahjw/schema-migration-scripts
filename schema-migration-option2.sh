#!/bin/bash

###### Edit this Section accordingly ######

DST_SCHEMA_REGISTRY="http://localhost:8082"
SCHEMAS_FOLDER="$1"

# TLS Encryption
# DST_CACERT="/path/to/dst/cacert.crt"

# Authentication
# DST_USER_PASSWORD="abc123:abc123"

###### End Edit ######

# Check if Schemas folder is specified
if [ -z "$SCHEMAS_FOLDER" ]; then
       echo "Usage: $0 <PATH TO SCHEMAS FOLDER>"
       exit 1
fi

echo "Schema Migration Tool (Option 2): Register Schemas from Files"
echo "CHECK: Ensure that Destination Schema Registry mode.mutability=true before continuing"
read -p "Press ENTER to continue..." REPLY

# Construct CURL_OPTS
CURL_OPTS_DST="-s"

if [ ! -z "$DST_CACERT" ]; then
    CURL_OPTS_DST="$CURL_OPTS_DST --cacert $DST_CACERT"
fi

if [ ! -z "$SRC_USER_PASSWORD" ]; then
    CURL_OPTS_DST="$CURL_OPTS_DST -u $DST_USER_PASSWORD"
fi

# echo "Constructed CURL_OPTS:"
# echo "DST: $CURL_OPTS_DST"
# echo

# Import Schema into Destination Schema Registry
register_schema_file () {
    # $1: subject name
    # $2: schema in JSON format
    # Sample schema: 
    # {
    #     "subject": "test-topic-value",
    #     "version": 1,
    #     "id": 1,
    #     "schema": "{\"type\":\"record\",\"name\":\"myrecord\",\"fields\":[{\"name\":\"f1\",\"type\":\"string\"}]}"
    # }
    echo "Importing $1 from $2"

    # PUT SUBJECT in IMPORT Mode
    curl $CURL_OPTS_DST -X PUT -H "Content-Type: application/json" $DST_SCHEMA_REGISTRY/mode/$1?force=true --data '{"mode": "IMPORT"}'

    echo ""

    curl $CURL_OPTS_DST -X POST -H "Content-Type: application/json" --data ""@$2"" $DST_SCHEMA_REGISTRY/subjects/$1/versions

    echo ""

    curl $CURL_OPTS_DST -X PUT -H "Content-Type: application/json" $DST_SCHEMA_REGISTRY/mode/$1 --data '{"mode": "READWRITE"}'

    echo ""
}

for i in $SCHEMAS_FOLDER/*.json;
    do 
        echo "Reading schema file: $i"
        SCHEMA_SUBJECT=$(jq -r .subject $i)
        echo "Extracted subject: $SCHEMA_SUBJECT"
        register_schema_file $SCHEMA_SUBJECT $i
    done
