# Solution — Create a Virtual Network and Subnets

**Reference:** *Azure CLI reference → Network → `az network vnet`*:
<https://learn.microsoft.com/cli/azure/network/vnet#az-network-vnet-create>
(or `az network vnet create --help` / `az network vnet subnet create --help`).

## Address space versus subnet prefix

The VNet gets the **big** range (`--address-prefixes`); each subnet gets a
**smaller** range inside it (`--subnet-prefixes`). `az network vnet create` can make
the VNet and its first subnet in one call, so you create `web` with the VNet, then
add `data` as a second subnet.

```bash
az group create -n lab-network-vnet01-rg -l centralus

az network vnet create -g lab-network-vnet01-rg -n lab-vnet \
  --address-prefixes 10.10.0.0/16 \
  --subnet-name web --subnet-prefixes 10.10.1.0/24

az network vnet subnet create -g lab-network-vnet01-rg --vnet-name lab-vnet \
  -n data --address-prefixes 10.10.2.0/24
```

## Confirm the layout

```bash
az network vnet subnet list -g lab-network-vnet01-rg --vnet-name lab-vnet \
  --query "[].{name:name, prefix:addressPrefix}" -o table
# name  prefix
# web   10.10.1.0/24
# data  10.10.2.0/24
```

Both subnet ranges sit inside `10.10.0.0/16`, the VNet's address space. Nothing
here costs money yet; you will place a VM in the `web` subnet in Question 2.

| Goal | Command |
|------|---------|
| See VNet create flags | `az network vnet create --help` |
| Create VNet + first subnet | `az network vnet create -g <rg> -n <vnet> --address-prefixes 10.10.0.0/16 --subnet-name web --subnet-prefixes 10.10.1.0/24` |
| Add another subnet | `az network vnet subnet create -g <rg> --vnet-name <vnet> -n data --address-prefixes 10.10.2.0/24` |
| List subnets | `az network vnet subnet list -g <rg> --vnet-name <vnet> --query "[].{name:name, prefix:addressPrefix}" -o table` |
| Show the VNet's address space | `az network vnet show -g <rg> -n <vnet> --query addressSpace.addressPrefixes -o tsv` |
