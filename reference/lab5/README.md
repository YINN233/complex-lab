# Lab5 reference implementation

This directory contains the Lab5 reference code.

## Limitation

The reference CPU is multi-cycle.
The comprehensive lab requires a five-stage pipeline.
Reuse the ALU, register file, decoder, bus master, and controllers.
Do not reuse the multi-cycle control FSM as the final CPU.

## Top module

`rtl/board/thinpad_top.sv`

The top module contains:

- PLL.
- Reset logic.
- Board pins.
- `lab5_soc`.

## Core modules

| File | Purpose |
|---|---|
| `rtl/core/alu32.sv` | 32-bit ALU |
| `rtl/core/regfile32.sv` | 32 x 32 register file |
| `rtl/core/imm_gen.sv` | Immediate generator |
| `rtl/core/decoder.sv` | Instruction decoder |
| `rtl/core/wb_master.sv` | Wishbone master |
| `rtl/core/lab5_cpu.sv` | Multi-cycle CPU |
| `rtl/core/lab5_soc.sv` | CPU, bus, SRAM, UART |

## Common modules

| File | Purpose |
|---|---|
| `rtl/common/sram_controller.sv` | SRAM controller |
| `rtl/common/uart_controller.sv` | UART controller |
| `rtl/common/wb_mux_3.v` | Wishbone mux |
| `rtl/common/async.v` | UART PHY |

## Program

| File | Purpose |
|---|---|
| `program/sum.s` | Target program |
| `program/sum.bin` | Binary for BaseRAM |
| `program/sum.mem` | Word dump for simulation |
| `program/sum.dis` | Disassembly |
| `program/memtest.s` | Byte lane and sign extension test |

Load `sum.bin` into BaseRAM at byte offset `0x0`.

Expected results:

- UART output: `done!`
- BaseRAM offset `0x100`: `BA 13 00 00`

## Simulation

Top-level test:

- `sim/lab5_tb.sv`

Waveform test:

- `sim/lab5_cpu_wave_tb.sv`

Unit tests:

- `sim/tb_alu32.sv`
- `sim/tb_regfile32.sv`
- `sim/tb_imm_gen.sv`
- `sim/tb_decoder.sv`
- `sim/tb_wb_master.sv`
- `sim/tb_lab5_cpu.sv`
- `sim/tb_lab5_mem.sv`

## Vivado

Add the RTL files to a Vivado project.
Add `ip/pll_example.xci`.
Use `constraints/thinpad_top.xdc`.
Set `thinpad_top` as the synthesis top.
Set `lab5_tb` as the simulation top.

The `pll_example` IP must be generated before simulation and implementation.

## Notice

Some files derive from the course template.
Keep this repository private.
Do not redistribute course materials.
