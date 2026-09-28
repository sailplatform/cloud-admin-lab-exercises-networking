# Question 5 — Load-Balance Two VMs

## Scenario

Two identical web servers, `vm1` and `vm2`, each serve the app. Right now there is
no single address in front of them and no way to spread traffic or survive one VM
failing. As the cloud administrator, put a **public load balancer** in front of both
so one IP distributes requests across them.

`setup.bash` provisions the VNet and both VMs (nginx, each serving its own hostname,
port 80 open).

## The idea

A **load balancer** takes traffic on a **frontend** (a public IP + port) and spreads
it across a **backend pool** of VMs, sending only to the ones a **health probe** says
are healthy. You wire up four things: a frontend (public IP), a backend pool (the two
VMs' network cards), a probe (is port 80 answering?), and a rule (frontend 80 to
backend 80).

## Requirements

Everything in `lab-network-vnet05-rg`:

| # | Requirement | Value |
|---|-------------|-------|
| 1 | A **public load balancer** with a rule | frontend port `80` to backend port `80` |
| 2 | A **health probe** | on port `80` |
| 3 | The **backend pool** contains both VMs | 2 members |

Prove it: `curl` the load balancer's public IP several times and watch the reply
alternate between `vm1` and `vm2`. (Walkthrough in `solution.md`.)

## Work the question

```bash
./setup.bash       # provisions vm1 + vm2 (nginx); you build the load balancer
# ... create the LB, pool, probe, rule; add both VMs; curl the LB IP repeatedly ...
./validate.bash
./cleanup.bash
```
