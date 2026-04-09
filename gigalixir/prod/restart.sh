#!/usr/bin/env bash
APP_NAME="$(<app_name.txt)"
gigalixir ps:restart -a "${APP_NAME}"
