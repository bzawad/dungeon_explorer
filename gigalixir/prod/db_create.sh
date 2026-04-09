#!/usr/bin/env bash
APP_NAME="$(<app_name.txt)"
gigalixir pg:create --free -y -a "${APP_NAME}"
