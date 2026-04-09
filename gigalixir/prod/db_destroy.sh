#!/usr/bin/env bash
APP_NAME="$(<app_name.txt)"
jq --version >/dev/null
if [ $? -ne 0 ]; then
    echo "Requires jq"
    echo "Try: brew install jq"
    exit 1
fi
gigalixir ps:scale --replicas=0 -a "${APP_NAME}"
gigalixir pg:destroy -y --database_id $(gigalixir pg -a "${APP_NAME}" | jq -r '.[].id') -a "${APP_NAME}"
