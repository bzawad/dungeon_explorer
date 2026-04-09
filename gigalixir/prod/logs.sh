#!/usr/bin/env bash
APP_NAME="$(<app_name.txt)"
gigalixir logs -t -a "${APP_NAME}"
