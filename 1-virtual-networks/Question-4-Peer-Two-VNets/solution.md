# Solution — Peer Two Virtual Networks

**Reference:** *Azure CLI reference → `az network vnet peering`*:
<https://learn.microsoft.com/cli/azure/network/vnet/peering#az-network-vnet-peering-create>
(or `az network vnet peering create --help`).

## Move 1 — see the isolation

`setup.bash` printed vm-a's public IP and vm-b's private IP. SSH into vm-a and try
to reach vm-b:

```bash
ssh azureuser@<vm-a-public-ip>
curl --max-time 5 http://<vm-b-private-ip>    # -> times out: the VNets are isolated
exit
```

## Move 2 — peer both directions

Peering needs the *resource ID* of the remote VNet on each side. Grab both, then
create the two halves:

```bash
AID=$(az network vnet show -g lab-network-vnet04-rg -n vnet-a --query id -o tsv)
BID=$(az network vnet show -g lab-network-vnet04-rg -n vnet-b --query id -o tsv)

az network vnet peering create -g lab-network-vnet04-rg -n a-to-b \
  --vnet-name vnet-a --remote-vnet "$BID" --allow-vnet-access

az network vnet peering create -g lab-network-vnet04-rg -n b-to-a \
  --vnet-name vnet-b --remote-vnet "$AID" --allow-vnet-access
```

After the second one, both report `Connected`:

```bash
az network vnet peering list -g lab-network-vnet04-rg --vnet-name vnet-a \
  --query "[].{name:name, state:peeringState}" -o table
# name    state
# a-to-b  Connected
```

## Move 3 — confirm connectivity

```bash
ssh azureuser@<vm-a-public-ip>
curl --max-time 5 http://<vm-b-private-ip>    # -> Hello from vm-b, reached over the peering
exit
```

The private IP that was unreachable a moment ago now answers. Note you never opened
a public port on vm-b: peering carries the traffic privately, and vm-b's default
rules already allow traffic from within its (now-peered) virtual network.

| Goal | Command |
|------|---------|
| Get a VNet's resource ID | `az network vnet show -g <rg> -n <vnet> --query id -o tsv` |
| Create one side of a peering | `az network vnet peering create -g <rg> -n <name> --vnet-name <local> --remote-vnet <remote-id> --allow-vnet-access` |
| List peerings + state | `az network vnet peering list -g <rg> --vnet-name <vnet> --query "[].{name:name, state:peeringState}" -o table` |
