#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Networking Q2: Place a VM in a Subnet. Read-only.
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

RG="$(lab_rg vnet02)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

vm_name()    { az vm list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }
vm_priv_ip() {
  local v; v="$(vm_name)"; [[ -z "$v" ]] && return 1
  az vm list-ip-addresses -g "$RG" -n "$v" \
    --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv 2>/dev/null
}

vm_exists()    { [[ -n "$(vm_name)" ]]; }
# The web subnet is 10.10.1.0/24, so any address in it starts with 10.10.1.
vm_in_web()    { [[ "$(vm_priv_ip)" == 10.10.1.* ]]; }

echo "======================================================"
echo " Validating Networking Q2: Place a VM in a Subnet"
echo "   Resource group: $RG"
echo "======================================================"

check "A VM exists in '$RG'"                                vm_exists
check "The VM's private IP is in the web subnet (10.10.1.0/24)" vm_in_web

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
