# Solution — Place a VM in a Subnet

**Reference:** *Azure CLI reference → `az vm create`*:
<https://learn.microsoft.com/cli/azure/vm#az-vm-create>
(or `az vm create --help`). The flags that matter here are **`--vnet-name`** and
**`--subnet`**: they attach the VM to an *existing* network instead of making a new
one.

## Create the VM in the web subnet

```bash
az vm create -g lab-network-vnet02-rg -n web-vm \
  --image Ubuntu2404 --size Standard_B2als_v2 \
  --vnet-name lab-vnet --subnet web \
  --admin-username azureuser --generate-ssh-keys
```

`--generate-ssh-keys` creates a key pair (no password to set). The VM also gets a
public IP by default so you can reach it. This takes about a minute.

## Confirm the private IP

```bash
az vm list-ip-addresses -g lab-network-vnet02-rg -n web-vm \
  --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv
# -> 10.10.1.4   (a 10.10.1.x address = it's in the web subnet)
```

Azure hands out the first few addresses of a subnet to its own services, so the
first VM usually lands on `.4`. Any `10.10.1.x` confirms the VM is in `web`.

| Goal | Command |
|------|---------|
| See VM create flags | `az vm create --help` |
| Create a VM in a subnet | `az vm create -g <rg> -n <vm> --image Ubuntu2404 --size Standard_B2als_v2 --vnet-name <vnet> --subnet web --admin-username azureuser --generate-ssh-keys` |
| Show private IP | `az vm list-ip-addresses -g <rg> -n <vm> --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv` |
| Show public IP | `az vm list-ip-addresses -g <rg> -n <vm> --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv` |
