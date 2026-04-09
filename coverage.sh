#!/usr/bin/env bash
MIX_ENV=test mix coveralls.html
open cover/excoveralls.html
