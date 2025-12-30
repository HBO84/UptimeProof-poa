# Proof of Availability (PoA)
## A Lightweight, Verifiable Uptime and Data Availability Attestation System

Version: 1.0  
Date: 2025-12-30  
Project: UptimeProof PoA  
Website: https://uptimeproof.io  
Repository: https://github.com/HBO84/uptimeproof-poa  

---

## 1. Abstract

Proof of Availability (PoA) is a lightweight cryptographic framework designed to provide public, verifiable evidence that a service or dataset was available at a given point in time.

Unlike traditional uptime monitoring services, PoA does not rely on trust in a centralized dashboard.
Instead, it uses cryptographic hashes, chained evidence files, and a public DNS anchor.

Any third party can independently verify availability claims offline, without API access, and without trusting the operator.

---

## 2. Problem Statement

Service providers frequently claim uptime, availability, or historical presence of APIs, datasets, or services.
However, most existing solutions suffer from:

- Closed-source dashboards
- Centralized trust assumptions
- No cryptographic proof
- No anti-rollback protection
- No retroactive verification

As a result, uptime claims are rarely provable.

---

## 3. Design Goals

PoA is built around the following principles:

- Verifiability – anyone can verify independently
- Transparency – proofs are public
- Immutability – historical proofs cannot be silently altered
- Simplicity – no blockchain required
- Low Cost – runs on low-cost VPS infrastructure
- Offline Verification – DNS + files are sufficient

---

## 4. Architecture Overview

PoA consists of five core components:

1. Exporter – produces availability datasets
2. Hasher – computes SHA256 digests
3. Chain – links proofs together (anti-rollback)
4. Anchor – publishes the current proof hash via DNS
5. Verifier – validates the system end-to-end

---

## 5. Proof Generation

### 5.1 Dataset Export

At regular intervals, the system exports an availability dataset:

heartbeats_YYYYMMDD_HHMMSS.json

Each file represents a snapshot of availability at a precise moment in time.

### 5.2 Cryptographic Hashing

Each export is hashed using SHA256:

SHA256(file) = digest

The digest uniquely identifies the file content.

### 5.3 Proof Chaining (Anti-Rollback)

Each proof embeds metadata:

- Previous file name
- Previous file hash
- Sequence number
- Timestamp

This creates a cryptographic chain. Any modification, deletion, or reordering of past proofs breaks the chain.

---

## 6. Public Anchoring via DNS

The current proof is anchored in public DNS using a TXT record:

_poa.example.com TXT  
TS=timestamp;SHA256=digest;FILE=filename

DNS provides a globally distributed, timestamped, and publicly observable anchor.

---

## 7. Verification Process

Verification requires no trust in the operator.

Steps:
1. Query authoritative DNS TXT record
2. Extract timestamp, filename, and hash
3. Locate the referenced file
4. Recompute SHA256
5. Validate timestamp consistency
6. Validate proof chain integrity

Command-line verification:

POA_EXPORT_DIR=/path/to/exports python poa_verify_full.py

Expected output:

VERDICT: OK

---

## 8. Security Properties

Guarantees:
- Proof existed at or before DNS timestamp
- File content integrity is preserved
- Historical proofs cannot be silently removed
- Independent verification is always possible

Non-goals:
- Does not prove absolute uptime
- Does not prevent operator shutdown
- Does not replace full monitoring platforms

---

## 9. Git and Snapshot Strategy

To remain scalable:
- Git stores a rolling window of recent proofs
- Older proofs are archived as immutable snapshots
- Snapshots remain publicly accessible

This preserves auditability without repository bloat.

---

## 10. Limitations

- DNS propagation delays
- Registrar-level compromise
- Clock drift (mitigated via chaining)

All limitations are explicit and measurable.

---

## 11. Use Cases

- API availability attestation
- Dataset publication proof
- SLA dispute resolution
- Regulatory evidence
- Trust-minimized infrastructure claims

---

## 12. Roadmap

- Multi-anchor support (DNS, Git, blockchain)
- Multi-region PoA nodes
- Third-party exporters
- Formal specification
- Independent verifiers

---

## 13. Conclusion

Proof of Availability replaces trust with cryptographic evidence.
It provides a simple, transparent, and verifiable mechanism to prove availability claims.

---

## 14. License

MIT License
