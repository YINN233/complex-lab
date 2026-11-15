#!/usr/bin/env python3
"""Render report-ready Lab5 waveform figures from an Icarus VCD file."""

from __future__ import annotations

import sys
from bisect import bisect_right
from collections import defaultdict
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

ROOT = Path(__file__).resolve().parent
DEFAULT_VCD = Path("/tmp/lab5_cpu_wave.vcd")


def parse_vcd(path: Path):
    scopes: list[str] = []
    name_to_code: dict[str, str] = {}
    code_to_names: dict[str, list[str]] = defaultdict(list)
    widths: dict[str, int] = {}
    changes: dict[str, list[tuple[int, str]]] = defaultdict(list)
    now = 0

    with path.open("r", errors="replace") as handle:
        for raw in handle:
            line = raw.strip()
            if not line:
                continue
            if line.startswith("$scope"):
                scopes.append(line.split()[2])
                continue
            if line.startswith("$upscope"):
                if scopes:
                    scopes.pop()
                continue
            if line.startswith("$var"):
                parts = line.split()
                width = int(parts[2])
                code = parts[3]
                name = parts[4]
                full = ".".join(scopes + [name])
                name_to_code[full] = code
                code_to_names[code].append(full)
                widths[full] = width
                continue
            if line.startswith("$"):
                continue
            if line.startswith("#"):
                now = int(line[1:])
                continue

            first = line[0]
            if first in "01xzXZ":
                changes[line[1:]].append((now, first))
            elif first in "bB":
                parts = line[1:].split()
                if len(parts) >= 2:
                    changes[parts[1]].append((now, parts[0]))

    signals: dict[str, list[tuple[int, str]]] = {}
    for full, code in name_to_code.items():
        signals[full] = changes.get(code, [])
    return signals, widths


def value_at(signal: list[tuple[int, str]], time_ps: int) -> str:
    if not signal:
        return "x"
    times = [item[0] for item in signal]
    index = bisect_right(times, time_ps) - 1
    if index < 0:
        return signal[0][1]
    return signal[index][1]


def segments(signal: list[tuple[int, str]], start_ps: int, end_ps: int):
    points = [start_ps]
    for time_ps, _ in signal:
        if start_ps < time_ps < end_ps:
            points.append(time_ps)
    points.append(end_ps)
    for left, right in zip(points, points[1:]):
        yield left / 1000.0, right / 1000.0, value_at(signal, left)


def bin_to_int(value: str):
    if not value or any(ch not in "01" for ch in value):
        return None
    return int(value, 2)


def bus_text(value: str, width: int) -> str:
    if value in ("x", "z", "X", "Z"):
        return value.upper()
    number = bin_to_int(value)
    if number is None:
        return value.upper()
    if width == 4:
        return f"{number:04b}"
    digits = max(1, (width + 3) // 4)
    return f"0x{number:0{digits}X}"


STATE_NAMES = {
    0: "FETCH",
    1: "DECODE",
    2: "EXEC",
    3: "MEM_R",
    4: "MEM_W",
    5: "WB",
}


def state_text(value: str) -> str:
    number = bin_to_int(value)
    if number is None:
        return "X"
    return STATE_NAMES.get(number, str(number))


def draw_row(ax, signal, width, start_ps, end_ps, kind="bus", label=None, color="#1f2937"):
    if label is None:
        label = ""
    if kind == "clock":
        for left, right, value in segments(signal, start_ps, end_ps):
            y = 0.78 if value == "1" else 0.22
            ax.plot([left, right], [y, y], color=color, linewidth=1.0)
            ax.plot([left, left], [0.22, 0.78], color=color, linewidth=0.7)
    elif kind == "bit":
        previous = None
        for left, right, value in segments(signal, start_ps, end_ps):
            y = 0.78 if value == "1" else 0.22
            ax.plot([left, right], [y, y], color=color, linewidth=1.2)
            if previous is not None and previous != y:
                ax.plot([left, left], [previous, y], color=color, linewidth=1.0)
            previous = y
    elif kind == "state":
        previous_y = None
        for left, right, value in segments(signal, start_ps, end_ps):
            if right - left < 1:
                continue
            ax.add_patch(
                Rectangle(
                    (left, 0.18),
                    right - left,
                    0.64,
                    facecolor="#eef2ff",
                    edgecolor="#4f46e5",
                    linewidth=0.6,
                )
            )
            text = state_text(value)
            if right - left > 8.0:
                ax.text(
                    (left + right) / 2,
                    0.50,
                    text,
                    ha="center",
                    va="center",
                    fontsize=6.5,
                    color="#1e1b4b",
                )
            if previous_y is not None:
                ax.plot([left, left], [0.18, 0.82], color="#4f46e5", linewidth=0.6)
            previous_y = 0.5
    else:
        previous_y = None
        for left, right, value in segments(signal, start_ps, end_ps):
            if right - left < 1:
                continue
            ax.add_patch(
                Rectangle(
                    (left, 0.18),
                    right - left,
                    0.64,
                    facecolor="#e0f2fe",
                    edgecolor="#0284c7",
                    linewidth=0.6,
                )
            )
            text = bus_text(value, width)
            if right - left > 10.0:
                ax.text(
                    (left + right) / 2,
                    0.50,
                    text,
                    ha="center",
                    va="center",
                    fontsize=6.5,
                    color="#0c4a6e",
                )
            if previous_y is not None:
                ax.plot([left, left], [0.18, 0.82], color="#0284c7", linewidth=0.6)
            previous_y = 0.5

    ax.set_ylim(0.0, 1.0)
    ax.set_yticks([])
    ax.set_ylabel(label, rotation=0, ha="right", va="center", fontsize=8, labelpad=18)
    ax.tick_params(axis="y", length=0)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.grid(axis="x", color="#d1d5db", linewidth=0.4, alpha=0.8)
    ax.set_facecolor("white")


def render(
    name: str,
    title: str,
    note: str,
    rows: list[tuple[str, str, str, str]],
    start_ns: float,
    end_ns: float,
    event_ns: float,
    out_path: Path,
    signals,
    widths,
):
    fig, axes = plt.subplots(
        len(rows),
        1,
        figsize=(14.0, 0.42 * len(rows) + 1.8),
        sharex=True,
        gridspec_kw={"hspace": 0.06},
    )
    if len(rows) == 1:
        axes = [axes]

    start_ps = int(start_ns * 1000)
    end_ps = int(end_ns * 1000)
    for ax, (full_name, label, kind, _) in zip(axes, rows):
        signal = signals.get(full_name, [(0, "x")])
        width = widths.get(full_name, 1)
        draw_row(ax, signal, width, start_ps, end_ps, kind=kind, label=label)
        ax.axvline(event_ns, color="#dc2626", linewidth=1.0, linestyle="--", alpha=0.75)

    axes[-1].set_xlim(start_ns, end_ns)
    axes[-1].set_xlabel("Time (ns)", fontsize=9)
    axes[-1].tick_params(axis="x", labelsize=8)
    for ax in axes[:-1]:
        ax.tick_params(axis="x", labelbottom=False)

    fig.suptitle(title, x=0.02, ha="left", fontsize=13, fontweight="bold", y=0.985)
    fig.text(0.02, 0.945, note, ha="left", fontsize=8.5, color="#374151")
    fig.text(
        0.98,
        0.985,
        f"event @ {event_ns:g} ns",
        ha="right",
        fontsize=8.5,
        color="#dc2626",
    )
    fig.subplots_adjust(left=0.19, right=0.985, top=0.91, bottom=0.065)
    fig.savefig(out_path, dpi=220, facecolor="white")
    plt.close(fig)
    print(f"wrote {out_path}")


def main() -> int:
    vcd_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_VCD
    signals, widths = parse_vcd(vcd_path)

    top = "lab5_cpu_wave_tb."
    cpu = top + "u_cpu."

    render(
        "branch",
        "Lab5 multi-cycle CPU: taken branch",
        "beq t0, t1, target  |  pc_now = 0x8000_0008, imm = 8, target = 0x8000_0010",
        [
            (top + "clk", "clk", "clock", ""),
            (cpu + "state", "state", "state", ""),
            (cpu + "pc", "pc", "bus", ""),
            (cpu + "pc_now", "pc_now", "bus", ""),
            (cpu + "inst", "inst", "bus", ""),
            (cpu + "operand1", "rs1 (t0)", "bus", ""),
            (cpu + "operand2", "rs2 (t1)", "bus", ""),
            (cpu + "imm", "imm", "bus", ""),
            (cpu + "zero", "zero", "bit", ""),
            (cpu + "branch", "branch", "bit", ""),
            (top + "cpu_wb_adr", "wb_adr", "bus", ""),
            (top + "cpu_wb_dat_i", "wb_dat_i", "bus", ""),
        ],
        250.0,
        350.0,
        295.0,
        ROOT / "wave_branch.png",
        signals,
        widths,
    )

    render(
        "memory",
        "Lab5 multi-cycle CPU: store word",
        "sw t1, 0x100(t0)  |  addr = 0x8000_0100, data = 0x0000_0001",
        [
            (top + "clk", "clk", "clock", ""),
            (cpu + "state", "state", "state", ""),
            (cpu + "pc", "pc", "bus", ""),
            (cpu + "inst", "inst", "bus", ""),
            (cpu + "operand1", "rs1 (t0)", "bus", ""),
            (cpu + "operand2", "imm (offset)", "bus", ""),
            (cpu + "store_data", "store_data (t1)", "bus", ""),
            (cpu + "addr", "addr", "bus", ""),
            (top + "cpu_wb_cyc", "wb_cyc", "bit", ""),
            (top + "cpu_wb_stb", "wb_stb", "bit", ""),
            (top + "cpu_wb_ack", "wb_ack", "bit", ""),
            (top + "cpu_wb_adr", "wb_adr", "bus", ""),
            (top + "cpu_wb_dat_o", "wb_dat_o", "bus", ""),
            (top + "cpu_wb_sel", "wb_sel", "bus", ""),
            (top + "cpu_wb_we", "wb_we", "bit", ""),
            (top + "wbs0_cyc", "wbs0_cyc", "bit", ""),
            (top + "wbs0_stb", "wbs0_stb", "bit", ""),
            (top + "wbs0_ack", "wbs0_ack", "bit", ""),
            (top + "wbs0_we", "wbs0_we", "bit", ""),
            (top + "sram_addr", "sram_addr", "bus", ""),
            (top + "sram_data", "sram_data", "bus", ""),
            (top + "sram_we_n", "sram_we_n", "bit", ""),
            (top + "sram_be_n", "sram_be_n", "bus", ""),
        ],
        430.0,
        540.0,
        485.0,
        ROOT / "wave_memory.png",
        signals,
        widths,
    )

    render(
        "uart",
        "Lab5 multi-cycle CPU: store byte to UART",
        "sb a0, 0(t0)  |  addr = 0x1000_0000, data = 0x41 ('A')",
        [
            (top + "clk", "clk", "clock", ""),
            (cpu + "state", "state", "state", ""),
            (cpu + "pc", "pc", "bus", ""),
            (cpu + "inst", "inst", "bus", ""),
            (cpu + "operand1", "rs1 (t0)", "bus", ""),
            (cpu + "operand2", "imm (offset)", "bus", ""),
            (cpu + "store_data", "store_data (a0)", "bus", ""),
            (top + "cpu_wb_cyc", "wb_cyc", "bit", ""),
            (top + "cpu_wb_stb", "wb_stb", "bit", ""),
            (top + "cpu_wb_ack", "wb_ack", "bit", ""),
            (top + "cpu_wb_adr", "wb_adr", "bus", ""),
            (top + "cpu_wb_dat_o", "wb_dat_o", "bus", ""),
            (top + "cpu_wb_sel", "wb_sel", "bus", ""),
            (top + "cpu_wb_we", "wb_we", "bit", ""),
            (top + "wbs2_cyc", "wbs2_cyc", "bit", ""),
            (top + "wbs2_stb", "wbs2_stb", "bit", ""),
            (top + "wbs2_ack", "wbs2_ack", "bit", ""),
            (top + "wbs2_adr", "wbs2_adr", "bus", ""),
            (top + "wbs2_dat_o", "wbs2_dat_o", "bus", ""),
            (top + "wbs2_sel", "wbs2_sel", "bus", ""),
            (top + "uart_valid", "uart_valid", "bit", ""),
            (top + "uart_data", "uart_data", "bus", ""),
        ],
        760.0,
        860.0,
        815.0,
        ROOT / "wave_uart.png",
        signals,
        widths,
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
