#!/bin/bash
set -e

# Restore the database.
echo "Restoring datbase from replica"
litestream restore -v -if-replica-exists -o /pb_data/data.db "${REPLICA_URL}"

# Run litestream with your app as the subprocess.
exec litestream replicate -exec "/usr/local/bin/pocketbase serve --http 0.0.0.0:8090 --dir /pb_data"

