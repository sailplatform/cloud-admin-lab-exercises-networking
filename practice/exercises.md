# Practice Exercises — Networking

These are practice problems: **questions only**, no `setup.bash`, no
`validate.bash`, no `solution.md`. The graded questions walked you through the core
skills; these are the reps that turn understanding into muscle memory.

Work them the way a cloud admin works any ticket:

1. **Read the scenario into a checklist** of concrete constraints.
2. **Find the reference**: guess `az network <noun> <verb>`, confirm in the docs.
3. **Tame the flags with `--help`**, required first, then match the rest to your checklist.
4. **Build the command incrementally**, then **verify with your own eyes.**

Some questions deliberately leave a value for you to look up. Finding it in the docs
is part of the exercise.

## How to check your own work (no validator here)

You are the validator now. The commands that tell you the truth:

```bash
az network vnet subnet list -g <rg> --vnet-name <vnet> -o table
az network nsg rule list -g <rg> --nsg-name <nsg> -o table
az network vnet peering list -g <rg> --vnet-name <vnet> --query "[].{name:name, state:peeringState}" -o table
az network public-ip show -g <rg> -n <pip> --query "{ip:ipAddress, alloc:publicIPAllocationMethod}" -o table
az network route-table route list -g <rg> --route-table-name <rt> -o table
az vm list-ip-addresses -g <rg> -n <vm> -o table
```

## Ground rules

- Use your **own resource groups**, a good convention is `practice-netNN-rg` so they
  are easy to find and delete. One group per exercise.
- Several of these create **real, billable VMs.** Clean up the moment you finish:
  ```bash
  az group delete --name <your-rg> --yes --no-wait
  ```
- Region is your choice; if a size is not offered where you are, pick another region.

---

## Exercise 1 — Design a three-tier network

An app has a public web tier, a private app tier, and a database tier, and each must
sit in its own subnet.

**Done when:**
- A VNet exists with address space `10.30.0.0/16`.
- Three subnets exist: `web` (`10.30.1.0/24`), `app` (`10.30.2.0/24`), and `data`
  (`10.30.3.0/24`).
- `az network vnet subnet list` shows all three with the right ranges.

## Exercise 2 — Lock a subnet down with a service tag

The database subnet should accept traffic only from inside the virtual network, not
from the internet, without you having to list IP ranges by hand.

**Done when:**
- An NSG is associated to a `data` subnet.
- It has an inbound rule allowing TCP `1433` whose **source is the `VirtualNetwork`
  service tag** (look up what a service tag is and which one means "this VNet and
  its peers").
- Confirm with `az network nsg rule list` that the source is `VirtualNetwork`, not a
  raw IP range.

## Exercise 3 — Steer traffic with a route table

You want all outbound traffic from a subnet to be sent somewhere specific (here,
just prove you can install a custom route).

**Done when:**
- A **route table** exists and is associated to a subnet.
- It contains a route for destination `0.0.0.0/0` (look up the `--next-hop-type`
  options and pick `Internet` for this experiment).
- Confirm with `az network route-table route list`.

## Exercise 4 — Static versus dynamic public IP

A service needs a public IP that never changes. Show the difference between the two
allocation methods.

**Done when:**
- You create one public IP with **dynamic** allocation and one with **static**.
- You explain (to yourself) which one is guaranteed not to change and why that
  matters for DNS.
- Confirm the allocation method of each with
  `az network public-ip show --query publicIPAllocationMethod`.

## Exercise 5 — Internal load balancer

Two backend VMs should be reachable through a single **private** address inside the
VNet, with nothing exposed to the internet.

**Done when:**
- An **internal** (private) load balancer sits in a subnet with a private frontend
  IP (no public IP anywhere).
- Its backend pool holds two VMs, with a health probe and a rule on port 80.
- From a third VM in the same VNet, `curl http://<lb-private-ip>` returns a page, and
  repeated calls reach both backends.
