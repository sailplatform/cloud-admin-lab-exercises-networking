# Question 3 — Secure a Subnet with an NSG

## Scenario

A VM running a web server sits in the `web` subnet, but nobody can reach it: with
no **network security group (NSG)**, Azure's default rules deny inbound traffic
from the internet. As the cloud administrator, add an NSG that permits SSH and HTTP,
and apply it to the whole `web` subnet so every VM in that tier is governed by the
same rules.

`setup.bash` provisions the VNet and the VM (nginx on port 80, no NSG).

## The idea

An **NSG** is a stateful allow/deny list of traffic rules. You can attach it to a
single VM's network card or, better for a tier, to a **subnet** so every resource
in that subnet inherits it. Each rule has a priority, a direction, a protocol, a
source, and a destination port. You will allow inbound **22** (SSH) and **80**
(HTTP) and let the default "deny everything else" stay in place.

## Requirements

Everything in `lab-network-vnet03-rg`:

| # | Requirement | Value |
|---|-------------|-------|
| 1 | An **NSG** associated to the `web` subnet | allows inbound **TCP 80** (and 22) |

Before the change, `curl http://<vm-public-ip>` times out; after you associate the
NSG, it returns `200`. Watch that flip. (Walkthrough in `solution.md`.)

## Work the question

```bash
./setup.bash       # provisions the VM (nginx, no NSG); prints its public IP
# ... curl it (blocked), create+associate the NSG, curl again (200) ...
./validate.bash
./cleanup.bash
```
