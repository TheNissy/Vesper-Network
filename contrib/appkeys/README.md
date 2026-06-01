# AppKeys Gateway Integration (Vesper Wallet RPC)

This fork adds AppKeys spend authorization directly into `vesper-wallet-rpc` for:
- `transfer`
- `transfer_split`
- `sweep_all`

## Enable

Run wallet RPC with:

```bash
--appkeys-enforce-spend-gateway \
--appkeys-policy-file=/path/to/policy.json \
--appkeys-replay-window-seconds=120
```

When enabled, spend RPC requests without valid AppKeys metadata are rejected with:

`ERROR: DIRECT_WALLET_ACCESS_BLOCKED_BY_APPKEYS`

## Request fields

Spend methods now accept an `appkeys` object:

```json
"appkeys": {
  "app_key_id": "poker-app-key",
  "session_token": "session-token-1",
  "session_secret": "optional-session-secret-forwarded-by-middleware",
  "request_nonce": "nonce-123",
  "request_timestamp": 1717000000,
  "request_signature": "hex-signature"
}
```

If `session_token` is not preloaded in the policy file, `session_secret` can be forwarded by middleware.

## Signature format

Expected signature is:

`hex(HMAC_SHA256(session_secret, payload))`

Where payload is:

`request_nonce:request_timestamp:primary_destination:amount_total`

`primary_destination` is the first destination address for `transfer` / `transfer_split`,
or the sweep destination for `sweep_all`.

## Policy file

Use `contrib/appkeys/policy.example.json` as a template.

## Reload policy at runtime

Call JSON-RPC method:

`appkeys_reload_policy`

This reloads profiles and sessions from the configured policy file.

## vesper-wallet-cli AppKeys controls

`vesper-wallet-cli` now includes an `appkeys` command with subcommands:

- `appkeys load_policy <path>`
- `appkeys save_policy [path]`
- `appkeys reload`
- `appkeys status`
- `appkeys list`
- `appkeys create_key <app_key_id> <wallet_address> <spend_limit_per_tx> <daily_limit> <total_allocation> [allowed=<addr1,addr2>] [blocked=<addr1,addr2>]`
- `appkeys revoke_key <app_key_id> <0|1>`
- `appkeys create_session <session_token> <app_key_id> <session_secret> <expires_at_unix>`
- `appkeys revoke_session <session_token> <0|1>`
- `appkeys use_session <session_token>`
- `appkeys clear_session`
- `appkeys enforce_cli <0|1>`

When `appkeys enforce_cli 1` is enabled, spend commands (`transfer`, `sweep_all`, `sweep_account`, `sweep_below`, `sweep_single`) are blocked unless an active, valid AppKeys session is selected and policy checks pass.
