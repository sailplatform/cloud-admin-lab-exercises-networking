# Solution — Load-Balance Two VMs

**Reference:** *Azure CLI reference → `az network lb`*:
<https://learn.microsoft.com/cli/azure/network/lb#az-network-lb-create>
(or `az network lb create --help`, plus `az network lb probe create --help` and
`az network lb rule create --help`).

## Step 1 — create the load balancer, frontend, and backend pool

`az network lb create` builds the LB, a new public IP, the frontend, and an empty
backend pool in one call:

```bash
az network lb create -g lab-network-vnet05-rg -n web-lb --sku Standard \
  --public-ip-address web-lb-pip \
  --frontend-ip-name frontend --backend-pool-name backend-pool
```

## Step 2 — add a health probe and a rule

```bash
az network lb probe create -g lab-network-vnet05-rg --lb-name web-lb -n health-probe \
  --protocol Http --port 80 --path /

az network lb rule create -g lab-network-vnet05-rg --lb-name web-lb -n http-rule \
  --protocol Tcp --frontend-port 80 --backend-port 80 \
  --frontend-ip-name frontend --backend-pool-name backend-pool --probe-name health-probe
```

## Step 3 — put both VMs in the backend pool

The pool holds each VM's NIC ip-config. Discover the NIC and ip-config names, then
add them:

```bash
for vm in vm1 vm2; do
  NIC_ID=$(az vm show -g lab-network-vnet05-rg -n "$vm" \
    --query "networkProfile.networkInterfaces[0].id" -o tsv)
  NIC=$(basename "$NIC_ID")
  IPCFG=$(az network nic ip-config list --nic-name "$NIC" -g lab-network-vnet05-rg \
    --query "[0].name" -o tsv)
  az network nic ip-config address-pool add -g lab-network-vnet05-rg \
    --nic-name "$NIC" --ip-config-name "$IPCFG" \
    --lb-name web-lb --address-pool backend-pool
done
```

## Step 4 — confirm traffic spreads

```bash
LBIP=$(az network public-ip show -g lab-network-vnet05-rg -n web-lb-pip --query ipAddress -o tsv)

for i in $(seq 6); do curl -s "http://$LBIP"; echo; done
# Served by vm1
# Served by vm2
# Served by vm1
# ...
```

The replies alternate between the two VMs: one public address, traffic spread across
both backends. (The probe only sends traffic to healthy VMs, so if you stopped `vm1`,
every reply would come from `vm2`.)

> **Standard SKU note:** a Standard load balancer only forwards traffic that an NSG
> explicitly allows, which is why `setup.bash` opened port 80 on the VMs.

| Goal | Command |
|------|---------|
| Create LB + public IP + pool | `az network lb create -g <rg> -n <lb> --sku Standard --public-ip-address <pip> --frontend-ip-name frontend --backend-pool-name backend-pool` |
| Add a health probe | `az network lb probe create -g <rg> --lb-name <lb> -n health-probe --protocol Http --port 80 --path /` |
| Add a rule | `az network lb rule create -g <rg> --lb-name <lb> -n http-rule --protocol Tcp --frontend-port 80 --backend-port 80 --frontend-ip-name frontend --backend-pool-name backend-pool --probe-name health-probe` |
| Add a VM's NIC to the pool | `az network nic ip-config address-pool add -g <rg> --nic-name <nic> --ip-config-name <ipcfg> --lb-name <lb> --address-pool backend-pool` |
| Get the LB public IP | `az network public-ip show -g <rg> -n <pip> --query ipAddress -o tsv` |
