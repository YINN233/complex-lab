# complex-lab

Repository for the RISC-V computer organization comprehensive lab.

## Lab6 Ver.2 monitor

The core adds machine CSRs, M/U mode transitions, exceptions, and interrupt
handling. The SoC exposes the CLINT timer at `0x0200bff8` (`mtime`) and
`0x02004000` (`mtimecmp`), with the high word at each base address plus four.

Build both monitor images with the course sources. The default regression
uses Ver.1, and the other two commands exercise Ver.2 and UART RX interrupts.

```powershell
python scripts/build_images.py --toolchain-dir "path/to/toolchain/bin" --monitor "path/to/supervisor-rv/kernel"
python scripts/build_images.py --toolchain-dir "path/to/toolchain/bin" --monitor "path/to/supervisor-rv/kernel" --monitor-version 2
python scripts/run_sim.py --vivado-bin "path/to/Vivado/bin"
python scripts/run_sim.py --vivado-bin "path/to/Vivado/bin" --test monitor-ver2
python scripts/run_sim.py --vivado-bin "path/to/Vivado/bin" --test irq
```

Load `build/images/monitor-ver2.bin` at BaseRAM byte offset 0 when testing the
Ver.2 monitor on ThinPAD. The FPGA build command and the rest of the board
setup are in the [base implementation notes](docs/lab6-base.md#thinpad-上板验收).

The course Ver.2 monitor uses CLINT for user-program timeouts and polls UART.
A custom handler can enable UART RX machine external interrupts by setting
bit 0 of the byte at `0x10000001` and enabling MEIE. Reading the received
byte from `0x10000000` clears the RX interrupt.

## 第 56 组交接

该分支已通过 Ver.1 回归、Ver.2 监控程序和独立 UART 接收中断仿真。Ver.2 测试覆盖 `ECALL`、`EBREAK`、非法指令及原始 1000 万周期超时。四个性能测例在仿真中各跑三次循环。Vivado 通过 10 MHz 时序检查。课程 GitLab 的同版 RTL 已生成位流并出现在 ThinPAD 的 CI 编译结果列表中。CI 日志显示 Verilator 返回非零，诊断见 `linter.log`，待排查。

| 事项 | 负责人 | 交接 |
| --- | --- | --- |
| 大实验功能测试 | B 主办，A 协助 | 在 ThinPAD 选择课程 GitLab 的 `lab6/grp56-ver2` 编译结果。每次提交会运行基础、A、B 三组测例。优先检查 B01–B20 的监控命令、BaseRAM/ExtRAM、UART 和复位。 |
| 额外指令测试 | A、B | 对同一 CI 位流运行 `SBSET`、`SBCLR`、`CLZ`。本地仿真在 `0x8040_0100` 读回四个字 `0x80000000`、`0x00000000`、`0x00000020`、`0x0000001f`。 |
| 性能与最终记录 | 全组，B 汇总 | 若纳入性能测试，用同一 CI 位流复测。保存 CI 任务号、评测任务号、得分和板上截图。确认后在 ThinPAD 评测列表标记最终版本，最终标记使用 GitLab CI 产物。 |
| Ver.2 中断异常测试 | B 负责总线，A/C 负责 CPU | 本地监控程序已经跑通。未映射的 Wishbone 请求可能一直等待应答。B 需把总线错误返回给请求方，A/C 需把取指、读、写错误分别转成精确异常 `1`、`5`、`7`，验证 `mepc` 和故障指令副作用。 |
| Ver.3 页表测试 | C 实现，B 集成 | 等 Sv32 地址翻译和缺页处理就绪后，再接监控程序 Ver.3。 |

手动上板时，把 `monitor-ver2.bin` 写入 BaseRAM 字节偏移 0，DIP0 置零，直连串口设为 115200、8N1，复位检查启动横幅。再用 `build/images/monitor-ver2-tests.txt` 的入口运行 `UTEST_PUTC` 和 `UTEST_SPIN`，分别记录 `OK` 及超时后恢复交互的结果。自动评测、实板截图和最终标记以课程平台记录为准。

评测入口和详细分工见 [ThinPAD 自动评测](https://lab.cs.tsinghua.edu.cn/thinpad/judge) 和 [三人分工](docs/01-requirements-and-division.md#63-b-的任务)。

## Lab6 base implementation

The `lab6/grp56-base` branch implements a five-stage ThinPAD CPU for the
32-bit Ver.1 monitor, with the group’s `SBSET`, `SBCLR` and `CLZ` instructions
from Bitmanip 0.92. See the [Lab6 implementation and verification notes](docs/lab6-base.md)
for build commands, board setup, and verification results.

- `rtl/core/` contains the CPU, decoder and ALU.
- `rtl/soc/` connects the two Wishbone masters to BaseRAM, ExtRAM and UART.
- `rtl/board/` provides the ThinPAD top and the single-step clock.
- `sim/` contains the CPU, arbiter and UART/monitor regression tests.
- `scripts/` contains the Vivado build and simulation entry points.

## Reference material

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
