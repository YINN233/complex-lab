"""Run the Lab6 regression in Vivado Simulator."""

import argparse
from pathlib import Path
import shutil
import subprocess


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build" / "xsim"
IMAGES = ROOT / "build" / "images"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--vivado-bin", type=Path, help="Vivado's bin directory")
    parser.add_argument("--test", choices=("all", "core", "bus", "sum", "monitor"), default="all")
    args = parser.parse_args()

    def run(name, *arguments):
        path = str(args.vivado_bin.resolve() / name) if args.vivado_bin else name
        executable = shutil.which(path)
        if not executable:
            raise SystemExit(f"Vivado tool not found: {path}")
        return subprocess.run([executable, *map(str, arguments)], cwd=BUILD,
                              check=True, text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT).stdout

    def simulate(top, name, marker, plusargs=(), wave=False):
        options = [top, "--onerror", "quit"]
        if wave:
            options.extend(("--tclbatch", (ROOT / "scripts" / "core_wave.tcl").as_posix(),
                            "--wdb", f"{name}.wdb"))
        else:
            options.append("--runall")
        for argument in plusargs:
            options.extend(("--testplusarg", argument))
        # A response file keeps Xilinx's Windows batch wrappers from splitting '='.
        response = BUILD / f"{name}.args"
        response.write_text("\n".join(f'"{item}"' if " " in item else item
                                      for item in options) + "\n", encoding="utf-8")
        output = run("xsim", "-f", response.name)
        (BUILD / f"{name}.log").write_text(output, encoding="utf-8")
        if marker not in output or "Fatal:" in output or "ERROR:" in output:
            raise SystemExit(f"Simulation failed: {name}\n{output}")
        for line in output.splitlines():
            if line.startswith("LAB6 "):
                print(line, flush=True)

    try:
        BUILD.mkdir(parents=True, exist_ok=True)
        manifest = (ROOT / "scripts" / "rtl.f").read_text().splitlines()
        rtl = [ROOT / source for source in manifest]
        tests = [ROOT / "sim" / f"tb_lab6_{name}.sv" for name in ("core", "bus", "soc")]
        memory_model = ROOT / "reference" / "lab5" / "sim" / "sram_model_lab5.sv"
        run("xvlog", "--sv", *rtl, memory_model, *tests)

        selected = args.test
        if selected in ("all", "core"):
            run("xelab", "tb_lab6_core", "-s", "core", "-debug", "typical")
            for mode in (0, 1, 2):
                simulate("core", f"core-{mode}", "LAB6 CORE PASS",
                         ("PROGRAM=../images/core.mem", f"DELAY={mode}"), wave=True)
        if selected in ("all", "bus"):
            run("xelab", "tb_lab6_bus", "-s", "bus")
            simulate("bus", "bus-run", "LAB6 BUS PASS")
        if selected in ("all", "sum", "monitor"):
            run("xelab", "tb_lab6_soc", "-s", "soc", "-debug", "typical")
            if selected in ("all", "sum"):
                simulate("soc", "soc-sum", "LAB6 SOC SUM PASS",
                         ("IMAGES=../images", "SUM"))
            if selected in ("all", "monitor"):
                simulate("soc", "soc-monitor", "LAB6 SOC MONITOR PASS",
                         ("IMAGES=../images",))
    except subprocess.CalledProcessError as error:
        raise SystemExit(f"Vivado command failed ({error.returncode})\n{error.stdout}") from error


if __name__ == "__main__":
    main()
