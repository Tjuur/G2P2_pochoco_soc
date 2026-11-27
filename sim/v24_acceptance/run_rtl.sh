#!/usr/bin/env bash
set -euo pipefail
# Run from repository root after assembling the actual candidate; never flashes.
D=sim/v24_acceptance
OUT=build/v24_acceptance
MODE=${1:-quick}
case "$MODE" in smoke|quick|full|all) ;; *) echo 'Usage: run_rtl.sh [smoke|quick|full|all]' >&2; exit 2;; esac
for c in iverilog vvp yosys-config python3; do command -v "$c" >/dev/null || { echo "Missing $c"; exit 1; }; done
[ -f sw/trade.hex ] || { echo 'Assemble the V24-T candidate first (not V2.3).'; exit 1; }
[ -f "$OUT/META/expected.csv" ] || python3 "$D/acceptance.py"
mkdir -p "$OUT/rtl"
iverilog -g2012 -s tb_v24_mem -o "$OUT/rtl/mem_tb" rtl/pochoco_v24_mem.v "$D/tb_v24_mem.sv"
vvp -n "$OUT/rtl/mem_tb"
iverilog -g2012 -s tb_v24_acceptance -o "$OUT/rtl/tb" \
  "$(yosys-config --datdir)/ice40/cells_sim.v" rtl/*.v rtl/espino_core/*.v "$D/tb_v24_acceptance.sv"
run(){
  local name=$1 n=$2 period=$3 half=$4 phase=$5 repeat=$6 tag="${1}_${2}_${3}_${4}_${5}_${6}"
  local x="$OUT/$name" y="$OUT/rtl/$tag"
  echo "=== $tag ==="
  vvp -n "$OUT/rtl/tb" "+PRICES=$x/prices.hex" "+DECISIONS=$x/decisions.hex" "+NEXT=$x/next.hex" "+OUT=$y.csv" "+N=$n" "+PERIOD=$period" "+HALF=$half" "+PHASE=$phase" "+REPEAT=$repeat" | tee "$y.log"
  grep -q 'PASS RTL SPI' "$y.log"
  python3 "$D/acceptance.py" --compare "$x/expected.csv" "$y.csv" --limit "$n"
}
# Small integration check before the much longer suites.
if [ "$MODE" = smoke ]; then
  run META 4096 100000 500 7 1
  run META 2048 100000 1000 19 2
  echo 'PASS smoke RTL tests'
  exit 0
fi
# Full practice at fastest period, three clock phases, two SPI rates, reset between rounds.
run META 20000 100000 500 7 1
run META 2048 100000 500 19 2
run META 2048 100000 1000 33 1
# Slow rounds: quick mode is a protocol smoke test, not a full competition run.
if [ "$MODE" = quick ]; then
  run META 2048 1000000 500 7 1
  run META 2048 10000000 500 7 1
else
  run META 20000 1000000 500 7 1
  run META 20000 10000000 500 7 1
fi
# Stress series at the hardest deadline.
for name in constant_100 constant_255 alternating_100_255 ramp_up ramp_down cliff_recovery sawtooth random_full pdf_range_1_255 pdf_range_cliff; do
  run "$name" 20000 100000 500 7 1
done
if [ "$MODE" = all ]; then
  for x in "$OUT"/*_real "$OUT"/SINTETICO_*; do
    [ -d "$x" ] || continue
    run "$(basename "$x")" 20000 100000 500 7 1
  done
fi
echo 'PASS all selected RTL tests (physical test and synthesis remain separate).'
