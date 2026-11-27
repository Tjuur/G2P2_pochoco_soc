#!/usr/bin/env bash
# Build only assembly. Never flash. Default GNU toolchain matches sw/Makefile.
set -euo pipefail
cd "$(dirname "$0")/../.."
PREFIX=${PREFIX:-riscv64-elf-}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
"${PREFIX}as" -march=rv32e -mabi=ilp32e -o "$T/trade.o" sw/trade.s
"${PREFIX}ld" -m elf32lriscv -Ttext=0x0 --no-relax -e _start -o "$T/trade.elf" "$T/trade.o"
"${PREFIX}objcopy" -O binary "$T/trade.elf" "$T/trade.bin"
python3 - "$T/trade.bin" "$T/trade.hex" <<'PY'
import struct,sys,pathlib
b=pathlib.Path(sys.argv[1]).read_bytes(); assert len(b)%4==0
w=[x[0] for x in struct.iter_unpack('<I',b)]; assert len(w)<=1024
pathlib.Path(sys.argv[2]).write_text(''.join(f'{x:08x}\n' for x in w+[0x13]*(1024-len(w))))
print('Assembled instruction words:',len(w))
PY
if cmp -s "$T/trade.hex" sw/trade.hex; then
  echo 'PASS rebuild matches delivered hex byte-for-byte'
else
  echo 'Rebuild differs from delivered hex; preserving delivered hex. Validate new build separately.' >&2
  exit 1
fi
