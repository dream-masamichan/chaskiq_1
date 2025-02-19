#!/bin/bash
set -e

echo "Precompiling assets..."
bundle exec rails assets:precompile

exec "$@"