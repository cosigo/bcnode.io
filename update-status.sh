#!/bin/bash

CONF="/var/lib/bitcoind/.bitcoin/bitcoin.conf"
OUT="/var/www/bcnode.io/status.json"
TMP=$(mktemp)

BLOCKCHAIN=$(sudo -u bitcoin bitcoin-cli -conf="$CONF" getblockchaininfo)
NETWORK=$(sudo -u bitcoin bitcoin-cli -conf="$CONF" getnetworkinfo)
MEMPOOL=$(sudo -u bitcoin bitcoin-cli -conf="$CONF" getmempoolinfo)
UPTIME=$(sudo -u bitcoin bitcoin-cli -conf="$CONF" uptime)

jq -n \
  --argjson b "$BLOCKCHAIN" \
  --argjson n "$NETWORK" \
  --argjson m "$MEMPOOL" \
  --arg uptime "$UPTIME" \
'{
  chain: $b.chain,
  blocks: $b.blocks,
  headers: $b.headers,
  verificationprogress: $b.verificationprogress,
  initialblockdownload: $b.initialblockdownload,
  pruned: $b.pruned,
  connections: $n.connections,
  version: $n.subversion,
  mempool_tx: $m.size,
  mempool_bytes: $m.bytes,
  uptime_seconds: ($uptime | tonumber)
}' > "$TMP" && sudo mv "$TMP" "$OUT"
sudo chmod 644 "$OUT"
