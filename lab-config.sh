#!/usr/bin/env bash
# ============================================================================
#  lab-config.sh — shared configuration for the Networking lab
# ============================================================================
#  Every setup.bash / validate.bash / cleanup.bash sources this one file, so
#  all the scripts for a question agree on WHERE your resources live, WHAT they
#  are named, and WHICH VM size/image the connectivity "probe" VMs use.
#
#  This is YOUR file to edit. The most common change is the region. Azure
#  capacity/quotas vary by region: if a create fails, switch LAB_LOCATION to
#  another region and re-run. Reliable alternates:
#      westus2, westus3, eastus2, southcentralus, westeurope, northeurope
#
#  Override any value for a single run without editing the file:
#      LAB_LOCATION=westus3 ./validate.bash
# ============================================================================

# Azure region where all lab resources are created.
export LAB_LOCATION="${LAB_LOCATION:-centralus}"

# Prefix applied to every resource group this lab creates. Keeps lab resources
# easy to spot in the portal and easy to delete when you're done.
export LAB_RG_PREFIX="${LAB_RG_PREFIX:-lab-network}"

# Size and image for the small "probe" VMs used to test connectivity across the
# network (used from Question 2 on). A cheap, widely-available burstable size.
export LAB_VM_SIZE="${LAB_VM_SIZE:-Standard_B2als_v2}"
export LAB_VM_IMAGE="${LAB_VM_IMAGE:-Ubuntu2404}"

# Admin username for the probe VMs. Authentication uses generated SSH keys, so
# there is no password to set or store.
export LAB_VM_ADMIN="${LAB_VM_ADMIN:-azureuser}"

# Build the resource-group name for a question from its short slug.
#   lab_rg vnet01   ->   lab-network-vnet01-rg
lab_rg() {
  echo "${LAB_RG_PREFIX}-$1-rg"
}
