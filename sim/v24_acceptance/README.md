# Pochoco Trader — V24-T acceptance suite

Status: Python oracle verified on the original practice and 48 historical + 3 synthetic series, plus 10 stress series. **Not a competition firmware or bitstream.** The actual current RTL/assembly tree and FPGA toolchain were not available for execution here. The SV testbench was written against the course SPI interface; its compilation, hierarchy and runtime need validation on the current branch.

## Frozen candidate

`reference.py` contains P12, V17.3-P, Shadow and v24 copied from the submitted benchmark. `candidate()` selects `merit_trades=1, early_failure=False, dynamic_trail=True`. Do not tune it. `verified_manifest.json` records the reference and data SHA-256 hashes. `verified_report.csv` and `verified_run.log` record the actual executed Python results. Historical windows are development data, not holdout. Random and 1–255 stress cases measure integrity, not realistic profitability.

## From repository root

Extract this package into the repository root (only `sim/v24_acceptance` is added). Keep the existing working firmware and releases intact. Requires Python 3.9+ with no external packages.

```
python3 sim/v24_acceptance/acceptance.py
```

Expected data layout: `sim/data/practica_meta.csv`, `sim/data/pochoco_v16/**/**_real.csv` (48), `sim/data/pochoco_tests_20000/**/SINTETICO_*.csv` (3). Use `--data` for a different root. Generated artifacts go under `build/v24_acceptance/`; do not incorporate any oracle or price data in synthesizable firmware. Every series generates the exact executed and next decision bytes, plus real cash, shares and wealth per tick. The last next_decision is compared at the CPU write but is not executed by the simulated master. `verified_manifest.json` records the datasets used here; compare with the local generated manifest to establish identity.

## Hardware acceptance (only after V24-T exists in assembly)

From the candidate branch, assemble `make -B -C sw trade.hex` (does not flash). Never invoke bare `make` in this repository. Then:

```
bash sim/v24_acceptance/run_rtl.sh quick
bash sim/v24_acceptance/run_rtl.sh full
# optional exhaustive test (long, all 48 historical and 3 synthetic cases)
bash sim/v24_acceptance/run_rtl.sh all
```

Quick: full META at 0.1 ms, short META for 1/10 ms, repeated reset, additional phase and SPI frequency, and ten stress datasets at 0.1 ms. Full uses all 20,000 META ticks in each of the three periods. All adds every historical and synthetic trace at the fastest period. A full 10 ms RTL run can be computationally expensive. The SV checks both transmitted and newly written decision bytes, exactly one byte/price read/decision write per tick (a deliberate stricter acceptance criterion than the minimum rules), no unknown MISO bits, no lost prices, no invalid official ledger, actual write before next CS, and measures price-to-write latency. The Python comparator checks all per-tick ledger fields and fails at the first mismatch. The comparator was tested on a matching trace and a deliberately corrupted trace. Reset in the testbench is a forced internal simulation reset, not evidence of a physical reset circuit. Current branch hierarchy may differ; adapt probes only, not expected outputs. IC/CPI instrumentation must use the actual current core retirement/valid signal, not count instruction fetches blindly. Add the existing performance monitor once the actual tree is available.

## Synthesis and physical acceptance (pending)

After exact parity, inspect the current Makefile and run explicit synthesis targets only:

```
make -B game_top.json
nextpnr-ice40 --hx1k --package vq100 --json game_top.json --pcf goboard.pcf --asc game_top.asc --freq 25
icepack game_top.asc game_top.bin
```

Require successful timing at 25 MHz, no overuse of resources, no out-of-bounds ROM/RAM access, and safe maximum latency at 0.1 ms. Save the candidate bitstream and hashes in a separate release; never overwrite V2.3. Verify actual master connection, power-on/reset between rounds, no stale decisions, SPI polarity and pinout. Do not flash until all software/RTL/synthesis checks pass and the user explicitly initiates programming. Implement and benchmark the two hardware alternatives plus software-only baseline required by the assignment; document IC, cycles, CPI, Ops/s, Amdahl, roofline, LUTs/BRAM, Fmax and testbenches. These are not yet completed.

Expected META: $19,239, 76 orders, $380 fees, $3,815 maximum monetary drawdown, 23.9726% maximum relative drawdown. HOLD $10,000; B&H $9,695 on this series. Historical mean +16.2883%, 34/48 positive, worst -18.23%, best +101.18%.

## Actualización de la versión final

La implementación definitiva, los comandos vigentes y los resultados verificados se documentan en el [README principal](../../README.md). Las advertencias sobre síntesis y simulación pendientes corresponden a la etapa inicial de desarrollo.
