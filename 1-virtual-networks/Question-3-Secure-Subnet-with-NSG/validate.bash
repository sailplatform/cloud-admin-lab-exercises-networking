#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Networking Q3: Secure a Subnet with an NSG. Read-only.
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

RG="$(lab_rg vnet03)"
VNET="lab-vnet"
VM="web-vm"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

subnet_nsg_id() {
  az network vnet subnet show -g "$RG" --vnet-name "$VNET" -n web \
    --query "networkSecurityGroup.id" -o tsv 2>/dev/null
}

subnet_has_nsg() { [[ -n "$(subnet_nsg_id)" ]]; }

# The subnet's NSG has an inbound Allow rule covering TCP port 80. Port fields are
# read as scalars per rule (never a multiselect projection to tsv, which mangles).
nsg_allows_80() {
  local id ranges multi
  id="$(subnet_nsg_id)"; [[ -z "$id" ]] && return 1
  ranges="$(az network nsg show --ids "$id" \
    --query "securityRules[?access=='Allow' && direction=='Inbound'].destinationPortRange" -o tsv 2>/dev/null)"
  multi="$(az network nsg show --ids "$id" \
    --query "securityRules[?access=='Allow' && direction=='Inbound'].destinationPortRanges[]" -o tsv 2>/dev/null)"
  grep -qxE '80|\*' <<<"$ranges" || grep -qxE '80|\*' <<<"$multi"
}

# The observable proof: an HTTP GET to the VM now succeeds.
http_ok() {
  local ip code
  ip="$(az vm list-ip-addresses -g "$RG" -n "$VM" \
    --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv 2>/dev/null)"
  [[ -z "$ip" ]] && return 1
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "http://$ip" 2>/dev/null)"
  [[ "$code" == "200" ]]
}

echo "======================================================"
echo " Validating Networking Q3: Secure a Subnet with an NSG"
echo "   Resource group: $RG"
echo "======================================================"

check "The 'web' subnet has an NSG associated"           subnet_has_nsg
check "That NSG allows inbound TCP port 80"              nsg_allows_80
check "HTTP GET to the VM returns 200"                   http_ok

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
