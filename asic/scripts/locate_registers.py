from pathlib import Path
import re
import csv
import matplotlib.pyplot as plt

RUN = Path("asic/config/runs/architecture_A_optimized_antenna")
NETLIST = RUN / "final/nl/asic_top.nl.v"
DEF = RUN / "final/def/asic_top.def"
OUTPUT = Path("asic/reports/layout")

OUTPUT.mkdir(parents=True, exist_ok=True)

netlist = NETLIST.read_text()
def_text = DEF.read_text()

# Factor de conversión DEF -> micrómetros
units_match = re.search(
    r"UNITS\s+DISTANCE\s+MICRONS\s+(\d+)\s*;",
    def_text
)

if not units_match:
    raise RuntimeError("No se encontró UNITS en el DEF")

units = int(units_match.group(1))

# Extraer posiciones de instancias físicas
positions = {}

components_match = re.search(
    r"^COMPONENTS\s+\d+\s*;(.*?)^END COMPONENTS",
    def_text,
    re.MULTILINE | re.DOTALL
)

if not components_match:
    raise RuntimeError("No se encontró la sección COMPONENTS")

components = components_match.group(1)

for match in re.finditer(
    r"-\s+(\S+)\s+\S+.*?"
    r"\+\s+(?:PLACED|FIXED)\s+"
    r"\(\s*(\d+)\s+(\d+)\s*\).*?;",
    components,
    re.DOTALL
):
    name = match.group(1)
    x = int(match.group(2)) / units
    y = int(match.group(3)) / units
    positions[name] = (x, y)

# Buscar flip-flops y sus señales Q
groups = {
    "register_file": [],
    "cycle_counter": [],
}

cell_pattern = re.compile(
    r"(gf180mcu_fd_sc_mcu7t5v0__dff\w+)\s+"
    r"(\S+)\s*\((.*?)\);",
    re.DOTALL
)

for match in cell_pattern.finditer(netlist):
    cell_type, instance, ports = match.groups()

    q_match = re.search(
        r"\.Q\(\s*(.*?)\s*\)",
        ports,
        re.DOTALL
    )

    if not q_match:
        continue

    signal = q_match.group(1)

    if "u_rf.registers[" in signal:
        group = "register_file"
    elif "u_periph.cycles[" in signal:
        group = "cycle_counter"
    else:
        continue

    if instance not in positions:
        continue

    x, y = positions[instance]

    groups[group].append({
        "instance": instance,
        "signal": signal,
        "x_um": x,
        "y_um": y,
    })

# Guardar coordenadas y generar gráficos
for group, cells in groups.items():
    csv_path = OUTPUT / f"{group}_coordinates.csv"

    with csv_path.open("w", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["instance", "signal", "x_um", "y_um"]
        )
        writer.writeheader()
        writer.writerows(cells)

    print(f"{group}: {len(cells)} flip-flops localizados")

    if not cells:
        continue

    xs = [cell["x_um"] for cell in cells]
    ys = [cell["y_um"] for cell in cells]

    plt.figure(figsize=(9, 7))
    plt.scatter(xs, ys, s=8, alpha=0.7)

    plt.xlabel("X (µm)")
    plt.ylabel("Y (µm)")
    plt.title(f"Distribución física: {group}")
    plt.axis("equal")
    plt.grid(True, alpha=0.3)
    plt.tight_layout()

    plt.savefig(
        OUTPUT / f"{group}_distribution.png",
        dpi=200
    )
    plt.close()

print(f"\nResultados guardados en {OUTPUT}")
