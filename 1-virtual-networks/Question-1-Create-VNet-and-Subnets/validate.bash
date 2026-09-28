#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Networking Q1: Create a VNet and Subnets. Read-only.
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

RG="$(lab_rg vnet01)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

vnet_name() { az network vnet list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }
# A subnet's prefix, reading whichever field this CLI version populates.
subnet_prefix() {
  local v; v="$(vnet_name)"; [[ -z "$v" ]] && return 1
  az network vnet subnet show -g "$RG" --vnet-name "$v" -n "$1" \
    --query "addressPrefix || addressPrefixes[0]" -o tsv 2>/dev/null
}

rg_exists()   { [[ "$(az group exists -n "$RG" 2>/dev/null)" == "true" ]]; }
vnet_exists() { [[ -n "$(vnet_name)" ]]; }
vnet_space_ok() {
  local v out; v="$(vnet_name)"; [[ -z "$v" ]] && return 1
  out="$(az network vnet show -g "$RG" -n "$v" --query "addressSpace.addressPrefixes" -o tsv 2>/dev/null)"
  grep -qx "10.10.0.0/16" <<<"$out"
}
web_ok()  { [[ "$(subnet_prefix web)"  == "10.10.1.0/24" ]]; }
data_ok() { [[ "$(subnet_prefix data)" == "10.10.2.0/24" ]]; }

echo "======================================================"
echo " Validating Networking Q1: Create a VNet and Subnets"
echo "   Resource group: $RG"
echo "======================================================"

check "Resource group '$RG' exists"                         rg_exists
check "A virtual network exists in '$RG'"                   vnet_exists
check "VNet address space includes 10.10.0.0/16"            vnet_space_ok
check "Subnet 'web' has prefix 10.10.1.0/24"                web_ok
check "Subnet 'data' has prefix 10.10.2.0/24"               data_ok

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
