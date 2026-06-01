param(
  [string]$BinDir = "$HOME\\Testnet-Vesper-Network\\source\\build\\release\\bin",
  [string]$DataRoot = "$HOME\\tvesper-localnet",
  [string]$P2PBindIP = "0.0.0.0",
  [string]$RPCBindIP = "127.0.0.1",
  [int]$LogLevel = 1,
  [switch]$AllowUnsyncMining
)

$daemonExe = Join-Path $BinDir "vesperd.exe"
if (-not (Test-Path $daemonExe)) {
  $daemonExe = Join-Path $BinDir "monerod.exe"
}
if (-not (Test-Path $daemonExe)) {
  Write-Error "vesperd.exe/monerod.exe not found in $BinDir"
  exit 1
}

New-Item -ItemType Directory -Force -Path $DataRoot | Out-Null

function Start-Node {
  param(
    [string]$Name,
    [int]$P2PPort,
    [int]$RPCPort,
    [int]$ZMQPort,
    [string[]]$ExtraArgs
  )

  $nodeDir = Join-Path $DataRoot $Name
  New-Item -ItemType Directory -Force -Path $nodeDir | Out-Null

  $args = @(
    "--testnet",
    "--non-interactive",
    "--detach",
    "--no-igd",
    "--hide-my-port",
    "--disable-dns-checkpoints",
    "--check-updates", "disabled",
    "--confirm-external-bind",
    "--data-dir", $nodeDir,
    "--log-file", (Join-Path $nodeDir "monerod.log"),
    "--log-level", "$LogLevel",
    "--p2p-bind-ip", $P2PBindIP,
    "--p2p-bind-port", "$P2PPort",
    "--rpc-bind-ip", $RPCBindIP,
    "--rpc-bind-port", "$RPCPort",
    "--zmq-rpc-bind-port", "$ZMQPort"
  )

  if ($AllowUnsyncMining) {
    $args += "--allow-testnet-mining-without-sync"
  }

  if ($ExtraArgs) {
    $args += $ExtraArgs
  }

  & $daemonExe @args
  Write-Host "Started $Name (p2p:$P2PPort rpc:$RPCPort zmq:$ZMQPort)"
}

Start-Node -Name node1 -P2PPort 38180 -RPCPort 38181 -ZMQPort 38182
Start-Node -Name node2 -P2PPort 38190 -RPCPort 38191 -ZMQPort 38192 -ExtraArgs @("--add-exclusive-node", "127.0.0.1:38180")
Start-Node -Name node3 -P2PPort 38200 -RPCPort 38201 -ZMQPort 38202 -ExtraArgs @("--add-exclusive-node", "127.0.0.1:38180")

Write-Host "All 3 nodes started."
