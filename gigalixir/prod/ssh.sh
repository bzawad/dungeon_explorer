#!/usr/bin/env bash
APP_NAME="$(<app_name.txt)"
gigalixir ps:ssh -a "${APP_NAME}"
