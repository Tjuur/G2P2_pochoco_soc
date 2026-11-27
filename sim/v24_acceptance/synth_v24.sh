#!/usr/bin/env bash
set -euo pipefail
# Run from repository root; no make default target and no programming.
OUT=build/v24_acceptance/synth
mkdir -p "$OUT"
for c in yosys nextpnr-ice40 icepack; do command -v "$c" >/dev/null || { echo "Missing $c"; exit 1; }; done
# Verify frozen binary prior to any synthesis. This script does not rebuild it.
python3 - <<'PY'
from pathlib import Path
import hashlib,json
m=json.loads(Path('sw/v24/manifest.json').read_text())
for f in ('sw/trade.hex','sw/trade.s','rtl/pochoco_soc.v','rtl/pochoco_v24_mem.v'):
    assert hashlib.sha256(Path(f).read_bytes()).hexdigest()==m['files'][f],f'Changed since delivery: {f}'
PY
rm -f "$OUT/game_top.json" "$OUT/game_top.asc" "$OUT/game_top.bin"
yosys -p "read_verilog $(find rtl -name '*.v' | sort | tr '\n' ' '); synth_ice40 -top game_top -json $OUT/game_top.json; stat" 2>&1 | tee "$OUT/yosys.log"
nextpnr-ice40 --hx1k --package vq100 --json "$OUT/game_top.json" --pcf goboard.pcf --asc "$OUT/game_top.asc" --freq 25 2>&1 | tee "$OUT/nextpnr.log"
icepack "$OUT/game_top.asc" "$OUT/game_top.bin"
shasum -a 256 "$OUT/game_top.bin" | tee "$OUT/bitstream.sha256"
echo "Built candidate $OUT/game_top.bin (not programmed; RTL and physical validation still required)."
