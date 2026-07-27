# bcnode.io Operations Manual

Current purpose: operate `bcnode.io` as a small, independent, COSIGO-operated public Bitcoin node with public status pages, masked peer-load visibility, rate-limited historical block serving, and automatic peer-quality protection.

Last major operating state:
- Public node domain: `bcnode.io`
- Server hostname: `server1.bcnode.io`
- SSH alias from operator machine: `node`
- Bitcoin service: `bitcoind`
- Current target peer cap: `maxconnections=200`
- Node mode: pruned
- Public dashboard: `https://bcnode.io/network.html`
- Peer-load page: `https://bcnode.io/peer-load.html`
- Explorer: `https://explorer.bcnode.io/`

---

## Why this is published

bcnode.io publishes these basic operations notes so other small Bitcoin node operators can see how this node is run: peer limits, public status generation, masked peer telemetry, bandwidth policy, and automatic peer-quality controls.

This node is operator-funded in both time and money. It welcomes ordinary Bitcoin peer connections, but it is not intended to be free backend infrastructure for commercial, indexing, gambling, exchange, analytics, wallet-backend, or other high-volume services. Those services should operate and fund their own Bitcoin infrastructure.

The operating goal is normality: stable service, honest public peer access, controlled bandwidth, low server pressure, and automatic trimming of peers that repeatedly create poor connection quality or excessive load.

---

## 1. Core paths

### Site repo

    /srv/sites/bcnode.io

Important public files:

    /srv/sites/bcnode.io/index.html
    /srv/sites/bcnode.io/network.html
    /srv/sites/bcnode.io/peer-load.html
    /srv/sites/bcnode.io/status.json
    /srv/sites/bcnode.io/peer-load.json

Notes:
- `index.html` is the bcnode home page.
- `network.html` is the public Bitcoin node dashboard.
- `peer-load.html` is the masked public peer-load watch page.
- `status.json` is generated status data.
- `peer-load.json` is generated peer-load data.
- Generated JSON files are not committed to git.

### Bitcoin Core

    /usr/local/bin/bitcoind
    /usr/local/bin/bitcoin-cli
    /var/lib/bitcoind/.bitcoin/bitcoin.conf

Always use this config path with `bitcoin-cli`:

    bitcoin-cli -conf=/var/lib/bitcoind/.bitcoin/bitcoin.conf getnetworkinfo

Do not rely on plain `bitcoin-cli` from a normal user shell. It may look under the wrong home directory.

### Public status generator

    /usr/local/sbin/bcnode-status

Likely output:

    /srv/sites/bcnode.io/status.json

Timer/service names may include:

    bcnode-status.service
    bcnode-status.timer

### Peer-load generator

    /usr/local/sbin/bcnode-peer-load-status

Systemd:

    /etc/systemd/system/bcnode-peer-load-status.service
    /etc/systemd/system/bcnode-peer-load-status.timer

Output:

    /srv/sites/bcnode.io/peer-load.json

Purpose:
- Reads Bitcoin Core peer data.
- Masks public peer IPs.
- Publishes public peer activity tables.
- Does not expose private RPC.

### Peer guard

    /usr/local/sbin/bcnode-peer-guard

Systemd:

    /etc/systemd/system/bcnode-peer-guard.service
    /etc/systemd/system/bcnode-peer-guard.timer

State/logs:

    /var/lib/bcnode-peer-guard/state.json
    /var/log/bcnode-peer-guard.log

Purpose:
- Automatically disconnects poor-quality peers.
- Temporarily blocks persistent high-latency peers.
- Trims high sustained bandwidth peers.
- Gives healthier normal peers a better chance to occupy slots.
- Protects the operator-owned `bcnode_dot_io` peer.

---

## 2. Working tree view

    /srv/sites/bcnode.io
    ├── index.html
    ├── network.html
    ├── peer-load.html
    ├── status.json              # generated, not committed
    ├── peer-load.json           # generated, not committed
    ├── BCNODE-OPS.md            # this manual
    ├── backups/
    └── .git/

    /usr/local/sbin
    ├── bcnode-status
    ├── bcnode-peer-load-status
    └── bcnode-peer-guard

    /etc/systemd/system
    ├── bitcoind.service
    ├── bcnode-status.service
    ├── bcnode-status.timer
    ├── bcnode-peer-load-status.service
    ├── bcnode-peer-load-status.timer
    ├── bcnode-peer-guard.service
    └── bcnode-peer-guard.timer

    /var/lib/bitcoind/.bitcoin
    └── bitcoin.conf

    /var/lib/bcnode-peer-guard
    └── state.json

    /var/log
    └── bcnode-peer-guard.log

---

## 3. Basic operating flow

    Bitcoin Core bitcoind
            |
            v
    bitcoin-cli RPC checks
            |
            +--> bcnode-status generator
            |       |
            |       v
            |   status.json
            |       |
            |       v
            |   network.html dashboard
            |
            +--> bcnode-peer-load-status generator
            |       |
            |       v
            |   peer-load.json
            |       |
            |       v
            |   peer-load.html public masked peer page
            |
            +--> bcnode-peer-guard
                    |
                    +--> disconnectnode for bad peers
                    +--> setban exact IP for temporary blocks
                    +--> logs to /var/log/bcnode-peer-guard.log

---

## 4. Current public policy

bcnode.io welcomes ordinary Bitcoin peer connections.

This is a small, independently operated, operator-funded public Bitcoin node. Commercial, indexing, gambling, exchange, analytics, wallet-backend, or other high-volume services should operate their own Bitcoin infrastructure instead of relying on this node.

Peer behavior is monitored from local node telemetry such as:
- traffic
- latency
- connection age
- in-flight request data

Peers showing repeated extreme latency, unusually high sustained traffic, or repeated connection load may be disconnected or temporarily blocked to protect node stability.

This is not a Bitcoin peer approval system, trust endorsement, transaction priority service, private RPC service, or consensus privilege.

---

## 5. Peer guard policy

Current intended behavior:

    ordinary peer:
      leave alone

    persistent high-ping peer:
      15+ minutes connected
      10,000+ ms ping
      disconnect + 6-hour exact-IP timeout

    extreme ping peer:
      60,000+ ms ping
      disconnect + 6-hour exact-IP timeout

    high sustained bandwidth peer:
      60+ minutes connected
      node has sent 1.5 GiB+ in this connection
      disconnect

    high sustained sent-rate peer:
      30+ minutes connected
      1.0 MiB/min+ sent rate
      disconnect

    repeat bad peer:
      3 strikes in 24 hours
      6-hour exact-IP timeout

Important:
- Guard only polices inbound public peers.
- Guard should not police outbound peers.
- Guard protects the operator peer label `bcnode_dot_io`.
- Exact-IP blocks are preferred.
- Do not ban whole ranges unless there is clear reason.

---

## 6. Daily quick health check

Run on the node:

    sudo bash -lc '
    CONF=/var/lib/bitcoind/.bitcoin/bitcoin.conf

    echo "===== cap / peers ====="
    grep -nE "^[[:space:]]*maxconnections=" "$CONF"
    bitcoin-cli -conf="$CONF" getnetworkinfo | python3 -c "
    import json,sys
    d=json.load(sys.stdin)
    print(\"connections:\", d.get(\"connections\"))
    print(\"connections_in:\", d.get(\"connections_in\"))
    print(\"connections_out:\", d.get(\"connections_out\"))
    print(\"networkactive:\", d.get(\"networkactive\"))
    "

    echo
    echo "===== upload cap ====="
    bitcoin-cli -conf="$CONF" getnettotals | python3 -c "
    import json,sys
    d=json.load(sys.stdin)
    u=d.get(\"uploadtarget\",{})
    target=u.get(\"target\",0) or 0
    left=u.get(\"bytes_left_in_cycle\",0) or 0
    used=max(0,target-left)
    pct=(used/target*100) if target else 0
    print(\"target_gb:\", round(target/1024/1024/1024,2))
    print(\"used_gb:\", round(used/1024/1024/1024,2))
    print(\"remaining_gb:\", round(left/1024/1024/1024,2))
    print(\"used_pct:\", round(pct,3))
    print(\"target_reached:\", u.get(\"target_reached\"))
    print(\"serve_historical_blocks:\", u.get(\"serve_historical_blocks\"))
    "

    echo
    echo "===== memory ====="
    free -h
    systemctl show bitcoind -p MemoryCurrent -p MemoryPeak -p MemorySwapCurrent -p MemorySwapPeak

    echo
    echo "===== pressure ====="
    cat /proc/pressure/cpu
    cat /proc/pressure/memory

    echo
    echo "===== peer guard recent actions ====="
    tail -40 /var/log/bcnode-peer-guard.log 2>/dev/null || true
    '

Healthy signs:
- `networkactive: True`
- outbound peers around `10`
- peer count rising toward configured cap
- CPU load light
- memory pressure near `0`
- no repeated bitcoind restarts
- peer guard log mostly `ok no_actions`, with occasional disconnects/temp-bans

---

## 7. Check bitcoind status

    sudo systemctl --no-pager --full status bitcoind | sed -n "1,40p"

Restart only when needed:

    sudo systemctl restart bitcoind

Restarting bitcoind drops all peers. Peer count may take hours or days to refill.

---

## 8. Check maxconnections

    sudo grep -nE "^[[:space:]]*maxconnections=" /var/lib/bitcoind/.bitcoin/bitcoin.conf

Current target:

    maxconnections=200

Do not raise again until 200 is boring for several days.

Possible future ladder:

    200 current test
    225 next if stable
    250 target if 225 is stable

---

## 9. Change maxconnections safely

Example for target 225:

    sudo bash -lc '
    set -euo pipefail

    CONF=/var/lib/bitcoind/.bitcoin/bitcoin.conf
    SERVICE=bitcoind
    TARGET=225
    STAMP=$(date -u +%Y%m%d-%H%M%SZ)

    echo "===== before change ====="
    grep -nE "^[[:space:]]*maxconnections=" "$CONF" || true

    echo
    echo "===== backup bitcoin.conf ====="
    cp -a "$CONF" "$CONF.backup-maxconnections-$STAMP"
    echo "Backup: $CONF.backup-maxconnections-$STAMP"

    echo
    echo "===== set maxconnections=$TARGET ====="
    if grep -qE "^[[:space:]]*maxconnections=" "$CONF"; then
      sed -i -E "s/^[[:space:]]*maxconnections=.*/maxconnections=$TARGET/" "$CONF"
    else
      printf "\nmaxconnections=%s\n" "$TARGET" >> "$CONF"
    fi

    echo
    echo "===== confirm config ====="
    grep -nE "^[[:space:]]*maxconnections=" "$CONF"

    echo
    echo "===== restart bitcoind ====="
    systemctl restart "$SERVICE"

    sleep 15

    echo
    echo "===== peer summary ====="
    bitcoin-cli -conf="$CONF" getnetworkinfo | python3 -c "
    import json,sys
    d=json.load(sys.stdin)
    print(\"networkactive:\", d.get(\"networkactive\"))
    print(\"connections:\", d.get(\"connections\"))
    print(\"connections_in:\", d.get(\"connections_in\"))
    print(\"connections_out:\", d.get(\"connections_out\"))
    "

    echo
    echo "===== memory / pressure ====="
    free -h
    systemctl show "$SERVICE" -p MemoryCurrent -p MemoryPeak -p MemorySwapCurrent -p MemorySwapPeak
    cat /proc/pressure/cpu
    cat /proc/pressure/memory
    '

---

## 10. Peer guard operations

Check timer:

    systemctl --no-pager --full status bcnode-peer-guard.timer | sed -n "1,30p"

Run guard once:

    sudo systemctl reset-failed bcnode-peer-guard.service || true
    sudo systemctl start bcnode-peer-guard.service

Check service:

    systemctl --no-pager --full status bcnode-peer-guard.service | sed -n "1,70p"

Good oneshot result:

    Active: inactive (dead)
    code=exited, status=0/SUCCESS

Check guard log:

    sudo tail -80 /var/log/bcnode-peer-guard.log

Check important rules are installed:

    sudo grep -nE "LATENCY_BAN_SECONDS|latency_tempban|persistent_high_ping|EXTREME_PING_MS|HIGH_PING_MS|HIGH_USE_SENT_MIB|HIGH_RATE_SENT_MIB_MIN" /usr/local/sbin/bcnode-peer-guard

Current expected lines include:
- `PERSISTENT_HIGH_PING_MIN_AGE_MIN = 15`
- `LATENCY_BAN_SECONDS = 6 * 60 * 60`
- `reasons.append("persistent_high_ping")`
- `rpc("setban", ip, "add", str(LATENCY_BAN_SECONDS))`

---

## 11. Manual peer actions

Disconnect one peer by node id:

    sudo bitcoin-cli -conf=/var/lib/bitcoind/.bitcoin/bitcoin.conf disconnectnode "" NODE_ID

Example:

    sudo bitcoin-cli -conf=/var/lib/bitcoind/.bitcoin/bitcoin.conf disconnectnode "" 446

Temporary exact-IP block for 6 hours:

    sudo bitcoin-cli -conf=/var/lib/bitcoind/.bitcoin/bitcoin.conf setban IP.ADDRESS.HERE add 21600

Temporary exact-IP block for 24 hours:

    sudo bitcoin-cli -conf=/var/lib/bitcoind/.bitcoin/bitcoin.conf setban IP.ADDRESS.HERE add 86400

List banned peers:

    sudo bitcoin-cli -conf=/var/lib/bitcoind/.bitcoin/bitcoin.conf listbanned

Remove a ban:

    sudo bitcoin-cli -conf=/var/lib/bitcoind/.bitcoin/bitcoin.conf setban IP.ADDRESS.HERE remove

Operator rule:
- disconnect for first bad behavior
- temp-ban repeated bad behavior
- avoid permanent bans unless absolutely necessary
- avoid /24 or range bans unless there is clear reason

---

## 12. Peer-load page operations

Check peer-load generator timer:

    systemctl --no-pager --full status bcnode-peer-load-status.timer | sed -n "1,30p"

Run manually:

    sudo systemctl start bcnode-peer-load-status.service

Check generated JSON:

    ls -lh /srv/sites/bcnode.io/peer-load.json
    head -40 /srv/sites/bcnode.io/peer-load.json

Permissions should allow public reading:

    ls -lh /srv/sites/bcnode.io/peer-load.json

If needed:

    sudo chmod 644 /srv/sites/bcnode.io/peer-load.json

---

## 13. Site editing workflow

Go to repo:

    cd /srv/sites/bcnode.io

Check status:

    git status --short

Before edits, make backup:

    STAMP="$(date -u +%Y%m%d-%H%M%SZ)"
    mkdir -p backups
    cp -a network.html "backups/network.html.$STAMP"

Review diff:

    git diff -- index.html network.html peer-load.html BCNODE-OPS.md

Commit:

    git add index.html network.html peer-load.html BCNODE-OPS.md
    git commit -m "Describe change here"

Push:

    git push

---

## 14. Current important public wording

High-use notice:

    bcnode.io welcomes ordinary Bitcoin peer connections. This is a small, independently operated, operator-funded public Bitcoin node. Commercial, indexing, gambling, exchange, analytics, wallet-backend, or other high-volume services should operate their own Bitcoin infrastructure instead of relying on this node. Peer behavior is monitored from local node telemetry such as traffic, latency, connection age, and in-flight request data. Peers showing repeated extreme latency, unusually high sustained traffic, or repeated connection load may be disconnected or temporarily blocked to protect node stability.

Operator peer wording:

    Operator-verified peers are operator-controlled connections used only for bcnode.io connectivity checks. They are not endorsements, rankings, approvals, transaction-priority services, private RPC access, or consensus privileges.

Operator peer public IP must remain masked:

    189.180.145.x

Do not publish the full home/operator IP address.

---

## 15. 200-peer test plan

Current test:

    maxconnections=200

Expected behavior:
- peer count may take days to refill after restart
- outbound should return to about 10 quickly
- inbound refills slowly
- guard may slow total count by removing poor peers
- goal is not exactly 200 peers at all times
- goal is mostly healthy peers

Success signs:
- 180-200 peers
- outbound 10
- CPU load light
- CPU pressure low
- memory pressure 0 or near 0
- bitcoind accounted memory steady
- swap not steadily climbing
- daily upload cap reasonable
- guard log mostly `ok no_actions`
- occasional disconnect/temp-ban only

Next possible steps:
- hold 200 for several days
- if boring, consider 225
- if 225 is boring, consider 250
- 250 happy normal peers is the target, not 250 bad peers

---

## 16. Troubleshooting quick map

Problem: peer count low after restart
- Normal.
- Wait hours/days.
- Do not keep restarting.

Problem: guard log missing
- Guard may not have run or may be failing.
- Check service:

    systemctl --no-pager --full status bcnode-peer-guard.service | sed -n "1,80p"

Problem: guard service failed
- Run syntax check:

    sudo python3 -m py_compile /usr/local/sbin/bcnode-peer-guard

Problem: high-ping peer not kicked
- Confirm guard timer active.
- Confirm service success.
- Confirm rule exists:

    sudo grep -nE "PERSISTENT_HIGH_PING|persistent_high_ping|LATENCY_BAN_SECONDS|latency_tempban" /usr/local/sbin/bcnode-peer-guard

Problem: public page says data unavailable
- Check JSON file exists and is readable:

    ls -lh /srv/sites/bcnode.io/peer-load.json
    sudo chmod 644 /srv/sites/bcnode.io/peer-load.json

Problem: plain bitcoin-cli fails
- Use config path:

    bitcoin-cli -conf=/var/lib/bitcoind/.bitcoin/bitcoin.conf getnetworkinfo

Problem: need full logs
- bitcoind:

    journalctl -u bitcoind --no-pager -n 120

- peer guard:

    sudo tail -120 /var/log/bcnode-peer-guard.log

- peer-load generator:

    journalctl -u bcnode-peer-load-status.service --no-pager -n 120

---

## 17. Operating philosophy

bcnode.io is useful public Bitcoin infrastructure, but it is not unlimited free backend infrastructure.

The goal is:

    more normal Bitcoin peers
    fewer useless high-latency squatters
    fewer commercial-style high-volume drains
    stable server resource use
    minimal operator babysitting

Good node operation is boring:
- healthy peers
- stable memory
- low pressure
- controlled upload
- automatic trimming
- clear public policy
