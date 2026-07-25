# ACPI `_LPI` states vs. `hamoa.dtsi` idle states (x1p42100 / purwa)

Source: `acpi/dat/dsdt.dsl`, Lenovo IdeaPad Slim 5x (X1P-42-100). Extracted 2026-07-25.
Relevant to the stalled linux-arm-msm patches adding a `system_pd` idle state.

Three `_LPI` levels exist, each an `ACPI0010` processor container:

| container | `_UID` | level ID (pkg elem 1) | states |
|---|---|---|---|
| `\_SB.SYSM` | `0x00100000` | `0x02000000` | `platform.SS1`, `platform.SS2`, `platform.DRIPS` |
| `\_SB.SYSM.CLS0` | `0x10` | `0x01000000` | `Cluster0.CL4`, `Cluster0.CL5` |
| `\_SB.SYSM.CLS0.CPU0` | `0` | `0` (none) | `NCC.C1`, `NCC.C4` |

## The numbers

`_LPI` package element order is MinResidency, WorstCaseWakeLatency, Flags,
ArchContextLostFlags, ResidencyCounterFrequency, EnabledParentState, EntryMethod,
ResidencyCounterRegister, UsageCounterRegister, StateName. All times in microseconds.

| ACPI state | MinResidency | WakeLatency | ArchCtxLost | EntryMethod |
|---|---|---|---|---|
| `NCC.C1` | 0 | 0 | 0 | (WFI) |
| `NCC.C4` | 600 | 500 | 0 | `FFixedHW` GAS, address `0x04` |
| `Cluster0.CL4` | 2500 | 500 | 0 | integer `0x40` |
| `Cluster0.CL5` | 7000 | 4000 | 0 | integer `0x50` |
| `platform.SS1` | 7500 | 500 | 0 | integer `0x0100` |
| `platform.SS2` | 8000 | 3000 | 0 | integer `0x0200` |
| `platform.DRIPS` | 9000 | 5000 | `0x20` | integer `0xC300` |

## The PSCI parameter is confirmed

Composing level ID with the entry methods of each level reproduces the in-tree values
exactly, and confirms the disputed one:

```
cluster_cl4  = 0x01000000 | 0x40   | 0x04 = 0x01000044   (matches hamoa.dtsi)
cluster_cl5  = 0x01000000 | 0x50   | 0x04 = 0x01000054   (matches hamoa.dtsi)
DRIPS        = 0x02000000 | 0xC300 | 0x50 | 0x04 = 0x0200C354
```

`0x0200C354` is exactly the value proposed in Daniel J Blueman's patch, and matches his
stated derivation ("CPU C4, cluster CL5 and system DRIPS parameters"). This is
independent confirmation on **x1p42100 (purwa)** silicon — both upstream submitters
tested x1e80100 (hamoa) parts.

## Where the DT and ACPI agree, and where they don't

| DT node | DT min-residency | ACPI MinResidency | DT exit-latency | ACPI WakeLatency | DT entry-latency |
|---|---|---|---|---|---|
| `cpu-sleep-0` (`cluster_c4`) | 600 | **600** | 320 | 500 | 180 |
| `cluster_cl4` | 2500 | **2500** | 500 | **500** | 350 |
| `cluster_cl5` | 7000 | **7000** | 4000 | **4000** | 2200 |
| proposed `domain_ss3` | 9000 | **9000** | 5000 | **5000** | 4000 (assumed) |

Every `min-residency-us` in the DT equals ACPI `MinResidency` exactly. Every
`exit-latency-us` equals ACPI `WorstCaseWakeLatency` exactly — **except** the CPU state,
which commit 3ecea84d2b90 changed from 500 to 320 so that entry+exit would sum to the
500 µs wake latency.

That is the substance of the review deadlock. Two conventions are now in tree:

- **cluster convention:** `exit-latency-us` = ACPI WakeLatency; `entry-latency-us` is
  not derived from ACPI. Both cluster states follow this.
- **CPU convention** (3ecea84d2b90, at Maulik Shah's direction): `entry-latency-us` +
  `exit-latency-us` = ACPI WakeLatency.

The proposed DRIPS values (9000 / 5000 / entry 4000) follow the *cluster* convention.
Maulik's objection — "total exit latency would be 9000 instead of 5000" — applies the
*CPU* convention. Note the existing cluster states violate the CPU convention too
(CL4: 350+500=850 vs 500; CL5: 2200+4000=6200 vs 4000), so this is a pre-existing
inconsistency the DRIPS patch merely surfaces, not one it introduces.

`entry-latency-us` is the only value with no ACPI source at any level. ACPI provides
MinResidency and WorstCaseWakeLatency only.

## SS1 and SS2 are unimplemented

Both upstream patches add DRIPS alone. The firmware exposes two shallower system states
(SS1 at 7500/500 and SS2 at 8000/3000) that no DT change proposes. `domain-idle-states`
accepts a list, so all three could be exposed, letting the genpd governor pick a shallower
system state for short idles instead of the all-or-nothing DRIPS.

Also worth noting: `DRIPS` is the firmware's own name for the deepest state; Val Packett's
patch called the DT node `SS3`, which does not correspond to anything in the DSDT.

## Measured baseline on this machine (stock DT, no system idle state)

From `/sys/kernel/debug/qcom_stats` across a 74.1 s suspend, and a 20.7 h suspend for the
power figure:

- `apss` collapses correctly: 72.15 s of the 74.1 s window
- `aosd`, `cxsd`, `ddr`: **0, and never non-zero since boot**
- 20.71 h suspend drew 79.9 % of a 60.42 Wh battery = **2.33 W average**
