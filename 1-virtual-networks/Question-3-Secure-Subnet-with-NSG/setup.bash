#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Networking Q3: Secure a Subnet with an NSG
# ============================================================================
#  Provisions a VNet + a VM (running nginx) in the 'web' subnet, created with NO
#  network security group. With no NSG, Azure's default rules DENY inbound
#  internet traffic, so the web server is unreachable until you add an NSG that
#  allows it. Real, billable VM. Re-runnable: reuses an existing VM.
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

echo "======================================================"
echo " Networking Q3 — Secure a Subnet with an NSG"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

if ! az network vnet show -g "$RG" -n "$VNET" >/dev/null 2>&1; then
  echo "  Creating VNet '$VNET' with subnets web + data..."
  az network vnet create -g "$RG" -n "$VNET" --address-prefixes 10.10.0.0/16 \
    --subnet-name web --subnet-prefixes 10.10.1.0/24 --output none
  az network vnet subnet create -g "$RG" --vnet-name "$VNET" -n data \
    --address-prefixes 10.10.2.0/24 --output none
fi

if az vm show -g "$RG" -n "$VM" >/dev/null 2>&1; then
  echo "  [OK] VM '$VM' already exists — reusing it."
else
  CLOUDINIT="$(mktemp)"
  cat > "$CLOUDINIT" <<'EOF'
#cloud-config
package_update: true
packages:
  - nginx
runcmd:
  - [ bash, -c, "echo 'web-vm is serving on port 80' > /var/www/html/index.html" ]
  - [ systemctl, enable, --now, nginx ]
EOF
  echo "  Provisioning VM '$VM' in the web subnet, with nginx and NO NSG... ~1 min."
  az vm create -g "$RG" -n "$VM" --image "$LAB_VM_IMAGE" --size "$LAB_VM_SIZE" \
    --vnet-name "$VNET" --subnet web --nsg "" \
    --admin-username "$LAB_VM_ADMIN" --generate-ssh-keys \
    --custom-data "$CLOUDINIT" --output none
  rm -f "$CLOUDINIT"
fi

PUBIP="$(az vm list-ip-addresses -g "$RG" -n "$VM" \
  --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv 2>/dev/null)"

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   VM              : ${VM}  (nginx on port 80, no NSG yet)"
echo "   VM public IP    : ${PUBIP}"
echo ""
echo "  >> SEE THE PROBLEM FIRST. The web server is up but unreachable:"
echo "       curl --max-time 5 http://${PUBIP}     # times out (default deny)"
echo ""
echo "  Your task: create an NSG that allows inbound SSH (22) and HTTP (80),"
echo "  associate it to the 'web' subnet, then curl again -> 200."
echo "  Validate with:  ./validate.bash    Clean up with: ./cleanup.bash"
echo "======================================================"
