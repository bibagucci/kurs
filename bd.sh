#!/bin/bash
#this will connect to a remote couchdb, get all its databases and create on the local couchdb the replication docs
TARGET='http://127.0.0.1:5984'
TARGET2='http://127.0.0.1:6984'
TARGET_PASS='foo:bar'
TARGET_USER='foo'
MASTER='https://couchdb.myserver.com'
MASTER_PASS='foo:bar'

PASS_MASTER=echo -n $MASTER_PASS | base64
PASS_TARGET=echo -n $TARGET_PASS | base64

dbs=$(curl -H  "Authorization: Basic $PASS_MASTER" -s $MASTER'/_all_dbs' | python -c "import sys, json; s= ' '.join(json.load(sys.stdin)).replace('_global_changes','').replace('_replicator','').replace('_users',''); print(s) ")

for DB in $dbs; do
V=$(cat <<EOF
{
 "_id": "$DB-pull",
  "user_ctx": {
    "name": "$TARGET_USER",
    "roles": [
      "_admin",
      "_reader",
      "_writer"
    ]
  },
  "source": {
    "headers": {
      "Authorization": "Basic $PASS_MASTER"
    },
    "url": "$MASTER/$DB"
  },
  "target": {
    "headers": {
      "Authorization": "Basic $PASS_TARGET"
    },
    "url": "$TARGET/$DB"
  },
  "create_target": true,
  "continuous": true,
  "owner": "$TARGET_USER"
}
EOF
)


    curl -X PUT $TARGET2/_replicator/$DB-pull \
   -H "Accept: application/json" \
   -H "Authorization: Basic $PASS_TARGET" \
   -H "Content-Type: application/json" \
         -d "$V"
done
