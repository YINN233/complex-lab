# Lab5 仿真结果整理

> 说明：本文记录 Lab5 本地 2025 工程的验证结果。  
> 2026 分支的顶层为 `thinpad_top`，仿真顶层为 `lab5_tb`。  
> 本文作为综合实验的参考记录，不代表综合实验最终 CPU。


## 1. 仿真环境

- iverilog 12.0。
- SystemVerilog 模式。
- Vivado 工程：`rv-2025/rv-2025/thinpad_top/thinpad_top.xpr`。
- 综合顶层：`lab5_cpu_top`。
- 仿真顶层：`lab5_cpu_top_tb`。
- iverilog 会输出 `constant selects in always_*` 警告。该警告来自 iverilog 12 的限制，不影响仿真结果。Vivado 不受该限制影响。

## 2. 测试清单

| 测试 | 文件 | 结果 |
|---|---|---|
| ALU | `tb_alu32.sv` | `ALU32 TEST PASSED` |
| 寄存器堆 | `tb_regfile32.sv` | `REGFILE32 TEST PASSED` |
| 立即数 | `tb_imm_gen.sv` | `IMM_GEN TEST PASSED` |
| 译码器 | `tb_decoder.sv` | `DECODER TEST PASSED` |
| Wishbone Master | `tb_wb_master.sv` | `WB_MASTER TEST PASSED` |
| 完整程序 | `tb_lab5_cpu.sv` | `LAB5 CPU TEST PASSED` |
| 字节与符号扩展 | `tb_lab5_mem.sv` | `LAB5 MEM TEST PASSED` |
| 短程序波形 | `lab5_cpu_wave_tb.sv` | `LAB5 WAVE TEST PASSED` |
| 顶层 | `lab5_cpu_top_tb.sv` | `LAB5 TOP TEST PASSED` |

## 3. 完整程序仿真

### 3.1 配置

- 时钟：10 MHz。
- 复位：300 ns 后释放。
- BaseRAM：`sram_model_lab5`，预装 `sum.mem` 的 36 条指令。
- UART：真实 `uart_controller`。
- 检查点：5 个 UART 字节和 BaseRAM 结果。

### 3.2 关键输出

```text
MEM WRITE: pc=80000020 inst=1072a023 addr=80000100 data=000013ba
UART WRITE: pc=80000038 inst=00a28023 data=00000064
UART[0] = 64 (d)
UART WRITE: pc=8000004c inst=00a28023 data=0000006f
UART[1] = 6f (o)
UART WRITE: pc=80000060 inst=00a28023 data=0000006e
UART[2] = 6e (n)
UART WRITE: pc=80000074 inst=00a28023 data=00000065
UART[3] = 65 (e)
UART WRITE: pc=80000088 inst=00a28023 data=00000021
UART[4] = 21 (!)
LAB5 CPU TEST PASSED
```

### 3.3 结果说明

| 项目 | 值 |
|---|---|
| 写内存指令 | `0x1072A023`，即 `sw t2, 0x100(t0)` |
| 写内存地址 | `0x8000_0100` |
| 写内存数据 | `0x0000_13BA`，即 5050 |
| UART 数据 | `64 6F 6E 65 21`，即 `done!` |
| 结束 PC | `0x8000_008C` |
| 仿真结束时间 | 723.85 us |

BaseRAM 本地偏移 `0x100` 的 4 个字节为 `BA 13 00 00`。  
该结果与实验要求一致。

## 4. 指令译码对照

| PC | 指令编码 | 汇编 | 说明 |
|---|---|---|---|
| `0x8000_0020` | `0x1072A023` | `sw t2, 0x100(t0)` | 写结果 5050 |
| `0x8000_0038` | `0x00A28023` | `sb a0, 0(t0)` | 发送 `d` |
| `0x8000_004C` | `0x00A28023` | `sb a0, 0(t0)` | 发送 `o` |
| `0x8000_0060` | `0x00A28023` | `sb a0, 0(t0)` | 发送 `n` |
| `0x8000_0074` | `0x00A28023` | `sb a0, 0(t0)` | 发送 `e` |
| `0x8000_0088` | `0x00A28023` | `sb a0, 0(t0)` | 发送 `!` |

## 5. 短程序波形

### 5.1 配置

- 时钟：100 MHz，仅用于压缩波形。
- 复位：40 ns 后释放。
- 程序：10 条指令。
- 覆盖：跳转、写内存、写串口。
- 仿真结束时间：865 ns。

### 5.2 指令译码输出

```text
t=105000 DECODE: pc=80000000 inst=00100293
t=195000 DECODE: pc=80000004 inst=00100313
t=285000 DECODE: pc=80000008 inst=00628463
t=295000 BRANCH TAKEN: pc=80000008 imm=00000008 target=80000010
t=365000 DECODE: pc=80000010 inst=800002b7
t=455000 DECODE: pc=80000014 inst=1062a023
t=485000 MEM WRITE: pc=80000014 inst=1062a023 addr=80000100 data=00000001
t=605000 DECODE: pc=80000018 inst=100002b7
t=695000 DECODE: pc=8000001c inst=04100513
t=785000 DECODE: pc=80000020 inst=00a28023
t=815000 UART WRITE: pc=80000020 inst=00a28023 data=00000041
t=825000 UART VALID: data=41
LAB5 WAVE TEST PASSED
```

### 5.3 跳转说明

- 时间约 295 ns。
- `pc=0x8000_0008` 的指令为 `0x00628463`，即 `beq t0, t1, target`。
- `t0=1`，`t1=1`，比较结果相等。
- 分支成立。
- 分支目标为 `0x8000_0010`。
- 下一条译码 PC 为 `0x8000_0010`。
- `0x8000_000C` 的指令被跳过。
- 该指令为 `addi t2, zero, 0x7ff`。
- 测试检查 `t2=0`，说明跳转路径正确。

### 5.4 写内存说明

- 时间约 485 ns。
- `pc=0x8000_0014` 的指令为 `0x1062A023`，即 `sw t1, 0x100(t0)`。
- 写地址为 `0x8000_0100`。
- 写数据为 `0x0000_0001`。
- 测试检查 BaseRAM 字地址 `0x40` 为 `0x0000_0001`。

### 5.5 写串口说明

- 时间约 815 ns。
- `pc=0x8000_0020` 的指令为 `0x00A28023`，即 `sb a0, 0(t0)`。
- 写地址为 `0x1000_0000`。
- 写数据低 8 位为 `0x41`，即 `A`。
- `uart_valid` 在约 825 ns 有效。
- 测试检查 UART 捕获字节为 `0x41`。

## 6. 字节与符号扩展测试

### 6.1 程序

测试程序见 `asmcode/memtest.s`。  
测试程序依次执行：

1. 清零字 `0x8000_0100`。
2. 向字节地址 `0x8000_0101` 写入 `0x80`。
3. 用 `lb` 读回 `0x8000_0101`。
4. 把读回值写到 `0x8000_0104`。
5. 向字节地址 `0x8000_0102` 写入 `0x7F`。
6. 用 `lb` 读回 `0x8000_0102`。
7. 把读回值写到 `0x8000_0108`。

### 6.2 结果

| 地址 | 值 | 说明 |
|---|---|---|
| `0x8000_0100` | `0x007F_8000` | 字节 1 为 `0x80`，字节 2 为 `0x7F` |
| `0x8000_0104` | `0xFFFF_FF80` | `lb` 对 `0x80` 做符号扩展 |
| `0x8000_0108` | `0x0000_007F` | `lb` 对 `0x7F` 做符号扩展 |

测试输出：

```text
LAB5 MEM TEST PASSED
```

## 7. 顶层仿真

### 7.1 配置

- 顶层：`lab5_cpu_top`。
- 时钟：测试平台生成 10 MHz 时钟。
- 复位：测试平台强制 `sys_rst`。
- PLL：Vivado 使用真实 `pll_example`；iverilog 使用 `pll_example_stub.sv`。
- UART：真实 `uart_controller`。
- 结果检查：BaseRAM 和 UART 字节。

### 7.2 结果

```text
LAB5 TOP TEST PASSED
```

## 8. Vivado 仿真注意事项

1. `pll_example_stub.sv` 只用于 iverilog。不要把它加入 Vivado 工程。
2. 顶层仿真直接强制 `sys_clk` 和 `sys_rst`，不依赖 PLL 模型。
   若 Vivado 不允许强制 `sys_clk`，改为强制 `dut.clk_10M` 和 `dut.reset_of_clk10M`，与 Lab3/Lab4 相同。
3. `sram_model_lab5.sv` 和 `wb_uart_model.sv` 只用于仿真。
4. Vivado 仿真顶层设为 `lab5_cpu_top_tb`。
5. 波形演示仿真顶层设为 `lab5_cpu_wave_tb`。
6. 完整程序仿真顶层设为 `tb_lab5_cpu`。
7. `tb_lab5_mem` 用于字节 lane 和 `lb` 符号扩展检查。

## 9. 报告插图建议

1. 完整程序仿真 Tcl Console：`LAB5 CPU TEST PASSED`。
2. `sw` 波形：约 485 ns；`state`、`pc_now`、`inst`、`wb_*`、`sram_*`。
3. `sb` 波形：约 815 ns；`wb_adr=0x1000_0000`、`wb_dat=0x41`、`wb_sel=0001`、`wb_ack`、`txd_start`、`txd_data`。
4. 分支波形：约 295 ns；`pc_now=0x8000_0008`、`inst=0x00628463`、`zero=1`、`pc=0x8000_0010`。
5. 内存截图：BaseRAM 偏移 `0x100`，值 `BA 13 00 00`。
6. 串口截图：`done!`。

Vivado 波形分组脚本：

```tcl
source reference/lab5/sim/lab5_wave.tcl
```

脚本运行 1000 ns。  
波形测试在 865 ns 结束。

## 10. 已生成的报告波形图

已生成三张波形图：

- `wave_branch.png`
- `wave_memory.png`
- `wave_uart.png`

生成方法：

- 使用 `lab5_cpu_wave_tb`。
- 使用 iverilog 12 导出 VCD。
- 使用 `reference/lab5/sim/render_waveforms.py` 绘图。
- 演示时钟为 100 MHz。实际硬件时钟为 10 MHz。

三张图的内容：

| 图 | 事件 | 时间 |
|---|---|---|
| `wave_branch.png` | `beq t0, t1, target` | 约 295 ns |
| `wave_memory.png` | `sw t1, 0x100(t0)` | 约 485 ns |
| `wave_uart.png` | `sb a0, 0(t0)`，数据 `0x41` | 约 815 ns |

如果课程要求必须使用 Vivado 截图，可按相同时间窗口和信号在 Vivado 中截取。  
如果允许使用仿真导出波形，可直接把这三张 PNG 插入报告。
