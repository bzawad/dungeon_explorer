#!/usr/bin/env bash
APP_NAME="$(<app_name.txt)"
gigalixir pg:psql -a "${APP_NAME}"
