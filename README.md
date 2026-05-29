# EEC180_lab5

Use `tb_updated.vt` for the official Lab 5 testbench from the TA.
The old `tb.vt` is intentionally not used.

Open [EEC180_lab5.qpf](EEC180_lab5.qpf) in Quartus. The hardware target is the DE10-Lite (`10M50DAF484C7G`) and the board wrapper is `top.v`.

FPGA demo controls:

- `KEY0`: active-low reset
- `KEY1`: clear the latched ready LED
- `SW[4:0]`: 32-entry bfloat16 RAM address
- `SW[6:5]`: operation select, `01` for square root and `10` for reciprocal
- `SW9`: display select, `0` shows result `y[15:0]`, `1` shows selected input `x[15:0]`
- `HEX3..HEX0`: selected 16-bit value in hex
- `LEDR[9]`: result-ready indicator latched after `done`

ModelSim commands:

```tcl
vlib work
vlog -work work -f compile_files.txt
vlog -work work tb_updated.vt
vsim -c work.tb -do "run -all; quit -f"
```

Custom exhaustive checker:

```tcl
vlog -work work tb_all_valid.vt
vsim -c work.tb_all_valid -do "run -all; quit -f"
```

Expected exhaustive result:

```text
EXHAUSTIVE PASS: tests=65024 min_cycles=10 max_cycles=12
```

Quartus DE10-Lite build:

```text
Device: 10M50DAF484C7G
SOF: output_files/EEC180_lab5.sof
Fmax: 60.09 MHz slow 1200mV 85C
Resource use: 1,387 logic elements, 198 registers, 8 embedded 9-bit multiplier elements
```
