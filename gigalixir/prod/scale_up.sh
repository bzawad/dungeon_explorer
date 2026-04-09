#!/usr/bin/env bash
APP_NAME="$(<app_name.txt)"
gigalixir ps:scale --replicas=1 -a "${APP_NAME}"
