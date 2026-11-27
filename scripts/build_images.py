"""Build the lab binaries and memory images with a RISC-V GNU toolchain."""

import argparse
import os
from pathlib import Path
import shutil
import struct
import subprocess


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build" / "images"


def write_words(binary: Path) -> None:
    data = binary.read_bytes()
    data += bytes(-len(data) % 4)
    words = (f"{word:08x}\n" for (word,) in struct.iter_unpack("<I", data))
    binary.with_suffix(".mem").write_text("".join(words), encoding="ascii")


def run(command):
    return subprocess.run([str(arg) for arg in command], check=True,
                          text=True, stdout=subprocess.PIPE).stdout


def csr_architecture(tool):
    # The course GCC 8.3 toolchain includes CSR instructions in rv32i.
    # Recent GNU assemblers expect Zicsr to be explicitly enabled.
    probe = subprocess.run(
        [tool("gcc"), "-march=rv32i_zicsr", "-mabi=ilp32", "-x", "assembler",
         "-c", "-o", os.devnull, "-"],
        input="csrr a0, mstatus\n", text=True, capture_output=True,
    )
    return "rv32i_zicsr" if probe.returncode == 0 else "rv32i"


def build_program(tool, name, address, entries=(), *, architecture="rv32i"):
    source = ROOT / "sim" / "programs" / f"{name}.S"
    elf = BUILD / f"{name}.elf"
    binary = BUILD / f"{name}.bin"
    run([tool("gcc"), f"-march={architecture}", "-mabi=ilp32", "-nostdlib", "-fno-pic",
         f"-Wl,-Ttext,{address:#x},--no-relax,--build-id=none", source, "-o", elf])
    run([tool("objcopy"), "-j", ".text", "-O", "binary", elf, binary])
    write_words(binary)
    if entries:
        write_entries(f"{name}-entries", read_symbols(tool, elf, ""), entries)


def read_symbols(tool, elf, prefix):
    symbols = {}
    for line in run([tool("nm"), elf]).splitlines():
        parts = line.split()
        if len(parts) == 3 and parts[2].startswith(prefix):
            symbols[parts[2]] = parts[0]
    return symbols


def write_entries(name, symbols, entries):
    (BUILD / f"{name}.mem").write_text(
        "".join(f"{symbols[entry]}\n" for entry in entries), encoding="ascii",
    )


def build_monitor(tool, source, version, csr_arch):
    sources = sorted((source / "kern").glob("*.S"))
    if not sources:
        raise SystemExit(f"No monitor assembly sources under {source / 'kern'}")
    name = "monitor"
    architecture = "rv32i"
    defines = ["-D__ASSEMBLY__", "-DRV32"]
    tests = ["SIMPLE", "1PTB", "2DCT", "3CCT", "4MDCT"]
    if version == 2:
        name = "monitor-ver2"
        architecture = csr_arch
        defines.append("-DENABLE_INT")
        tests.extend(("PUTC", "SPIN"))

    objects = []
    for asm in sources:
        obj = BUILD / f"{name}-{asm.stem}.o"
        run([tool("gcc"), "-c", f"-march={architecture}", "-mabi=ilp32", "-fno-pic",
             *defines, "-I", source / "include", asm, "-o", obj])
        objects.append(obj)
    elf = BUILD / f"{name}.elf"
    binary = BUILD / f"{name}.bin"
    run([tool("ld"), "-m", "elf32lriscv", *objects,
         "-T", source / "kern" / "kernel32.ld", "-o", elf])
    run([tool("objcopy"), "-j", ".text", "-j", ".text.*", "-j", ".rodata",
         "-j", ".data", "-O", "binary", elf, binary])
    write_words(binary)
    disassembly = run([tool("objdump"), "-d", "-M", "no-aliases", elf])
    (BUILD / f"{name}.dis").write_text(disassembly, encoding="ascii")
    symbols = read_symbols(tool, elf, "UTEST_")
    (BUILD / f"{name}-tests.txt").write_text(
        "".join(f"{symbol} {address}\n" for symbol, address in sorted(symbols.items())),
        encoding="ascii",
    )
    write_entries(f"{name}-entries", symbols, (f"UTEST_{test}" for test in tests))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--toolchain-dir", type=Path,
                        help="Folder containing riscv64-unknown-elf-gcc and binutils")
    parser.add_argument("--monitor", type=Path,
                        help="External supervisor-rv/kernel source directory")
    parser.add_argument("--monitor-version", type=int, choices=(1, 2), default=1,
                        help="Build Ver.1 (default) or interrupt-enabled Ver.2")
    args = parser.parse_args()

    def tool(name):
        executable = f"riscv64-unknown-elf-{name}"
        directory = str(args.toolchain_dir.resolve()) if args.toolchain_dir else None
        found = shutil.which(executable, path=directory)
        if not found:
            location = f" in {directory}" if directory else " on PATH"
            raise SystemExit(f"RISC-V tool not found: {executable}{location}")
        return found

    BUILD.mkdir(parents=True, exist_ok=True)
    csr_arch = csr_architecture(tool)
    build_program(tool, "core", 0x80000000)
    build_program(tool, "lab1", 0x80100000, ("LAB1_FIB10", "LAB1_FIB60", "LAB1_ASCII"))
    build_program(tool, "grp56", 0x80100000)
    build_program(tool, "ver2_traps", 0x80100000, ("VER2_EBREAK", "VER2_ILLEGAL", "VER2_ILLEGAL_PC"))
    build_program(tool, "uart_irq", 0x80000000, architecture=csr_arch)
    sum_binary = BUILD / "sum.bin"
    shutil.copyfile(ROOT / "reference" / "lab5" / "program" / "sum.bin", sum_binary)
    write_words(sum_binary)
    if args.monitor:
        build_monitor(tool, args.monitor.resolve(), args.monitor_version, csr_arch)
    print(f"Built simulation images in {BUILD}")


if __name__ == "__main__":
    main()
