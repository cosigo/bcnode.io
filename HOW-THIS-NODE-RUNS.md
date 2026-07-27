# How bcnode.io Runs

bcnode.io is a small, independent, operator-funded Bitcoin node operated as COSIGO public infrastructure.

The node is public, but it is not unlimited free backend infrastructure. Bandwidth, uptime, monitoring, storage, and maintenance all require time and money.

This document explains the public operating model in plain terms so other small Bitcoin node operators can see one practical way to run a responsible public node.

---

## Purpose

bcnode.io exists to provide ordinary Bitcoin peer connectivity and public node visibility.

The goal is simple:

- stay online
- serve normal Bitcoin peers
- publish basic node health
- avoid exposing private RPC
- control bandwidth
- trim poor-quality or abusive peer behavior
- keep the node useful without constant manual policing

---

## Public services

The public site includes:

- main node page: `https://bcnode.io/`
- live node dashboard: `https://bcnode.io/network.html`
- masked peer-load watch: `https://bcnode.io/peer-load.html`
- public block explorer: `https://explorer.bcnode.io/`

The dashboard shows basic node health such as:

- online status
- block height
- peer count
- inbound and outbound connections
- pruned mode status
- mempool size
- daily historical upload cap
- basic server health

The peer-load page shows masked peer behavior. It is meant to show patterns, not expose private users.

---

## Privacy and safety

bcnode.io does not publish private Bitcoin RPC access.

Public peer information is masked. The purpose is to show node load and behavior patterns, not to expose ordinary users.

The operator connectivity-check peer is also masked.

No private keys, wallet funds, RPC cookies, passwords, or admin tokens belong in public documentation.

---

## Bandwidth policy

bcnode.io welcomes ordinary Bitcoin peer connections.

This is a small, independently operated, operator-funded public Bitcoin node. Commercial, indexing, gambling, exchange, analytics, wallet-backend, or other high-volume services should operate their own Bitcoin infrastructure instead of relying on this node.

Peer behavior is monitored from local node telemetry such as:

- traffic
- latency
- connection age
- in-flight request data

Peers showing repeated extreme latency, unusually high sustained traffic, or repeated connection load may be disconnected or temporarily blocked to protect node stability.

High-bandwidth users may request operator review or support.

---

## Peer-quality controls

The node is configured to accept many public peers, but peer slots are not treated as unlimited.

The node automatically trims peers that repeatedly show poor connection quality or excessive load.

Examples of behavior that may be trimmed:

- very high latency
- repeated poor responsiveness
- unusually heavy sustained bandwidth use
- repeated connection behavior that harms node stability

This protects normal Bitcoin peers by freeing slots for healthier connections.

---

## What this is not

bcnode.io does not provide:

- paid transaction priority
- private RPC access
- mining services
- wallet-backend guarantees
- exchange infrastructure
- indexing infrastructure
- peer endorsement
- peer ranking
- consensus privilege

A peer being connected to bcnode.io does not mean that peer is trusted, approved, ranked, or endorsed.

---

## Why publish this?

Many small operators run Bitcoin nodes quietly, but public nodes can attract heavy users that should really run their own infrastructure.

Publishing this operating model helps show that a small node can be:

- public
- useful
- transparent
- rate-limited
- privacy-conscious
- maintained responsibly
- protected from excessive load

The goal is normality: stable service for ordinary Bitcoin peers without letting high-volume users consume the node as free backend infrastructure.

---

## Operator philosophy

Good public Bitcoin infrastructure should be boring.

A healthy node should show:

- stable uptime
- reasonable peer count
- controlled bandwidth
- low server pressure
- normal memory use
- few manual interventions
- clear public policy

bcnode.io is paid for and maintained by its operator. Other high-volume users are welcome to run and fund their own Bitcoin nodes however they like.

