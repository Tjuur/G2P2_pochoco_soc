# Pochoco Trader V24-T — RV32E integration candidate

Based on commit `15c53eb` (`pochoco-v2.3-final`). Apply only in a new branch.
The delivered trade.s is the actual assembly executed by Espino. It was generated from the included integer C port using Clang 17 RV32E, with immediate left shifts lowered into ADD instructions and calls lowered into JAL. No shift, multiplication, division, x16–x31 or external datasets are used in the binary. P12 virtual equity is represented as net PnL relative to its initial capital; unused V17 virtual accounting and diagnostic-only counters are removed. The complete decision is computed by Espino. There is no new decision accelerator.

## Verified off-board

`check_isa.py` executes the delivered machine code in a functional RV32E interpreter, including the boot reset, actual MMIO reads/writes and the private data-memory ledger. It compares decisions, cash, and shares at every tick against the unchanged Python candidate. The 62 original/stress series passed, 1,240,000 ticks. META: 19,239, 76 orders, 380 commission, max drawdown 23.9726%. Estimated cycles use 2 per instruction plus 1 per load and taken branch/jump; **not a cycle-accurate or RTL measurement**. Worst observed 422 instructions, 947 estimated cycles. See `sim/v24_acceptance/verified_isa.csv`.

## Memory layout

Instruction ROM: 1024 x 32, of which 772 words are program and the rest NOP. Data RAM: 256 x 32, words 0–114 state (460 bytes), stack grows down from 0x10000400. `State.cash` and `State.shares` are words 106/107; used by the testbench for independent ledger checks. All data accesses are word-aligned. CPU register file and SPI protocol untouched. Nominal BRAM estimate: 8 ROM + 2 RAM + 4 register file = 14/16; inference and place/route must be checked, not assumed. Original price accelerator removed from the active SoC. No other peripherals or pins changed.

## Acceptance order

1. `python3 sim/v24_acceptance/check_isa.py` (all 62 series with the existing datasets). `--meta-only` is available.
2. Optional reproducibility test with the original GNU toolchain: `bash sw/v24/build_firmware.sh`. It checks byte equivalence without replacing the delivered hex on failure.
3. `bash sim/v24_acceptance/run_rtl.sh smoke` (4,096 ticks and repeat reset at fast timing, plus memory unit test).
4. `bash sim/v24_acceptance/run_rtl.sh quick` (full META, alternate SPI rates/phases, short slow rounds, stress cases).
5. `bash sim/v24_acceptance/run_rtl.sh full` (full slow rounds can require billions of simulated cycles).
6. `bash sim/v24_acceptance/run_rtl.sh all` (add 51 full historical/synthetic series).
7. `bash sim/v24_acceptance/synth_v24.sh` (25 MHz explicit timing target, no flashing).

RTL testbench now waits for the actual 10 ms POR, then initial HOLD from firmware; after forced reset also waits for boot. It checks actual ledger, IC, cycles, CPI, SPI decisions and deadline. Physical POR/round reset must be verified on the master; allow >10 ms plus boot initialization (e.g. 11 ms after power-on before first transaction). Tests at 500 kHz and 1 MHz use the course SPI protocol. A forced simulation reset is not evidence of physical reset capability.

## Pending / no claim of competition readiness

Icarus, Yosys, NextPNR and icepack were unavailable in the generation environment; new RTL has not been compiled or synthesized there. Do not program until local RTL acceptance and synthesis pass. If the fit fails, retain V2.3 and adjust the memory organization without changing decisions. Course hardware variants, measured speedup, Amdahl and roofline still need the final implementation-specific measurements. Do not run bare `make` (default flashes). Only program the exact verified bitstream manually once the physical setup is approved. The training windows are not independent validation; synthetic random streams can lose substantial money.
