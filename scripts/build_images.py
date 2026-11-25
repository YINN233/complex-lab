"""Build the lab binaries and memory images with a RISC-V GNU toolchain."""

import argparse
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


def build_program(tool, name, address):
    source = ROOT / "sim" / "programs" / f"{name}.S"
    elf = BUILD / f"{name}.elf"
    binary = BUILD / f"{name}.bin"
    run([tool("gcc"), "-march=rv32i", "-mabi=ilp32", "-nostdlib", "-fno-pic",
         f"-Wl,-Ttext,{address:#x},--no-relax,--build-id=none", source, "-o", elf])
    run([tool("objcopy"), "-j", ".text", "-O", "binary", elf, binary])
    write_words(binary)
    if name == "lab1":
        symbols = read_symbols(tool, elf, "LAB1_")
        (BUILD / "lab1-entries.mem").write_text(
            "".join(f"{symbols['LAB1_' + test]}\n" for test in ("FIB10", "FIB60", "ASCII")),
            encoding="ascii",
        )


def read_symbols(tool, elf, prefix):
    symbols = {}
    for line in run([tool("nm"), elf]).splitlines():
        parts = line.split()
        if len(parts) == 3 and parts[2].startswith(prefix):
            symbols[parts[2]] = parts[0]
    return symbols


def build_monitor(tool, source):
    sources = sorted((source / "kern").glob("*.S"))
    if not sources:
        raise SystemExit(f"No monitor assembly sources under {source / 'kern'}")
    objects = []
    for asm in sources:
        obj = BUILD / f"monitor-{asm.stem}.o"
        run([tool("gcc"), "-c", "-march=rv32i", "-mabi=ilp32", "-fno-pic",
             "-D__ASSEMBLY__", "-DRV32", "-I", source / "include", asm, "-o", obj])
        objects.append(obj)
    elf = BUILD / "monitor.elf"
    binary = BUILD / "monitor.bin"
    run([tool("ld"), "-m", "elf32lriscv", *objects,
         "-T", source / "kern" / "kernel32.ld", "-o", elf])
    run([tool("objcopy"), "-j", ".text", "-j", ".text.*", "-j", ".rodata",
         "-j", ".data", "-O", "binary", elf, binary])
    write_words(binary)
    disassembly = run([tool("objdump"), "-d", "-M", "no-aliases", elf])
    (BUILD / "monitor.dis").write_text(disassembly, encoding="ascii")
    symbols = read_symbols(tool, elf, "UTEST_")
    (BUILD / "monitor-tests.txt").write_text(
        "".join(f"{name} {address}\n" for name, address in sorted(symbols.items())),
        encoding="ascii",
    )
    (BUILD / "monitor-entries.mem").write_text(
        "".join(f"{symbols['UTEST_' + test]}\n"
                for test in ("SIMPLE", "1PTB", "2DCT", "3CCT", "4MDCT")),
        encoding="ascii",
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--toolchain-dir", type=Path,
                        help="Folder containing riscv64-unknown-elf-gcc and binutils")
    parser.add_argument("--monitor", type=Path,
                        help="External supervisor-rv/kernel source directory")
    args = parser.parse_args()

    def tool(name):
        executable = f"riscv64-unknown-elf-{name}"
        if args.toolchain_dir:
            executable = str(args.toolchain_dir.resolve() / executable)
        found = shutil.which(executable)
        if not found:
            raise SystemExit(f"RISC-V tool not found: {executable}")
        return found

    BUILD.mkdir(parents=True, exist_ok=True)
    build_program(tool, "core", 0x80000000)
    build_program(tool, "lab1", 0x80100000)
    build_program(tool, "grp56", 0x80100000)
    sum_binary = BUILD / "sum.bin"
    shutil.copyfile(ROOT / "reference" / "lab5" / "program" / "sum.bin", sum_binary)
    write_words(sum_binary)
    if args.monitor:
        build_monitor(tool, args.monitor.resolve())
    print(f"Built simulation images in {BUILD}")


if __name__ == "__main__":
    main()
