#!/usr/bin/env bash
# ============================================================================
#  cleanup.bash — Networking Q5: Load-Balance Two VMs. Deletes the RG.
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
echo "Cleaning up Networking Q5: resource group '$RG'..."
if [[ "$(az group exists --name "$RG" 2>/dev/null)" == "true" ]]; then
  az group delete --name "$RG" --yes --no-wait
  echo "[OK] Deletion requested for '$RG' (running in the background)."
  echo "     Confirm later with:  az group exists --name $RG   # expect: false"
else
  echo "[OK] Resource group '$RG' does not exist — nothing to clean up."
fi
