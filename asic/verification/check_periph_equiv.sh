#!/bin/bash
set -euo pipefail

mkdir -p asic/reports/optimization

COUNTER="rtl/cycle_counter.v"

if [ ! -f "$COUNTER" ]; then
    COUNTER="asic/rtl/cycle_counter_optimized.v"
fi

if [ ! -f "$COUNTER" ]; then
    echo "ERROR: No se encontró el módulo cycle_counter."
    exit 1
fi

yosys -l asic/reports/optimization/periph_equivalence.log -p "
    read_verilog $COUNTER /tmp/pochoco_periph_baseline.v
    hierarchy -check -top pochoco_periph
    proc
    memory_map
    flatten
    async2sync
    opt
    rename pochoco_periph gold

    design -stash gold

    design -reset
    read_verilog $COUNTER rtl/pochoco_periph.v
    hierarchy -check -top pochoco_periph
    proc
    memory_map
    flatten
    async2sync
    opt
    rename pochoco_periph gate

    design -stash gate

    design -reset
    design -copy-from gold -as gold gold
    design -copy-from gate -as gate gate

    equiv_make gold gate equiv
    hierarchy -top equiv
    equiv_simple
    equiv_induct -seq 10
    equiv_status -assert
"

echo ""
echo "EQUIVALENCE CHECK PASSED"
