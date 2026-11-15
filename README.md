# complex-lab

Repository for the RISC-V computer organization comprehensive lab.

## Current status

This repository contains:

- The detailed requirements and three-person division document.
- A Lab5 reference implementation.
- Lab5 testbenches and program files.
- Lab5 simulation waveform figures.

The Lab5 reference implementation is a multi-cycle CPU.
The comprehensive lab requires a five-stage pipelined CPU.
Use the Lab5 code as a reference only.
Do not submit the Lab5 CPU as the final comprehensive lab CPU.

## Repository layout

```text
docs/
  01-requirements-and-division.md
  lab5/
    lab5-simulation-summary.md
    wave_branch.png
    wave_memory.png
    wave_uart.png
reference/
  lab5/
    rtl/core/        Lab5 CPU and SoC RTL
    rtl/board/       Board top
    rtl/common/      SRAM/UART controllers and mux
    sim/             Lab5 testbenches and models
    program/         Target program and test program
    constraints/     Board constraints
    ip/              PLL IP configuration
```

## Read first

1. `docs/01-requirements-and-division.md`
2. `reference/lab5/README.md`
3. `docs/lab5/lab5-simulation-summary.md`

## Important

- The repository does not include course HTML, PDF, or cloud screenshots.
- Some reference files derive from course templates.
- Keep this repository private.
- Do not redistribute course materials.
- Fill all `【待确认】` items before coding starts.
- Freeze interfaces before integration.

## Next steps

1. Confirm the three assigned B-extension instructions.
2. Obtain the monitor program documents and binaries.
3. Freeze the CPU, CSR, and MMU interfaces.
4. Start the three work streams in parallel.
5. Tag each milestone.
