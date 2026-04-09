#!/usr/bin/env bash
APP_NAME="$(<app_name.txt)"
gigalixir ps:remote_console -a "${APP_NAME}"
