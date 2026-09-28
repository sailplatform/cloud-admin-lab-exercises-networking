# Question 2 — Place a VM in a Subnet

## Scenario

The virtual network from Question 1 is ready. Now the web tier needs a server. As
the cloud administrator, deploy a Linux VM **into the `web` subnet** so it picks up
a private IP from that subnet's range.

`setup.bash` provisions the VNet (`lab-vnet`) with the `web` and `data` subnets for
you.

## The idea

When you create a VM you tell Azure which VNet and subnet to attach its network
card to. The VM then gets a **private IP** from that subnet's range. Put it in the
`web` subnet (`10.10.1.0/24`) and its private IP will be a `10.10.1.x` address. If
you forget the `--vnet-name`/`--subnet` flags, `az vm create` builds a brand-new
network instead, which is the usual "why isn't it in my subnet?" mistake.

## Requirements

Everything in `lab-network-vnet02-rg`:

| # | Requirement | Value |
|---|-------------|-------|
| 1 | A **Linux VM** attached to the `web` subnet | private IP inside `10.10.1.0/24` |

After it boots, look at its private IP and confirm it lands in the `web` range.
(Walkthrough in `solution.md`.)

## Work the question

```bash
./setup.bash       # provisions the VNet + subnets; you create the VM
# ... create a Linux VM in the 'web' subnet, then check its private IP ...
./validate.bash
./cleanup.bash
```
