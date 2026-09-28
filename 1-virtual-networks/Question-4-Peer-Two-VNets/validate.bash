#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Networking Q4: Peer Two Virtual Networks. Read-only.
#  Exit code = number of failed checks.
# ============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
find_config() {
  local dir="$SCRIPT_DIR"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/lab-config.sh" ]]; then echo "$dir/lab-config.sh"; return 0; fi
    dir="$(dirname "$dir")"
  done
  return 1
}
CONFIG="$(find_config)" || { echo "ERROR: could not find lab-config.sh" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONFIG"

RG="$(lab_rg vnet04)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

# A VNet has at least one peering in the Connected state.
peer_connected() {
  local out
  out="$(az network vnet peering list -g "$RG" --vnet-name "$1" --query "[].peeringState" -o tsv 2>/dev/null)"
  grep -qx "Connected" <<<"$out"
}

a_ok() { peer_connected vnet-a; }
b_ok() { peer_connected vnet-b; }

echo "======================================================"
echo " Validating Networking Q4: Peer Two Virtual Networks"
echo "   Resource group: $RG"
echo "======================================================"

check "vnet-a has a Connected peering"                   a_ok
check "vnet-b has a Connected peering"                   b_ok

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
