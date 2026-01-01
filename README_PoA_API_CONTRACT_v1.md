# UptimeProof PoA API — Contract (v1)

UptimeProof provides a **single source of truth** endpoint for Proof of Availability (PoA):

✅ **Truth endpoint**: `GET /poa/v1/verify`  
Everything else is either **health/debug** or **intentionally disabled** to avoid multiple “truths”.

---

## Base URL

- `https://uptimeproof.io`

---

## Endpoints

### 1) Truth (stable contract)
#### `GET /poa/v1/verify`
Returns the **canonical PoA verification payload**.

This is the only endpoint you should use to make “UP/DOWN” decisions.

---

### 2) Health (stable)
#### `GET /poa/v1/healthz`
Returns `{ "ok": true, "ts": "..." }` (+ branding).  
Use it to detect API availability independently from PoA checks.

---

### 3) Status (stable, summary)
#### `GET /poa/v1/status`
Short summary derived from `/poa/v1/verify`.

---

### 4) Debug (may change)
#### `GET /poa/v1/anchored`
Returns DNS anchor matching info (debug).

---

### Disabled endpoints
Some legacy/alternate endpoints may return:
- **HTTP 410**: `GONE (disabled). Public truth is only /poa/v1/verify.`

---

## Response Contract — `/poa/v1/verify`

### Top-level fields (stable)
- `schema` (string): **versioned schema id**, e.g. `uptimeproof:poa-verify:v1`
- `ts` (string, ISO8601 UTC): server timestamp at response time
- `verdict` (string): `"OK"` or `"FAIL"`
- `message` (string): human-readable explanation
- `service` (object): branding/identity (safe metadata)
- `links` (object): official URLs (status UI, verify JSON, etc.)

### Evidence objects (stable)
- `head` (object): canonical head from `latest.json`
  - `file`, `sha256`, `ts`, `sequence`, `mtime`
- `dns_anchor` (object): DNS TXT anchor parsing + local match
- `chain` (object): checks that head links to prev (integrity)
- `checks` (array): detailed check results with ids & statuses

### Canonical verification block (stable)
- `now_utc` (string): same as `ts` (UTC)
- `verification` (object):
  - `verdict`: `"VALID" | "INVALID" | "EXPIRED"`
  - `reason`: message
  - `checks` (booleans): normalized “machine truth”
- `proof` (object):
  - `ts`: timestamp of proved head
  - `head.file`, `head.sha256`
  - `proof_window_seconds`
  - `valid_until_utc`
- `anchor.dns` (object):
  - `file`, `sha256` seen in DNS TXT

---

## Meaning of `checks[]`

Each check item:
```json
{ "id": "...", "status": "OK|WARN|FAIL|UNKNOWN", "detail": "..." }
```

Current ids and meaning:

### `head_latest_json`
- **OK**: `latest.json` readable AND referenced head file exists on disk.
- **FAIL**: `latest.json` unreadable OR head file missing.

### `dns_matched_file_hash`
- **OK**: DNS TXT anchor matches a local export file by filename and/or sha256.
- **FAIL**: no local file matched the DNS sha256 (or DNS fetch failed).

### `chain_link`
- **OK**: previous file exists AND sha256 matches the `prev_sha256` in head.
- **FAIL**: previous file missing OR sha256 mismatch.
- **UNKNOWN**: no `prev_file/prev_sha256` yet (startup/first export).

### `dns_matches_head`
- **OK**: DNS TXT matches the current `latest.json` head (file+sha).
- **WARN**: DNS TXT matches **chain.prev** (lag by 1 step tolerated).
- **FAIL**: DNS TXT matches neither head nor tolerated previous head.

> Important: **WARN is acceptable** (propagation/cron delay), and is reflected by `verification.checks.dns_lag_ok = true`.

---

## Canonical machine checks (`verification.checks`)

These booleans are the recommended integration surface:

- `head_latest_json` (bool): head present & readable
- `dns_matches_head` (bool): strict DNS==head
- `dns_lag_ok` (bool): DNS==head OR DNS==prev (tolerate lag)
- `dns_matched_file_hash` (bool): DNS matched an export file locally
- `chain_ok` (bool): chain integrity OK (or UNKNOWN is acceptable)
- `not_expired` (bool): now <= `proof.valid_until_utc`

Recommended “UP” logic:
- Consider **UP** if:
  - `verdict == "OK"` AND
  - `verification.verdict == "VALID"` AND
  - `verification.checks.dns_lag_ok == true` AND
  - `verification.checks.not_expired == true`

---

## Example response (abridged)

```json
{
  "schema": "uptimeproof:poa-verify:v1",
  "ts": "2026-01-01T18:21:07Z",
  "verdict": "OK",
  "message": "OK: head matches DNS anchor and chain is valid.",

  "service": {
    "name": "UptimeProof",
    "project": "Proof of Availability (PoA)",
    "domain": "uptimeproof.io",
    "environment": "prod",
    "contact": "contact@uptimeproof.io",
    "branding": { "display_name": "UptimeProof PoA" }
  },
  "links": {
    "status_ui": "https://uptimeproof.io/status/",
    "verify_json": "https://uptimeproof.io/poa/v1/verify",
    "about": "https://uptimeproof.io/status/about.html"
  },

  "head": {
    "source": "latest.json",
    "file": "heartbeats_20260101_180105.json",
    "sha256": "92112357...20cf05",
    "ts": "2026-01-01T18:20:02Z",
    "sequence": 474,
    "mtime": 1767274802
  },

  "checks": [
    { "id": "head_latest_json", "status": "OK", "detail": "Head OK: heartbeats_..." },
    { "id": "dns_matched_file_hash", "status": "OK", "detail": "DNS TXT matched..." },
    { "id": "chain_link", "status": "OK", "detail": "Chain OK..." },
    { "id": "dns_matches_head", "status": "OK", "detail": "DNS TXT matches..." }
  ],

  "verification": {
    "verdict": "VALID",
    "checks": {
      "dns_lag_ok": true,
      "chain_ok": true,
      "not_expired": true
    }
  },

  "proof": {
    "proof_window_seconds": 300,
    "valid_until_utc": "2026-01-01T18:25:02Z"
  },
  "anchor": {
    "dns": {
      "file": "heartbeats_20260101_180105.json",
      "sha256": "92112357...20cf05"
    }
  }
}
```

---

## How to verify (client quickstart)

### 1) Call verify
```bash
curl -sS https://uptimeproof.io/poa/v1/verify | jq
```

### 2) Read canonical truth
- `verdict` must be `"OK"`
- `verification.verdict` should be `"VALID"`
- `verification.checks.dns_lag_ok` should be `true`

### 3) Check DNS anchor (optional manual)
```bash
dig +short TXT _poa.uptimeproof.io
```
Compare the `SHA256` and `FILE` with:
- `anchor.dns.sha256` / `anchor.dns.file` (or with `proof.head.*`)

---

## Stability & versioning

- `schema = uptimeproof:poa-verify:v1` identifies the contract version.
- This API is **backward compatible by default**:
  - ✅ new fields may be added
  - ❌ existing fields should not be removed/renamed in v1
- If breaking changes are needed, a new schema id will be published (v2).

---

## Support
- Contact: `contact@uptimeproof.io`
