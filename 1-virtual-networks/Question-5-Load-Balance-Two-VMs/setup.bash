#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Networking Q5: Load-Balance Two VMs
# ============================================================================
#  Provisions a VNet and TWO VMs (vm1, vm2), each running nginx that serves its
#  own hostname, with port 80 open. YOU put a public load balancer in front of
#  them so one address spreads traffic across both. TWO real, billable VMs.
#  Re-runnable: reuses existing VMs.
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
VNET="lab-vnet"

echo "======================================================"
echo " Networking Q5 — Load-Balance Two VMs"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

if ! az network vnet show -g "$RG" -n "$VNET" >/dev/null 2>&1; then
  echo "  Creating VNet '$VNET' with subnet 'web'..."
  az network vnet create -g "$RG" -n "$VNET" --address-prefixes 10.10.0.0/16 \
    --subnet-name web --subnet-prefixes 10.10.1.0/24 --output none
fi

make_vm() {
  local name="$1"
  az vm show -g "$RG" -n "$name" >/dev/null 2>&1 && { echo "  [OK] $name exists — reusing."; return; }
  local ci; ci="$(mktemp)"
  cat > "$ci" <<'EOF'
#cloud-config
package_update: true
packages:
  - nginx
runcmd:
  - [ bash, -c, "echo \"Served by $(hostname)\" > /var/www/html/index.html" ]
  - [ systemctl, enable, --now, nginx ]
EOF
  echo "  Provisioning $name (nginx serving its hostname)... ~1 min."
  az vm create -g "$RG" -n "$name" --image "$LAB_VM_IMAGE" --size "$LAB_VM_SIZE" \
    --vnet-name "$VNET" --subnet web \
    --admin-username "$LAB_VM_ADMIN" --generate-ssh-keys \
    --custom-data "$ci" --output none
  rm -f "$ci"
  az vm open-port -g "$RG" -n "$name" --port 80 --priority 900 --output none
}

make_vm vm1
make_vm vm2

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   Backends        : vm1 and vm2 (nginx on port 80, in subnet 'web')"
echo ""
echo "  Your task: put a PUBLIC load balancer in front of vm1 and vm2 -"
echo "  a public IP + frontend, a backend pool containing both VMs, a health"
echo "  probe on 80, and a load-balancing rule 80 -> 80. Then curl the load"
echo "  balancer's public IP several times and watch replies alternate between"
echo "  vm1 and vm2."
echo "  Validate with:  ./validate.bash    Clean up with: ./cleanup.bash"
echo "======================================================"
