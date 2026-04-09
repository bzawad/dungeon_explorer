#!/usr/bin/env bash
APP_NAME="$(<app_name.txt)"
gigalixir ps:scale --replicas=0 -a "${APP_NAME}"
