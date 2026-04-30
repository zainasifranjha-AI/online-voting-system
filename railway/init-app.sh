#!/usr/bin/env bash
set -euo pipefail

mkdir -p database
if [ ! -f database/database.sqlite ]; then
  touch database/database.sqlite
fi

php artisan migrate --force
php artisan storage:link || true

