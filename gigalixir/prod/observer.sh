#!/usr/bin/env bash
APP_NAME="$(<app_name.txt)"
gigalixir ps:observer -a "${APP_NAME}"
