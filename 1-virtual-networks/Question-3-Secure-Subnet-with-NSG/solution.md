# Solution — Secure a Subnet with an NSG

**Reference:** *Azure CLI reference → `az network nsg`*:
<https://learn.microsoft.com/cli/azure/network/nsg#az-network-nsg-create>
(or `az network nsg create --help`, `az network nsg rule create --help`, and
`az network vnet subnet update --help`).

## Move 1 — see it blocked

```bash
PUBIP=$(az vm list-ip-addresses -g lab-network-vnet03-rg -n web-vm \
  --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)

curl --max-time 5 -i "http://$PUBIP"    # -> times out: no NSG, default deny
```

## Move 2 — create the NSG, add rules, attach to the subnet

Three steps: make the NSG, add allow rules, then associate it to the `web` subnet.
An NSG already permits outbound and intra-VNet traffic by default, so you only add
the inbound rules you want (lower `--priority` number = evaluated first).

```bash
az network nsg create -g lab-network-vnet03-rg -n web-nsg

az network nsg rule create -g lab-network-vnet03-rg --nsg-name web-nsg -n allow-ssh \
  --priority 1000 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 22

az network nsg rule create -g lab-network-vnet03-rg --nsg-name web-nsg -n allow-http \
  --priority 1010 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 80

az network vnet subnet update -g lab-network-vnet03-rg --vnet-name lab-vnet -n web \
  --network-security-group web-nsg
```

## Move 3 — confirm it's reachable

```bash
curl --max-time 5 -i "http://$PUBIP"    # -> HTTP/1.1 200 OK, "web-vm is serving on port 80"
```

The same request that timed out now returns the page: the subnet NSG opened port 80
for the whole tier. (Rule changes take effect within a few seconds.)

| Goal | Command |
|------|---------|
| Create an NSG | `az network nsg create -g <rg> -n <nsg>` |
| Allow an inbound port | `az network nsg rule create -g <rg> --nsg-name <nsg> -n <rule> --priority <n> --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 80` |
| Attach NSG to a subnet | `az network vnet subnet update -g <rg> --vnet-name <vnet> -n web --network-security-group <nsg>` |
| List a subnet's NSG | `az network vnet subnet show -g <rg> --vnet-name <vnet> -n web --query networkSecurityGroup.id -o tsv` |
| List NSG rules | `az network nsg rule list -g <rg> --nsg-name <nsg> -o table` |
