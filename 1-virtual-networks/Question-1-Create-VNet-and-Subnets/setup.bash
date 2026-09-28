#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Networking Q1: Create a Virtual Network and Subnets
# ============================================================================
#  Preflight only. YOU create the resource group, the virtual network, and its
#  two subnets. This script does not create anything billable (a VNet and empty
#  subnets are free; you pay for resources you later place in them).
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

echo "======================================================"
echo " Networking Q1 — Create a Virtual Network and Subnets"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."
echo ""
echo "  Nothing was provisioned — this question is yours to build."
echo "------------------------------------------------------"
echo "   Target resource group : ${RG}  (in ${LAB_LOCATION})"
echo "   Virtual network        : address space 10.10.0.0/16"
echo "   Subnet 'web'           : 10.10.1.0/24"
echo "   Subnet 'data'          : 10.10.2.0/24"
echo ""
echo "  Build a resource group, a virtual network, and the two subnets above."
echo "  See problem.md, then solution.md if you get stuck."
echo "  Validate with:  ./validate.bash"
echo "======================================================"
