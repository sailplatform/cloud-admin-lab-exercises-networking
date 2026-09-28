#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Networking Q2: Place a VM in a Subnet
# ============================================================================
#  Provisions a virtual network with 'web' and 'data' subnets so you have
#  somewhere to put a VM. YOU create the VM, into the 'web' subnet. The VNet is
#  free; the VM you create is billable, so clean up when done.
#  Re-runnable: reuses an existing VNet.
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
VNET="lab-vnet"

echo "======================================================"
echo " Networking Q2 — Place a VM in a Subnet"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

if az network vnet show -g "$RG" -n "$VNET" >/dev/null 2>&1; then
  echo "  [OK] VNet '$VNET' already exists — reusing it."
else
  echo "  Creating VNet '$VNET' (10.10.0.0/16) with subnets web + data..."
  az network vnet create -g "$RG" -n "$VNET" --address-prefixes 10.10.0.0/16 \
    --subnet-name web --subnet-prefixes 10.10.1.0/24 --output none
  az network vnet subnet create -g "$RG" --vnet-name "$VNET" -n data \
    --address-prefixes 10.10.2.0/24 --output none
fi

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   Virtual network : ${VNET}  (subnets: web 10.10.1.0/24, data 10.10.2.0/24)"
echo ""
echo "  Your task: create a Linux VM in the 'web' subnet. When it comes up, its"
echo "  private IP should fall inside 10.10.1.0/24 (a 10.10.1.x address)."
echo "  Suggested size/image from lab-config: ${LAB_VM_SIZE} / ${LAB_VM_IMAGE}."
echo "  Validate with:  ./validate.bash    Clean up with: ./cleanup.bash"
echo "======================================================"
