#!/usr/bin/env bash
APP_NAME="$(<app_name.txt)"
gigalixir ps:migrate -a "${APP_NAME}"
