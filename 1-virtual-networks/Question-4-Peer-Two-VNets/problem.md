# Question 4 — Peer Two Virtual Networks

## Scenario

Two teams run in two separate virtual networks, `vnet-a` (`10.10.0.0/16`) and
`vnet-b` (`10.20.0.0/16`). By default the VNets are completely isolated: a VM in one
cannot reach a VM in the other, even over private IPs. The teams now need to talk.
As the cloud administrator, connect the two networks with **VNet peering**.

`setup.bash` provisions both VNets and a VM in each: `vm-a` (with SSH open, your way
in) and `vm-b` (running nginx, private IP only).

## The idea

**Peering** links two VNets so traffic routes between them over Azure's backbone,
using private IPs, as if they were one network. Peering is **directional**: you
create it on each side (a-to-b and b-to-a). Only when both halves exist does the
connection report `Connected` and traffic actually flow.

## Requirements

Everything in `lab-network-vnet04-rg`:

| # | Requirement | Value |
|---|-------------|-------|
| 1 | Peering `vnet-a` to `vnet-b` | state `Connected` |
| 2 | Peering `vnet-b` to `vnet-a` | state `Connected` |

Prove it: from `vm-a`, `curl` `vm-b`'s private IP. It times out before peering and
returns `200` after. (Walkthrough in `solution.md`.)

## Work the question

```bash
./setup.bash       # provisions both VNets + vm-a and vm-b; prints their IPs
# ... from vm-a, curl vm-b (blocked) -> peer both directions -> curl again (200) ...
./validate.bash
./cleanup.bash
```
