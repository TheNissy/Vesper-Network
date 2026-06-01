# Vesper Network Testnet Operations (3+ Nodes)

This folder provides a stable local testnet bootstrap for Vesper Network, with deterministic node peering and miner launch.

## Scope

This is for testnet stability and deployment workflows only:

- Multi-node bootstrap and sync
- Miner connectivity
- Wallet-to-node operation
- Chain health checks

No protocol redesign is introduced.

## Prerequisites

- Build binaries:
  - `vesperd` (fallback `monerod` also supported by scripts)
  - `vesper-wallet-cli` (or legacy `monero-wallet-cli`)
  - `vesper-wallet-rpc` (optional)
- Typical build output path used by scripts:
  - `$HOME/Testnet-Vesper-Network/source/build/release/bin`

## 1) Start 3 local nodes

Linux/WSL:

```bash
bash work/monero/contrib/testnet/start_local_3node_testnet.sh
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File work\\monero\\contrib\\testnet\\start_local_3node_testnet.ps1 -AllowUnsyncMining
```

Default topology:

- node1: p2p `38180`, rpc `38181`, zmq `38182`
- node2: p2p `38190`, rpc `38191`, zmq `38192`, exclusive peer -> node1
- node3: p2p `38200`, rpc `38201`, zmq `38202`, exclusive peer -> node1

## 1b) One-command readiness check (local 3-node + mining)

```bash
bash work/monero/contrib/testnet/run_local_testnet_readiness.sh <TESTNET_WALLET_ADDRESS> 2
```

This script:

- starts 3 local nodes
- verifies same tip hash + peer connectivity
- starts mining on node1 and confirms height increases
- prints a YES/NO readiness checklist

## 2) Check sync/health

```bash
bash work/monero/contrib/testnet/status_local_3node_testnet.sh
```

Health is OK when:

- all nodes are online
- all nodes report the same `top_block_hash`
- each node has at least one peer

## 3) Start mining on node1

```bash
bash work/monero/contrib/testnet/start_node_mining.sh <TESTNET_WALLET_ADDRESS> 2 38181
```

- Args: `<address> [threads] [rpc_port]`
- Uses daemon RPC `/start_mining`

## 4) Wallet usage against local testnet

Open wallet against node1:

```bash
./vesper-wallet-cli --testnet --daemon-address 127.0.0.1:38181
```

Create second wallet against node2/node3 and transfer between them to validate propagation.

## 4b) LAN mode (private network, no internet bootstrap)

Seed node (machine A):

```bash
bash work/monero/contrib/testnet/start_lan_seed_node.sh
```

Peer node (machine B):

```bash
bash work/monero/contrib/testnet/start_lan_peer_node.sh <MACHINE_A_LAN_IP>:38180
```

Example:

```bash
bash work/monero/contrib/testnet/start_lan_peer_node.sh 192.168.1.19:38180
```

## 5) Stop nodes

```bash
bash work/monero/contrib/testnet/stop_local_3node_testnet.sh
```

## Notes

- The daemon now supports `--allow-testnet-mining-without-sync` to avoid local testnet deadlock where mining start can remain BUSY while peers are still stabilizing.
- On non-mainnet, this behavior is enabled by default when the option is not explicitly provided.
- Mainnet behavior remains unchanged.
- Built-in public seed IPs are not used for testnet/stagenet in this fork; use explicit peers (`--add-exclusive-node`, `--seed-node`, or the scripts above).
