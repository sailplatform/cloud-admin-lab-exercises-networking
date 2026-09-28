#!/usr/bin/env bash
# ============================================================================
#  setup.bash — Networking Q4: Peer Two Virtual Networks
# ============================================================================
#  Provisions TWO virtual networks, each with one VM:
#    vnet-a (10.10.0.0/16) -> vm-a  (your jump box into the network; SSH open)
#    vnet-b (10.20.0.0/16) -> vm-b  (tiny web server; no public IP, no NSG)
#  The two VNets are isolated by default. You will peer them so vm-a can reach
#  vm-b over its PRIVATE IP. TWO real, billable VMs. Re-runnable.
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

echo "======================================================"
echo " Networking Q4 — Peer Two Virtual Networks"
echo "======================================================"
command -v az >/dev/null 2>&1 || { echo "  [X] Azure CLI not installed"; exit 1; }
az account show >/dev/null 2>&1 || { echo "  [X] Not logged in. Run: az login"; exit 1; }
echo "  [OK] Azure CLI present and logged in."

echo "  Ensuring resource group '$RG' in '$LAB_LOCATION'..."
az group create --name "$RG" --location "$LAB_LOCATION" --output none

if ! az network vnet show -g "$RG" -n vnet-a >/dev/null 2>&1; then
  echo "  Creating vnet-a (10.10.0.0/16) and vnet-b (10.20.0.0/16)..."
  az network vnet create -g "$RG" -n vnet-a --address-prefixes 10.10.0.0/16 \
    --subnet-name main --subnet-prefixes 10.10.1.0/24 --output none
  az network vnet create -g "$RG" -n vnet-b --address-prefixes 10.20.0.0/16 \
    --subnet-name main --subnet-prefixes 10.20.1.0/24 --output none
fi

if ! az vm show -g "$RG" -n vm-a >/dev/null 2>&1; then
  echo "  Provisioning vm-a in vnet-a (SSH open so you can log in)... ~1 min."
  az vm create -g "$RG" -n vm-a --image "$LAB_VM_IMAGE" --size "$LAB_VM_SIZE" \
    --vnet-name vnet-a --subnet main \
    --admin-username "$LAB_VM_ADMIN" --generate-ssh-keys --output none
fi

if ! az vm show -g "$RG" -n vm-b >/dev/null 2>&1; then
  CLOUDINIT="$(mktemp)"
  cat > "$CLOUDINIT" <<'EOF'
#cloud-config
# vm-b has no public IP, and Azure retired default outbound access (2025-09-30),
# so it has no path to the internet to install packages. We serve the page with
# Python's built-in http.server (already on the image) via a small systemd unit,
# so no internet is required.
write_files:
  - path: /opt/web/index.html
    content: |
      Hello from vm-b, reached over the peering
  - path: /etc/systemd/system/labweb.service
    content: |
      [Unit]
      Description=Lab web server (no internet needed)
      After=network.target
      [Service]
      WorkingDirectory=/opt/web
      ExecStart=/usr/bin/python3 -m http.server 80
      Restart=always
      [Install]
      WantedBy=multi-user.target
runcmd:
  - [ systemctl, daemon-reload ]
  - [ systemctl, enable, --now, labweb ]
EOF
  echo "  Provisioning vm-b in vnet-b (tiny web server, no public IP)... ~1 min."
  az vm create -g "$RG" -n vm-b --image "$LAB_VM_IMAGE" --size "$LAB_VM_SIZE" \
    --vnet-name vnet-b --subnet main --nsg "" --public-ip-address "" \
    --admin-username "$LAB_VM_ADMIN" --generate-ssh-keys \
    --custom-data "$CLOUDINIT" --output none
  rm -f "$CLOUDINIT"
fi

VMA_PUB="$(az vm list-ip-addresses -g "$RG" -n vm-a --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv 2>/dev/null)"
VMB_PRIV="$(az vm list-ip-addresses -g "$RG" -n vm-b --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv 2>/dev/null)"

echo "------------------------------------------------------"
echo "   Resource group : ${RG}"
echo "   vm-a public IP  : ${VMA_PUB}   (ssh ${LAB_VM_ADMIN}@${VMA_PUB})"
echo "   vm-b private IP : ${VMB_PRIV}  (in vnet-b, no public IP)"
echo ""
echo "  >> SEE THE PROBLEM FIRST. SSH into vm-a and curl vm-b's private IP:"
echo "       ssh ${LAB_VM_ADMIN}@${VMA_PUB}"
echo "       curl --max-time 5 http://${VMB_PRIV}     # times out: VNets are isolated"
echo ""
echo "  Your task: peer vnet-a and vnet-b (BOTH directions). Then curl again from"
echo "  vm-a -> 200. Validate with:  ./validate.bash    Clean up with: ./cleanup.bash"
echo "======================================================"
