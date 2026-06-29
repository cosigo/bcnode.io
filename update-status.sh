#!/bin/bash
set -euo pipefail

# Canonical bcnode.io status generator.
# Public site root is /srv/sites/bcnode.io via Caddy.
exec /usr/local/bin/bcnode-status-json
