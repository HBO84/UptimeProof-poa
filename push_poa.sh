#!/usr/bin/env bash
set -euo pipefail
cp -f /opt/uptimeproof/proof/poa.log /opt/uptimeproof/public-proof/poa.log
cd /opt/uptimeproof/public-proof
git add poa.log
git commit -m "update $(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null 2>&1 || true
git push >/dev/null 2>&1 || true
