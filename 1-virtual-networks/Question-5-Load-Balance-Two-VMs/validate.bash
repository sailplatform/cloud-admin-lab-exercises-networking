#!/usr/bin/env bash
# ============================================================================
#  validate.bash — Networking Q5: Load-Balance Two VMs. Read-only.
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

RG="$(lab_rg vnet05)"

PASS=0; FAIL=0; TOTAL=0
check() {
  local description="$1"; shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then echo "  PASS: $description"; PASS=$((PASS + 1))
  else echo "  FAIL: $description"; FAIL=$((FAIL + 1)); fi
}

lb_name()   { az network lb list -g "$RG" --query "[0].name" -o tsv 2>/dev/null; }
pool_name() {
  local lb; lb="$(lb_name)"; [[ -z "$lb" ]] && return 1
  az network lb address-pool list -g "$RG" --lb-name "$lb" --query "[0].name" -o tsv 2>/dev/null
}

lb_exists() { [[ -n "$(lb_name)" ]]; }

lb_rule_80() {
  local lb out; lb="$(lb_name)"; [[ -z "$lb" ]] && return 1
  out="$(az network lb rule list -g "$RG" --lb-name "$lb" --query "[].frontendPort" -o tsv 2>/dev/null)"
  grep -qx "80" <<<"$out"
}

lb_has_probe() {
  local lb out; lb="$(lb_name)"; [[ -z "$lb" ]] && return 1
  out="$(az network lb probe list -g "$RG" --lb-name "$lb" --query "[].name" -o tsv 2>/dev/null)"
  [[ -n "$out" ]]
}

# Backend pool has 2 members. The member field is spelled backendIpConfigurations
# or backendIPConfigurations depending on CLI version; try both.
pool_has_two() {
  local lb pool n; lb="$(lb_name)"; pool="$(pool_name)"
  [[ -z "$lb" || -z "$pool" ]] && return 1
  n="$(az network lb address-pool show -g "$RG" --lb-name "$lb" -n "$pool" \
        --query "backendIpConfigurations[].id" -o tsv 2>/dev/null | grep -c .)"
  [[ "$n" -ge 2 ]] && return 0
  n="$(az network lb address-pool show -g "$RG" --lb-name "$lb" -n "$pool" \
        --query "backendIPConfigurations[].id" -o tsv 2>/dev/null | grep -c .)"
  [[ "$n" -ge 2 ]]
}

echo "======================================================"
echo " Validating Networking Q5: Load-Balance Two VMs"
echo "   Resource group: $RG"
echo "======================================================"

check "A load balancer exists in '$RG'"                  lb_exists
check "The LB has a rule on frontend port 80"            lb_rule_80
check "The LB has a health probe"                        lb_has_probe
check "The backend pool contains 2 VMs"                  pool_has_two

echo ""
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "All checks passed! Clean up with: ./cleanup.bash"
else
  echo "See the FAIL lines above, or read solution.md."
fi
exit $FAIL
