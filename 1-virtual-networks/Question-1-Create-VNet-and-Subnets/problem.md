# Question 1 — Create a Virtual Network and Subnets

## Scenario

A team is about to deploy a small two-tier application (a web layer and a data
layer) and needs a private network in Azure to run it on. As the cloud
administrator, create the **virtual network** and carve it into two **subnets**, one
for each tier.

## First, two terms: virtual network and subnet

- A **virtual network (VNet)** is your own private slice of IP address space in
  Azure. You give it a range in CIDR notation, for example `10.10.0.0/16` (which
  covers `10.10.0.0` to `10.10.255.255`, about 65,000 addresses).
- A **subnet** carves a smaller range out of the VNet, for example
  `10.10.1.0/24` (256 addresses). You attach resources and security rules to
  subnets, so splitting a VNet into subnets is how you separate tiers (web, data)
  and control traffic between them.

## Requirements

Everything in `lab-network-vnet01-rg`:

| # | Requirement | Value |
|---|-------------|-------|
| 1 | A **virtual network** | address space `10.10.0.0/16` |
| 2 | A subnet **`web`** | `10.10.1.0/24` |
| 3 | A subnet **`data`** | `10.10.2.0/24` |

After you build it, list the subnets and see the two ranges sitting inside the
VNet's address space. (Walkthrough in `solution.md`.)

## Work the question

```bash
./setup.bash       # preflight only — you build everything
# ... create the RG, the VNet with the web subnet, then add the data subnet ...
./validate.bash
./cleanup.bash
```
