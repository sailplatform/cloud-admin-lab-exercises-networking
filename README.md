# Hands-on Lab Exercises: Azure Networking

> **Topic:** Building and connecting private networks in Azure with **Virtual
> Networks**: subnets, network security groups, VNet peering, and load balancing.

Welcome to the third lab in the Cloud Administrator series. Lab 1 was about
**compute** (Virtual Machines and App Service) and Lab 2 was about **data** (Blob
Storage and Azure SQL). This lab is about the **network** those resources live on
and talk across.

A real admin does not memorize every command. They know which breadcrumbs to
follow. Each problem here is a short, real world scenario. Your job is to work out
what it demands and solve it with the Azure CLI. You get a script to check your
work and a concise solution walkthrough, freely, because this is a low stakes place
to build competency.

## What you will build

One category, five graded questions, plus five practice exercises:

- Create a **virtual network** and carve it into **subnets**.
- Place a **VM** into a subnet and see it pick up a private IP from that range.
- Control traffic with a **network security group** on a subnet.
- Connect two VNets with **peering** so their VMs can reach each other privately.
- Put a **public load balancer** in front of two VMs so one address spreads traffic
  across both.

## How this lab is different from the earlier labs

In the compute and storage labs you mostly managed one resource at a time. Here the
subject is the **space between** resources: how they get addresses, who is allowed
to reach whom, and how separate networks are joined. A few things follow from that:

- **You see connectivity, not just configuration.** Most questions ask you to
  `curl` or connect across a boundary and watch it change: a request that times out
  before a rule and returns `200` after, or a private IP that is unreachable until
  two networks are peered.
- **The lab uses small "probe" VMs.** To prove that traffic does or does not flow,
  several questions provision one or two tiny VMs to test from. That means these
  questions cost more and take a little longer than the storage lab, and a couple of
  them (peering and load balancing) create two VMs each.
- **Addresses and CIDR ranges matter.** You will work in `10.10.0.0/16` and its
  `/24` subnets, and checking that a VM landed in the right range is part of the
  job.

## The three skills we are building

1. **Reading documentation.** The first question an admin asks is "where are the
   provider's docs for X?" Learn to navigate them and you can learn any service.
2. **Tooling.** We use the **Azure CLI** (`az`) exclusively. No portal for the
   exercises. We like the hard way, because the hard way is the way that sticks.
3. **Troubleshooting.** When things break, composure first. Understand the cause,
   fix it, and write down what happened.

## Prerequisites

- **An Azure subscription**, paid (pay as you go). The probe VMs use an
  inexpensive burstable size (`Standard_B2als_v2`).
- **A lab VM (jumpbox) to work from.** You created this in the Compute lab and it
  is meant to last the whole semester. Use that same jumpbox here. The Azure CLI
  runs there, not on your laptop.

> **No jumpbox yet?** Set one up using the "Set up your lab environment" section of
> the Compute lab README (an Ubuntu 24.04 LTS VM in its own `lab-jumpbox-rg`, with
> the Azure CLI installed and `az login` done), then come back here.

> **Region tip.** Azure capacity varies by region. The default is `centralus`. If a
> create fails with a capacity or allocation error, change `LAB_LOCATION` in
> [`lab-config.sh`](lab-config.sh) and try another region such as `eastus2`,
> `westus2`, `westus3`, `southcentralus`, `westeurope`, or `northeurope`.

## Getting started on your jumpbox

**1. Connect to the jumpbox** (VS Code Remote-SSH gives you a file explorer, a
rendered preview of each `problem.md` and `solution.md`, and a terminal; plain
`ssh` or the Portal's Bastion work too).

**2. Clone this repo onto the jumpbox:**

```bash
git clone https://github.com/sailplatform/cloud-admin-lab-exercises-networking.git
cd cloud-admin-lab-exercises-networking
```

**3. Work each question from inside its folder:**

```bash
cd 1-virtual-networks/Question-1-Create-VNet-and-Subnets
./setup.bash        # then read problem.md and solve it
```

The probe VMs use generated SSH keys (no password). One question (peering) has you
SSH into a VM to run a test from inside the network; `setup.bash` prints the exact
`ssh` command and the IP to use.

> **Cost warning.** These labs create **real Azure resources that cost money**. Each
> question is isolated in its own resource group. Questions 2 through 5 provision
> VMs, and the peering and load balancer questions create **two** VMs each. You are
> billed while they exist, so the golden rule is: provision, solve, validate, then
> **run `./cleanup.bash` the moment you finish a question.** Keep your jumpbox for
> the whole semester, but do not leave question VMs running.

## How each question is structured

Every graded question lives in its own self contained folder with five files:

| File | What it is |
|------|-----------|
| `setup.bash`    | Prepares or pre checks the environment (and, where relevant, provisions the starting network and probe VMs). |
| `problem.md`    | The scenario and the exact requirements ("done" criteria). |
| `validate.bash` | Automated PASS or FAIL checks against your subscription. |
| `solution.md`   | A concise walkthrough of how an admin reasons about it. Read this if you get stuck. |
| `cleanup.bash`  | Deletes everything the question created. |

All scripts are open source: read them. Seeing how a check maps to an
`az network ... --query` is good practice in itself.

## The workflow

Everything happens inside a single question folder. `cd` into it and go:

```bash
cd 1-virtual-networks/Question-1-Create-VNet-and-Subnets

./setup.bash       # 1. Prepare or preflight (and, where relevant, provision the starting network)

# 2. Read problem.md and solve it yourself with the Azure CLI.
#    Stuck? Open solution.md in the same folder.

./validate.bash    # 3. Check your work. Prints PASS or FAIL for each requirement.

./cleanup.bash     # 4. Delete the resources so they stop costing money.
```

## Configuration: make it yours

Shared settings live in [`lab-config.sh`](lab-config.sh) at the repo root: the
**region** (`LAB_LOCATION`, default `centralus`), the resource group prefix
(`LAB_RG_PREFIX`, default `lab-network`), and the **size and image** for the probe
VMs (`LAB_VM_SIZE`, `LAB_VM_IMAGE`). Change a value once and every script follows,
or override for a single run:

```bash
LAB_LOCATION=westus3 ./validate.bash
```

## Available questions

### [`1-virtual-networks/`](1-virtual-networks/): Virtual Networks

| # | Topic | Skill |
|---|-------|-------|
| 1 | Create a VNet and Subnets | Lay out an address space and split it into subnets |
| 2 | Place a VM in a Subnet | Attach a VM to a subnet and read its private IP |
| 3 | Secure a Subnet with an NSG | Allow HTTP/SSH on a subnet; curl it before and after |
| 4 | Peer Two VNets | Join two networks so their VMs reach each other privately |
| 5 | Load-Balance Two VMs | One public IP spreads traffic across two backends |

Plus [**five practice exercises**](practice/exercises.md) (a three-tier subnet
design, an NSG with a service tag, a route table, static versus dynamic public IPs,
and an internal load balancer).

## The practice mindset (why solutions are given freely)

First study the worked examples, the graded questions, each with a `solution.md`
walkthrough of how an admin reasons through the task. Then drill the practice set
(problems only, no solutions) to build muscle memory. The point is not to know how
to create a subnet or a peering. It is to prove you can, and to build the habit of
finding the answer when you do not already have it.
